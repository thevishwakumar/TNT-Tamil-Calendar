-- =====================================================================
-- TNT Tamil Calendar — Production Security Hardening & 1,000+ Users Migration
-- Safe, additive, backward-compatible migration
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Harden public.is_admin() Function
--    - Adds STABLE optimization
--    - Fixes search_path hijacking vulnerability
--    - Enforces active status check (suspended admins cannot act as admin)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() 
      AND role = 'ADMIN'
      AND account_status != 'SUSPENDED'
      AND is_active = TRUE
  );
END;
$$;

-- ---------------------------------------------------------------------
-- 2. Harden Profile Role Escalation & Account Status Protection Trigger
--    - Prevents standard users from modifying role, is_active, account_status,
--      email_verified_at, or phone_verified_at
--    - Protects the last active administrator from being demoted or suspended
--    - Fixes search_path
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_active_admin_count INTEGER;
BEGIN
    -- Check if restricted administrative columns are being modified
    IF (OLD.role IS DISTINCT FROM NEW.role 
        OR OLD.is_active IS DISTINCT FROM NEW.is_active
        OR OLD.account_status IS DISTINCT FROM NEW.account_status
        OR OLD.email_verified_at IS DISTINCT FROM NEW.email_verified_at
        OR OLD.phone_verified_at IS DISTINCT FROM NEW.phone_verified_at) THEN
        
        -- If caller is not an authenticated active administrator, reject
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'Security Violation: Standard users cannot modify account roles, verification status, or administrative flags.';
        END IF;

        -- If target is an ADMIN and is being demoted or suspended/deactivated, verify they are not the last active administrator
        IF OLD.role = 'ADMIN' AND (NEW.role != 'ADMIN' OR NEW.is_active = FALSE OR NEW.account_status = 'SUSPENDED') THEN
            SELECT COUNT(*) INTO v_active_admin_count 
            FROM public.profiles 
            WHERE role = 'ADMIN' 
              AND account_status != 'SUSPENDED' 
              AND is_active = TRUE;
              
            IF v_active_admin_count <= 1 THEN
                RAISE EXCEPTION 'Safety Violation: Cannot demote, suspend, or deactivate the last active administrator.';
            END IF;
        END IF;
    END IF;

    -- Update timestamp automatically
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_profile_role_escalation();

-- ---------------------------------------------------------------------
-- 3. Harden search_path on all SECURITY DEFINER functions
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_raw_full_name TEXT;
    v_full_name TEXT;
    v_phone TEXT;
    v_mobile TEXT;
    v_language TEXT;
    v_email_confirmed BOOLEAN;
BEGIN
    v_raw_full_name := NEW.raw_user_meta_data->>'full_name';
    IF v_raw_full_name IS NULL OR TRIM(v_raw_full_name) = '' THEN
        v_full_name := COALESCE(SPLIT_PART(NEW.email, '@', 1), 'TNT User');
    ELSE
        v_full_name := TRIM(v_raw_full_name);
    END IF;

    v_phone := NEW.phone;
    v_mobile := NEW.raw_user_meta_data->>'phone';
    v_language := COALESCE(NEW.raw_user_meta_data->>'language', 'ta');
    IF v_language NOT IN ('ta', 'en') THEN
        v_language := 'ta';
    END IF;

    v_email_confirmed := (NEW.email_confirmed_at IS NOT NULL);

    INSERT INTO public.profiles (
        id,
        full_name,
        email,
        phone,
        mobile,
        role,
        account_status,
        language,
        city,
        state,
        country,
        avatar_url,
        is_active,
        email_verified_at,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        v_full_name,
        COALESCE(NEW.email, ''),
        v_phone,
        v_mobile,
        'USER',
        CASE WHEN v_email_confirmed THEN 'ACTIVE' ELSE 'PENDING_EMAIL_VERIFICATION' END,
        v_language,
        NEW.raw_user_meta_data->>'city',
        NEW.raw_user_meta_data->>'state',
        NEW.raw_user_meta_data->>'country',
        NEW.raw_user_meta_data->>'avatar_url',
        true,
        NEW.email_confirmed_at,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = CASE WHEN EXCLUDED.email <> '' THEN EXCLUDED.email ELSE public.profiles.email END,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        mobile = COALESCE(EXCLUDED.mobile, public.profiles.mobile),
        email_verified_at = COALESCE(EXCLUDED.email_verified_at, public.profiles.email_verified_at),
        account_status = CASE 
            WHEN public.profiles.role = 'ADMIN' THEN public.profiles.account_status
            WHEN EXCLUDED.email_verified_at IS NOT NULL THEN 'ACTIVE'
            ELSE public.profiles.account_status
        END,
        updated_at = NOW();

    INSERT INTO public.user_preferences (
        user_id,
        language,
        notification_enabled,
        all_notifications,
        daily_panchangam,
        nalla_neram,
        rahu_kalam,
        festivals,
        muhurtham,
        special_days,
        reminders,
        marketing_notifications,
        updated_at
    ) VALUES (
        NEW.id,
        v_language,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        false, -- Strict opt-in for marketing by default
        NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.deactivate_device_token(p_device_token TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.user_devices
    SET is_active = false, updated_at = NOW()
    WHERE device_token = p_device_token
      AND (user_id = auth.uid() OR public.is_admin());
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_notification_as_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.notification_logs
    SET is_read = true, opened_at = NOW()
    WHERE id = p_notification_id
      AND user_id = auth.uid();
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE public.notification_logs
    SET is_read = true, opened_at = NOW()
    WHERE user_id = auth.uid()
      AND is_read = false;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_admin_audit(
    p_action TEXT,
    p_module TEXT,
    p_record_id TEXT,
    p_old_state JSONB DEFAULT NULL,
    p_new_state JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_id UUID;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can generate audit records.';
    END IF;

    INSERT INTO public.admin_audit_logs (
        admin_id, action, module, record_id, old_state, new_state, created_at
    ) VALUES (
        auth.uid(), p_action, p_module, p_record_id, p_old_state, p_new_state, NOW()
    ) RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_notification_campaign(p_campaign_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can cancel notification campaigns.';
    END IF;

    UPDATE public.notification_campaigns
    SET status = 'cancelled', updated_at = NOW()
    WHERE id = p_campaign_id AND status = 'scheduled';

    IF FOUND THEN
        PERFORM public.log_admin_audit('CANCEL_CAMPAIGN', 'NOTIFICATIONS', p_campaign_id::TEXT);
        RETURN true;
    END IF;

    RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_analytics_summary(
    p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '30 days')::DATE,
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_total_users INTEGER;
    v_active_users INTEGER;
    v_new_users INTEGER;
    v_calendar_views INTEGER;
    v_panchangam_views INTEGER;
    v_muhurtham_views INTEGER;
    v_festival_views INTEGER;
    v_special_day_views INTEGER;
    v_poster_views INTEGER;
    v_notif_opens INTEGER;
    v_shares INTEGER;
    v_reminders_set INTEGER;
    v_saved_items INTEGER;
    v_campaigns_count INTEGER;
    v_result JSONB;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Administrator role required for analytics.';
    END IF;

    -- Fast index-assisted counts
    SELECT COUNT(*) INTO v_total_users FROM public.profiles;
    SELECT COUNT(*) INTO v_active_users FROM public.profiles WHERE is_active = TRUE;
    SELECT COUNT(*) INTO v_new_users FROM public.profiles WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_calendar_views FROM public.analytics_events 
    WHERE event_name IN ('calendar_view', 'calendar_date_open', 'calendar_month_change') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_panchangam_views FROM public.analytics_events 
    WHERE event_name IN ('panchangam_view', 'panchangam_month_view') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_muhurtham_views FROM public.analytics_events 
    WHERE event_name IN ('muhurtham_view', 'muhurtham_category_view') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_festival_views FROM public.analytics_events 
    WHERE event_name IN ('festival_view', 'festival_filter_change') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_special_day_views FROM public.analytics_events 
    WHERE event_name IN ('special_day_view', 'special_day_filter_change') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_poster_views FROM public.analytics_events 
    WHERE event_name IN ('poster_view', 'media_preview') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_notif_opens FROM public.analytics_events 
    WHERE event_name IN ('notification_open', 'notification_click') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_shares FROM public.analytics_events 
    WHERE event_name IN ('content_share', 'panchangam_share', 'festival_share') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_reminders_set FROM public.user_reminders 
    WHERE is_enabled = TRUE;

    SELECT COUNT(*) INTO v_saved_items FROM public.user_saved_items;

    SELECT COUNT(*) INTO v_campaigns_count FROM public.notification_campaigns 
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;

    v_result := jsonb_build_object(
        'total_users', v_total_users,
        'active_users', v_active_users,
        'new_users', v_new_users,
        'calendar_views', v_calendar_views,
        'panchangam_views', v_panchangam_views,
        'muhurtham_views', v_muhurtham_views,
        'festival_views', v_festival_views,
        'special_day_views', v_special_day_views,
        'poster_views', v_poster_views,
        'notification_opens', v_notif_opens,
        'shares', v_shares,
        'active_reminders', v_reminders_set,
        'saved_bookmarks', v_saved_items,
        'campaigns_count', v_campaigns_count,
        'generated_at', NOW()
    );

    RETURN v_result;
END;
$$;

-- ---------------------------------------------------------------------
-- 4. Harden Row-Level Security (RLS) Policies
-- ---------------------------------------------------------------------

-- A. Profiles Update Policy: Add WITH CHECK constraint
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
CREATE POLICY "profiles_update_policy" ON public.profiles 
    FOR UPDATE 
    USING (auth.uid() = id OR public.is_admin())
    WITH CHECK (auth.uid() = id OR public.is_admin());

-- B. User Reminders: Add explicit INSERT, UPDATE, DELETE policies
DROP POLICY IF EXISTS "user_reminders_insert_policy" ON public.user_reminders;
CREATE POLICY "user_reminders_insert_policy" ON public.user_reminders
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_reminders_update_policy" ON public.user_reminders;
CREATE POLICY "user_reminders_update_policy" ON public.user_reminders
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_reminders_delete_policy" ON public.user_reminders;
CREATE POLICY "user_reminders_delete_policy" ON public.user_reminders
    FOR DELETE 
    USING (auth.uid() = user_id);

-- C. User Saved Items: Clean up redundant policies and add explicit WITH CHECK
DROP POLICY IF EXISTS "user_saved_items_insert_policy" ON public.user_saved_items;
CREATE POLICY "user_saved_items_insert_policy" ON public.user_saved_items
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_saved_items_update_policy" ON public.user_saved_items;
CREATE POLICY "user_saved_items_update_policy" ON public.user_saved_items
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_saved_items_delete_policy" ON public.user_saved_items;
CREATE POLICY "user_saved_items_delete_policy" ON public.user_saved_items
    FOR DELETE 
    USING (auth.uid() = user_id);

-- D. Notification Campaigns: Allow authenticated users to view SENT campaigns
DROP POLICY IF EXISTS "notification_campaigns_user_select_policy" ON public.notification_campaigns;
CREATE POLICY "notification_campaigns_user_select_policy" ON public.notification_campaigns
    FOR SELECT 
    USING (status = 'SENT' OR status = 'sent' OR public.is_admin());

-- E. Email Verification Challenges: Restrict raw challenge table reads to admin/service role
DROP POLICY IF EXISTS "email_challenges_user_select" ON public.email_verification_challenges;

-- F. Catering Enquiries: Standardize admin policy to public.is_admin()
DROP POLICY IF EXISTS "Admins can do everything on enquiries" ON public.catering_enquiries;
CREATE POLICY "Admins can do everything on enquiries" 
    ON public.catering_enquiries 
    FOR ALL 
    USING (public.is_admin());

-- G. System Settings: Standardize admin policy to public.is_admin()
DROP POLICY IF EXISTS "Admins can update system settings" ON public.system_settings;
CREATE POLICY "Admins can update system settings"
    ON public.system_settings
    FOR ALL
    USING (public.is_admin());

-- ---------------------------------------------------------------------
-- 5. Scalability Indexes for 1,000+ Concurrent Active Users
-- ---------------------------------------------------------------------

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role_status ON public.profiles(role, account_status, is_active);

-- User Preferences (queried on every app launch)
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON public.user_preferences(user_id);

-- User Bookmarks & Reminders
CREATE INDEX IF NOT EXISTS idx_user_saved_items_composite ON public.user_saved_items(user_id, item_type, item_id);
CREATE INDEX IF NOT EXISTS idx_user_reminders_composite ON public.user_reminders(user_id, reminder_time);

-- Muhurtham & Timings Joins
CREATE INDEX IF NOT EXISTS idx_muhurtham_timings_date_id ON public.muhurtham_timings(muhurtham_date_id);
CREATE INDEX IF NOT EXISTS idx_content_media_content_id ON public.content_media(content_id);

-- Catering & Leads
CREATE INDEX IF NOT EXISTS idx_catering_enquiries_user ON public.catering_enquiries(user_id);
CREATE INDEX IF NOT EXISTS idx_catering_enquiries_status ON public.catering_enquiries(status);

-- Notification Campaigns
CREATE INDEX IF NOT EXISTS idx_notification_campaigns_status_sent ON public.notification_campaigns(status, sent_at DESC);

-- Calendar Days
CREATE INDEX IF NOT EXISTS idx_calendar_days_gregorian ON public.calendar_days(gregorian_date);
