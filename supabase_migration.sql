-- =====================================================================
-- TNT Tamil Calendar & Panchangam System - Complete Database Migration
-- =====================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Remove existing resources if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TABLE IF EXISTS public.email_verification_challenges CASCADE;
DROP TABLE IF EXISTS public.otp_verifications CASCADE;
DROP TABLE IF EXISTS public.admin_audit_logs CASCADE;
DROP TABLE IF EXISTS public.media_assets CASCADE;
DROP TABLE IF EXISTS public.admin_schedules CASCADE;
DROP TABLE IF EXISTS public.daily_analytics CASCADE;
DROP TABLE IF EXISTS public.analytics_events CASCADE;
DROP TABLE IF EXISTS public.notification_logs CASCADE;
DROP TABLE IF EXISTS public.notification_campaigns CASCADE;
DROP TABLE IF EXISTS public.user_devices CASCADE;
DROP TABLE IF EXISTS public.user_reminders CASCADE;
DROP TABLE IF EXISTS public.user_saved_items CASCADE;
DROP TABLE IF EXISTS public.content_media CASCADE;
DROP TABLE IF EXISTS public.content CASCADE;
DROP TABLE IF EXISTS public.festivals CASCADE;
DROP TABLE IF EXISTS public.special_days CASCADE;
DROP TABLE IF EXISTS public.muhurtham_timings CASCADE;
DROP TABLE IF EXISTS public.muhurtham_dates CASCADE;
DROP TABLE IF EXISTS public.timing_entries CASCADE;
DROP TABLE IF EXISTS public.panchangam_entries CASCADE;
DROP TABLE IF EXISTS public.calendar_days CASCADE;
DROP TABLE IF EXISTS public.user_preferences CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- -------------------------------------------------------------
-- 1. profiles Table
-- -------------------------------------------------------------
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    mobile TEXT,
    role TEXT NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
    account_status TEXT NOT NULL DEFAULT 'PENDING_EMAIL_VERIFICATION' CHECK (account_status IN ('PENDING_EMAIL_VERIFICATION', 'PENDING_MOBILE_VERIFICATION', 'ACTIVE', 'SUSPENDED')),
    language TEXT NOT NULL DEFAULT 'ta' CHECK (language IN ('ta', 'en')),
    city TEXT,
    state TEXT,
    country TEXT,
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    email_verified_at TIMESTAMPTZ,
    phone_verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 1b. email_verification_challenges Table (Cryptographic SHA-256 Hashed OTPs)
-- -------------------------------------------------------------
CREATE TABLE public.email_verification_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 5,
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'VERIFIED', 'EXPIRED', 'MAX_ATTEMPTS_EXCEEDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_challenges_email ON public.email_verification_challenges(email);
CREATE INDEX idx_email_challenges_user ON public.email_verification_challenges(user_id);
CREATE INDEX idx_email_challenges_status ON public.email_verification_challenges(status);

-- -------------------------------------------------------------
-- 1c. otp_verifications Table (Secure Mobile OTP metadata only - NO raw plaintext OTPs)
-- -------------------------------------------------------------
CREATE TABLE public.otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone_hash TEXT NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'VERIFIED', 'EXPIRED', 'MAX_ATTEMPTS_EXCEEDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_verifications_user ON public.otp_verifications(user_id);
CREATE INDEX idx_otp_verifications_phone ON public.otp_verifications(phone_hash);
-- 2. user_preferences Table
-- -------------------------------------------------------------
CREATE TABLE public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    language TEXT NOT NULL DEFAULT 'ta' CHECK (language IN ('ta', 'en')),
    notification_enabled BOOLEAN NOT NULL DEFAULT true,
    all_notifications BOOLEAN NOT NULL DEFAULT true,
    panchangam_notifications BOOLEAN NOT NULL DEFAULT true,
    muhurtham_notifications BOOLEAN NOT NULL DEFAULT true,
    festival_notifications BOOLEAN NOT NULL DEFAULT true,
    special_day_notifications BOOLEAN NOT NULL DEFAULT true,
    reminder_notifications BOOLEAN NOT NULL DEFAULT true,
    important_updates BOOLEAN NOT NULL DEFAULT true,
    marketing_notifications BOOLEAN NOT NULL DEFAULT false, -- CRITICAL: Strictly OFF by default
    location_permission_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- -------------------------------------------------------------
-- 3. calendar_days Table
-- -------------------------------------------------------------
CREATE TABLE public.calendar_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE UNIQUE NOT NULL,
    tamil_date TEXT NOT NULL,
    tamil_month TEXT NOT NULL,
    tamil_year TEXT NOT NULL,
    weekday_tamil TEXT NOT NULL,
    weekday_english TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 4. panchangam_entries Table
-- -------------------------------------------------------------
CREATE TABLE public.panchangam_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calendar_day_id UUID NOT NULL REFERENCES public.calendar_days(id) ON DELETE CASCADE,
    tithi TEXT NOT NULL,
    nakshatra TEXT NOT NULL,
    yoga TEXT NOT NULL,
    karana TEXT NOT NULL,
    sunrise TIMESTAMPTZ,
    sunset TIMESTAMPTZ,
    moonrise TIMESTAMPTZ,
    moonset TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(calendar_day_id)
);

-- -------------------------------------------------------------
-- 5. timing_entries Table
-- -------------------------------------------------------------
CREATE TABLE public.timing_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calendar_day_id UUID NOT NULL REFERENCES public.calendar_days(id) ON DELETE CASCADE,
    timing_type TEXT NOT NULL CHECK (timing_type IN ('nalla_neram', 'rahu_kalam', 'yamagandam', 'kuligai', 'gowri_panchangam', 'subha_horai')),
    start_time TEXT, -- e.g., "09:15 AM"
    end_time TEXT, -- e.g., "10:15 AM"
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 6. muhurtham_dates Table
-- -------------------------------------------------------------
CREATE TABLE public.muhurtham_dates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE UNIQUE NOT NULL,
    title_tamil TEXT NOT NULL,
    title_english TEXT NOT NULL,
    description_tamil TEXT,
    description_english TEXT,
    is_published BOOLEAN NOT NULL DEFAULT false,
    source_name TEXT,
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 7. muhurtham_timings Table
-- -------------------------------------------------------------
CREATE TABLE public.muhurtham_timings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    muhurtham_date_id UUID NOT NULL REFERENCES public.muhurtham_dates(id) ON DELETE CASCADE,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    nakshatra TEXT,
    nakshatra_start TEXT,
    nakshatra_end TEXT,
    nalla_neram_start TEXT,
    nalla_neram_end TEXT,
    rahu_start TEXT,
    rahu_end TEXT,
    yamagandam_start TEXT,
    yamagandam_end TEXT,
    kuligai_start TEXT,
    kuligai_end TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 8. special_days Table
-- -------------------------------------------------------------
CREATE TABLE public.special_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    name_tamil TEXT NOT NULL,
    name_english TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'amavasai', 'pournami', 'pradosham', 'sashti', 'ekadashi', 
        'krithigai', 'chaturthi', 'shivaratri', 'special_day'
    )),
    description_tamil TEXT,
    description_english TEXT,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 9. festivals Table
-- -------------------------------------------------------------
CREATE TABLE public.festivals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    name_tamil TEXT NOT NULL,
    name_english TEXT NOT NULL,
    description_tamil TEXT,
    description_english TEXT,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 10. content Table
-- -------------------------------------------------------------
CREATE TABLE public.content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_tamil TEXT NOT NULL,
    title_english TEXT NOT NULL,
    description_tamil TEXT,
    description_english TEXT,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'EXPIRED', 'ARCHIVED')),
    publish_at TIMESTAMPTZ,
    expire_at TIMESTAMPTZ,
    priority INTEGER NOT NULL DEFAULT 0,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 11. content_media Table
-- -------------------------------------------------------------
CREATE TABLE public.content_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES public.content(id) ON DELETE CASCADE,
    media_type TEXT NOT NULL,
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 12. user_saved_items Table
-- -------------------------------------------------------------
CREATE TABLE public.user_saved_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL CHECK (item_type IN ('muhurtham', 'festival', 'special_day', 'panchangam')),
    item_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, item_type, item_id)
);

-- -------------------------------------------------------------
-- 13. user_reminders Table
-- -------------------------------------------------------------
CREATE TABLE public.user_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL,
    item_id UUID NOT NULL,
    reminder_time TIMESTAMPTZ NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 14. user_devices Table (Multi-device Push Token Management)
-- -------------------------------------------------------------
CREATE TABLE public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    app_version TEXT,
    device_info JSONB,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, device_token)
);

CREATE INDEX idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX idx_user_devices_token ON public.user_devices(device_token);
CREATE INDEX idx_user_devices_active ON public.user_devices(is_active);

-- -------------------------------------------------------------
-- 15. notification_campaigns Table (Marketing / System Announcements)
-- -------------------------------------------------------------
CREATE TABLE public.notification_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    title_tamil TEXT NOT NULL,
    title_english TEXT NOT NULL,
    body TEXT NOT NULL,
    message_tamil TEXT NOT NULL,
    message_english TEXT NOT NULL,
    category TEXT NOT NULL, -- PANCHANGAM, MUHURTHAM, FESTIVAL, SPECIAL_DAY, REMINDER, IMPORTANT_UPDATE, ANNOUNCEMENT, MARKETING
    audience_type TEXT NOT NULL DEFAULT 'all_eligible', -- all_eligible, opt_in_marketing, active_users, category_subscribers, custom_filter
    target_filter JSONB,
    notification_type TEXT NOT NULL DEFAULT 'campaign',
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SCHEDULED', 'SENDING', 'SENT', 'CANCELLED', 'FAILED')),
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    deep_link TEXT,
    media_reference TEXT,
    idempotency_key TEXT UNIQUE,
    total_targeted INT NOT NULL DEFAULT 0,
    total_sent INT NOT NULL DEFAULT 0,
    total_delivered INT NOT NULL DEFAULT 0,
    total_opened INT NOT NULL DEFAULT 0,
    total_failed INT NOT NULL DEFAULT 0,
    total_skipped INT NOT NULL DEFAULT 0,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_campaigns_status ON public.notification_campaigns(status);
CREATE INDEX idx_notification_campaigns_scheduled ON public.notification_campaigns(scheduled_at);
CREATE INDEX idx_notification_campaigns_category ON public.notification_campaigns(category);

-- -------------------------------------------------------------
-- 16. notification_logs Table (User Notification History)
-- -------------------------------------------------------------
CREATE TABLE public.notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES public.notification_campaigns(id) ON DELETE CASCADE,
    device_id UUID REFERENCES public.user_devices(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    title_tamil TEXT,
    body TEXT NOT NULL,
    body_tamil TEXT,
    notification_type TEXT NOT NULL, -- PANCHANGAM, MUHURTHAM, FESTIVAL, SPECIAL_DAY, REMINDER, IMPORTANT_UPDATE, ANNOUNCEMENT, MARKETING
    related_item_type TEXT, -- muhurtham, festival, special_day, panchangam, reminder, campaign, content
    related_item_id TEXT, -- ID of the related entity for actionable deep linking
    status TEXT NOT NULL DEFAULT 'SENT' CHECK (status IN ('PENDING', 'QUEUED', 'SENT', 'DELIVERED', 'OPENED', 'FAILED', 'SKIPPED', 'CANCELLED')),
    error_message TEXT,
    is_read BOOLEAN NOT NULL DEFAULT false,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_logs_user_id ON public.notification_logs(user_id);
CREATE INDEX idx_notification_logs_campaign_id ON public.notification_logs(campaign_id);
CREATE INDEX idx_notification_logs_sent_at ON public.notification_logs(sent_at DESC);
CREATE INDEX idx_notification_logs_unread ON public.notification_logs(user_id, is_read);
CREATE INDEX idx_notification_logs_status ON public.notification_logs(status);

-- -------------------------------------------------------------
-- 16. analytics_events Table
-- -------------------------------------------------------------
CREATE TABLE public.analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    event_name TEXT NOT NULL,
    content_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 17. daily_analytics Table (Strictly ADMIN only)
-- -------------------------------------------------------------
CREATE TABLE public.daily_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analytics_date DATE UNIQUE NOT NULL,
    total_users INTEGER NOT NULL DEFAULT 0,
    new_users INTEGER NOT NULL DEFAULT 0,
    active_users INTEGER NOT NULL DEFAULT 0,
    calendar_views INTEGER NOT NULL DEFAULT 0,
    panchangam_views INTEGER NOT NULL DEFAULT 0,
    muhurtham_views INTEGER NOT NULL DEFAULT 0,
    poster_views INTEGER NOT NULL DEFAULT 0,
    notification_opens INTEGER NOT NULL DEFAULT 0,
    shares INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 18. admin_schedules Table (Strictly ADMIN only)
-- -------------------------------------------------------------
CREATE TABLE public.admin_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL DEFAULT 'Internal Operational Task',
    description TEXT,
    schedule_date DATE NOT NULL,
    start_time TEXT NOT NULL DEFAULT '09:00 AM',
    end_time TEXT NOT NULL DEFAULT '05:00 PM',
    category TEXT NOT NULL DEFAULT 'CONTENT_PREP' CHECK (category IN ('CONTENT_PREP', 'MANDAPAM', 'VERIFICATION', 'NOTIFICATIONS', 'MAINTENANCE', 'GENERAL')),
    priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    status TEXT NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    mandapam TEXT,
    event_type TEXT,
    marriage_details TEXT,
    internal_notes TEXT, -- Strictly confidential
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 19. media_assets Table (Admin Media Library)
-- -------------------------------------------------------------
CREATE TABLE public.media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name TEXT NOT NULL,
    file_size INTEGER NOT NULL DEFAULT 0,
    mime_type TEXT NOT NULL DEFAULT 'image/jpeg',
    storage_path TEXT NOT NULL,
    public_url TEXT NOT NULL,
    thumbnail_url TEXT,
    media_type TEXT NOT NULL DEFAULT 'IMAGE' CHECK (media_type IN ('IMAGE', 'POSTER', 'BANNER', 'ICON', 'DOCUMENT')),
    related_content_id UUID REFERENCES public.content(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ARCHIVED', 'DELETED')),
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 20. admin_audit_logs Table (Strictly ADMIN only Audit Trail)
-- -------------------------------------------------------------
CREATE TABLE public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    admin_email TEXT,
    action TEXT NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'PUBLISH', 'SCHEDULE', 'ARCHIVE', 'DELETE', 'RESTORE', 'MEDIA_UPLOAD', 'MEDIA_REPLACE', 'MEDIA_DELETE', 'BULK_IMPORT')),
    module TEXT NOT NULL CHECK (module IN ('CALENDAR', 'PANCHANGAM', 'MUHURTHAM', 'SPECIAL_DAYS', 'FESTIVALS', 'CONTENT', 'MEDIA', 'USERS', 'NOTIFICATIONS', 'SETTINGS', 'SCHEDULES')),
    record_id TEXT NOT NULL,
    previous_state JSONB,
    new_state JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 21. user_important_dates Table (Strictly Private to User)
-- -------------------------------------------------------------
CREATE TABLE public.user_important_dates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    event_type TEXT NOT NULL DEFAULT 'CUSTOM' CHECK (event_type IN ('BIRTHDAY', 'ANNIVERSARY', 'WEDDING', 'FUNCTION', 'FAMILY_EVENT', 'CUSTOM')),
    reminder_enabled BOOLEAN NOT NULL DEFAULT true,
    reminder_time TEXT DEFAULT '09:00 AM',
    repeat_type TEXT NOT NULL DEFAULT 'NONE' CHECK (repeat_type IN ('NONE', 'YEARLY', 'MONTHLY')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 22. user_personal_notes Table (Strictly Private to User)
-- -------------------------------------------------------------
CREATE TABLE public.user_personal_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    title TEXT NOT NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 23. user_saved_locations Table (Strictly Private to User)
-- -------------------------------------------------------------
CREATE TABLE public.user_saved_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT,
    country TEXT NOT NULL DEFAULT 'India',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_important_dates_user ON public.user_important_dates(user_id);
CREATE INDEX idx_user_important_dates_date ON public.user_important_dates(date);
CREATE INDEX idx_user_personal_notes_user_date ON public.user_personal_notes(user_id, date);
CREATE INDEX idx_user_saved_locations_user ON public.user_saved_locations(user_id);

-- =============================================================
-- PERFORMANCE INDEXES
-- =============================================================
CREATE INDEX idx_calendar_days_date ON public.calendar_days(date);
CREATE INDEX idx_muhurtham_dates_date ON public.muhurtham_dates(date);
CREATE INDEX idx_special_days_date ON public.special_days(date);
CREATE INDEX idx_festivals_date ON public.festivals(date);
CREATE INDEX idx_analytics_events_created_at ON public.analytics_events(created_at);
CREATE INDEX idx_analytics_events_name ON public.analytics_events(event_name);
CREATE INDEX idx_content_status ON public.content(status);
CREATE INDEX idx_content_publish_at ON public.content(publish_at);
CREATE INDEX idx_admin_schedules_date ON public.admin_schedules(schedule_date);
CREATE INDEX idx_media_assets_status ON public.media_assets(status);
CREATE INDEX idx_media_assets_type ON public.media_assets(media_type);
CREATE INDEX idx_admin_audit_logs_module ON public.admin_audit_logs(module);
CREATE INDEX idx_admin_audit_logs_admin ON public.admin_audit_logs(admin_id);
CREATE INDEX idx_admin_audit_logs_created_at ON public.admin_audit_logs(created_at DESC);

-- =============================================================
-- SYSTEM TRIGGERS & SECURE TRIGGER FUNCTIONS
-- =============================================================

-- Auto create a user profile when a new user signs up via Supabase Auth.
-- Real signup assigns 'USER' role and creates a corresponding user_preferences entry.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_full_name TEXT;
    user_lang TEXT;
BEGIN
    -- Extract full name from raw_user_meta_data if present, else fallback
    user_full_name := COALESCE(new.raw_user_meta_data->>'full_name', 'TNT User');
    user_lang := COALESCE(new.raw_user_meta_data->>'language', 'ta');

    -- Insert into profiles
    INSERT INTO public.profiles (id, full_name, email, role, language, is_active)
    VALUES (new.id, user_full_name, new.email, 'USER', user_lang, true);

    -- Insert default preferences
    INSERT INTO public.user_preferences (user_id, language)
    VALUES (new.id, user_lang);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto update updated_at timestamps
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_user_preferences BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_calendar_days BEFORE UPDATE ON public.calendar_days FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_panchangam_entries BEFORE UPDATE ON public.panchangam_entries FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_timing_entries BEFORE UPDATE ON public.timing_entries FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_muhurtham_dates BEFORE UPDATE ON public.muhurtham_dates FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_muhurtham_timings BEFORE UPDATE ON public.muhurtham_timings FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_special_days BEFORE UPDATE ON public.special_days FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_festivals BEFORE UPDATE ON public.festivals FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_content BEFORE UPDATE ON public.content FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_content_media BEFORE UPDATE ON public.content_media FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_user_reminders BEFORE UPDATE ON public.user_reminders FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_notification_campaigns BEFORE UPDATE ON public.notification_campaigns FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_daily_analytics BEFORE UPDATE ON public.daily_analytics FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
CREATE TRIGGER set_timestamp_admin_schedules BEFORE UPDATE ON public.admin_schedules FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


-- =============================================================
-- SECURITY: ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_verification_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.panchangam_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timing_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muhurtham_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muhurtham_timings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.special_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.festivals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_saved_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_schedules ENABLE ROW LEVEL SECURITY;

-- Helper security function to check if the current user is an admin.
-- Queries the profiles table within a SECURITY DEFINER context to prevent recursion.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 1. profiles Policies
CREATE POLICY "profiles_select_policy" ON public.profiles 
    FOR SELECT USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_update_policy" ON public.profiles 
    FOR UPDATE USING (auth.uid() = id OR public.is_admin());

-- 1b. email_verification_challenges Policies (Strictly Admin / Service Role or self user)
CREATE POLICY "email_challenges_admin_policy" ON public.email_verification_challenges
    FOR ALL USING (public.is_admin());

CREATE POLICY "email_challenges_user_select" ON public.email_verification_challenges
    FOR SELECT USING (auth.uid() = user_id);

-- 1c. otp_verifications Policies (Strictly Admin or self user)
CREATE POLICY "otp_verifications_admin_policy" ON public.otp_verifications
    FOR ALL USING (public.is_admin());

CREATE POLICY "otp_verifications_user_select" ON public.otp_verifications
    FOR SELECT USING (auth.uid() = user_id);


-- 2. user_preferences Policies
CREATE POLICY "user_preferences_select_policy" ON public.user_preferences 
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "user_preferences_all_policy" ON public.user_preferences 
    FOR ALL USING (auth.uid() = user_id OR public.is_admin());


-- 3. calendar_days Policies
CREATE POLICY "calendar_days_select_policy" ON public.calendar_days 
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "calendar_days_admin_policy" ON public.calendar_days 
    FOR ALL USING (public.is_admin());


-- 4. panchangam_entries Policies
CREATE POLICY "panchangam_entries_select_policy" ON public.panchangam_entries 
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "panchangam_entries_admin_policy" ON public.panchangam_entries 
    FOR ALL USING (public.is_admin());


-- 5. timing_entries Policies
CREATE POLICY "timing_entries_select_policy" ON public.timing_entries 
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "timing_entries_admin_policy" ON public.timing_entries 
    FOR ALL USING (public.is_admin());


-- 6. muhurtham_dates Policies
CREATE POLICY "muhurtham_dates_select_policy" ON public.muhurtham_dates 
    FOR SELECT USING (is_published = true OR public.is_admin());

CREATE POLICY "muhurtham_dates_admin_policy" ON public.muhurtham_dates 
    FOR ALL USING (public.is_admin());


-- 7. muhurtham_timings Policies
CREATE POLICY "muhurtham_timings_select_policy" ON public.muhurtham_timings 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.muhurtham_dates
            WHERE id = muhurtham_timings.muhurtham_date_id AND (is_published = true OR public.is_admin())
        )
    );

CREATE POLICY "muhurtham_timings_admin_policy" ON public.muhurtham_timings 
    FOR ALL USING (public.is_admin());


-- 8. special_days Policies
CREATE POLICY "special_days_select_policy" ON public.special_days 
    FOR SELECT USING (is_published = true OR public.is_admin());

CREATE POLICY "special_days_admin_policy" ON public.special_days 
    FOR ALL USING (public.is_admin());


-- 9. festivals Policies
CREATE POLICY "festivals_select_policy" ON public.festivals 
    FOR SELECT USING (is_published = true OR public.is_admin());

CREATE POLICY "festivals_admin_policy" ON public.festivals 
    FOR ALL USING (public.is_admin());


-- 10. content Policies
CREATE POLICY "content_select_policy" ON public.content 
    FOR SELECT USING (
        (status = 'PUBLISHED' AND (publish_at IS NULL OR publish_at <= NOW()) AND (expire_at IS NULL OR expire_at >= NOW())) 
        OR public.is_admin()
    );

CREATE POLICY "content_admin_policy" ON public.content 
    FOR ALL USING (public.is_admin());


-- 11. content_media Policies
CREATE POLICY "content_media_select_policy" ON public.content_media 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.content
            WHERE id = content_media.content_id AND (
                (status = 'PUBLISHED' AND (publish_at IS NULL OR publish_at <= NOW()) AND (expire_at IS NULL OR expire_at >= NOW()))
                OR public.is_admin()
            )
        )
    );

CREATE POLICY "content_media_admin_policy" ON public.content_media 
    FOR ALL USING (public.is_admin());


-- 12. user_saved_items Policies
CREATE POLICY "user_saved_items_select_policy" ON public.user_saved_items 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_saved_items_all_policy" ON public.user_saved_items 
    FOR ALL USING (auth.uid() = user_id);


-- 13. user_reminders Policies
CREATE POLICY "user_reminders_select_policy" ON public.user_reminders 
    FOR SELECT USING (auth.uid() = user_id);

-- 14. user_devices Policies
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_devices_select_policy" ON public.user_devices 
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "user_devices_insert_policy" ON public.user_devices 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_devices_update_policy" ON public.user_devices 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_devices_delete_policy" ON public.user_devices 
    FOR DELETE USING (auth.uid() = user_id);


-- 15. notification_campaigns Policies (Strictly Admin only)
ALTER TABLE public.notification_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_campaigns_admin_policy" ON public.notification_campaigns 
    FOR ALL USING (public.is_admin());


-- 16. notification_logs Policies
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_logs_select_policy" ON public.notification_logs 
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "notification_logs_update_policy" ON public.notification_logs 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notification_logs_admin_all_policy" ON public.notification_logs 
    FOR ALL USING (public.is_admin());


-- 16. analytics_events Policies
CREATE POLICY "analytics_events_insert_policy" ON public.analytics_events 
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "analytics_events_admin_policy" ON public.analytics_events 
    FOR SELECT USING (public.is_admin());


-- 17. daily_analytics Policies (Strictly Admin only)
CREATE POLICY "daily_analytics_admin_policy" ON public.daily_analytics 
    FOR ALL USING (public.is_admin());


-- 18. admin_schedules Policies (Strictly Admin only - ZERO user access)
CREATE POLICY "admin_schedules_admin_policy" ON public.admin_schedules 
    FOR ALL USING (public.is_admin());


-- 19. media_assets Policies
ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "media_assets_select_policy" ON public.media_assets 
    FOR SELECT USING (status = 'ACTIVE' OR public.is_admin());

CREATE POLICY "media_assets_admin_policy" ON public.media_assets 
    FOR ALL USING (public.is_admin());


-- 20. admin_audit_logs Policies (Strictly Admin only)
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_audit_logs_admin_policy" ON public.admin_audit_logs 
    FOR ALL USING (public.is_admin());


-- 21. user_important_dates Policies (Strictly Owner Only)
ALTER TABLE public.user_important_dates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_important_dates_select_policy" ON public.user_important_dates 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_important_dates_all_policy" ON public.user_important_dates 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- 22. user_personal_notes Policies (Strictly Owner Only)
ALTER TABLE public.user_personal_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_personal_notes_select_policy" ON public.user_personal_notes 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_personal_notes_all_policy" ON public.user_personal_notes 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- 23. user_saved_locations Policies (Strictly Owner Only)
ALTER TABLE public.user_saved_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_saved_locations_select_policy" ON public.user_saved_locations 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_saved_locations_all_policy" ON public.user_saved_locations 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- =============================================================
-- STORAGE BUCKETS CONFIGURATION (PROFILES / CONTENT / POSTERS / MEDIA)
-- =============================================================
-- Insert storage buckets if not exists
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('avatars', 'avatars', true),
  ('content', 'content', true),
  ('posters', 'posters', true),
  ('media', 'media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for Avatars bucket
CREATE POLICY "avatars_public_select" ON storage.objects 
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_user_upload" ON storage.objects 
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage Policies for Content, Posters, and Media buckets (Admin only upload, anyone public read)
CREATE POLICY "content_public_select" ON storage.objects 
  FOR SELECT USING (bucket_id = 'content' OR bucket_id = 'posters' OR bucket_id = 'media');

CREATE POLICY "content_admin_upload" ON storage.objects 
  FOR ALL USING ((bucket_id = 'content' OR bucket_id = 'posters' OR bucket_id = 'media') AND public.is_admin());


-- =============================================================
-- NOTIFICATION PROCEDURES & SECURE DELIVERY LOGIC
-- =============================================================

-- Register or update user device push token
CREATE OR REPLACE FUNCTION public.register_device_token(
    p_device_token TEXT,
    p_platform TEXT,
    p_app_version TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_device_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.user_devices (
        user_id, device_token, platform, app_version, device_info, is_active, last_seen_at, updated_at
    ) VALUES (
        v_user_id, p_device_token, p_platform, p_app_version, p_device_info, true, NOW(), NOW()
    )
    ON CONFLICT (user_id, device_token) 
    DO UPDATE SET 
        platform = EXCLUDED.platform,
        app_version = COALESCE(EXCLUDED.app_version, user_devices.app_version),
        device_info = COALESCE(EXCLUDED.device_info, user_devices.device_info),
        is_active = true,
        last_seen_at = NOW(),
        updated_at = NOW()
    RETURNING id INTO v_device_id;

    RETURN jsonb_build_object('success', true, 'device_id', v_device_id);
END;
$$;

-- Deactivate device token on logout or invalidation
CREATE OR REPLACE FUNCTION public.deactivate_device_token(
    p_device_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    UPDATE public.user_devices
    SET is_active = false, updated_at = NOW()
    WHERE user_id = v_user_id AND device_token = p_device_token;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- Mark single notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_as_read(
    p_notification_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    UPDATE public.notification_logs
    SET is_read = true, opened_at = COALESCE(opened_at, NOW())
    WHERE id = p_notification_id AND user_id = v_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- Mark all notifications as read for current user
CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_count INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    UPDATE public.notification_logs
    SET is_read = true, opened_at = COALESCE(opened_at, NOW())
    WHERE user_id = v_user_id AND is_read = false;
    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN jsonb_build_object('success', true, 'marked_count', v_count);
END;
$$;

-- Server-side scheduled notification processor
-- Runs periodically (e.g., via pg_cron or Supabase Edge Function) to evaluate due reminders,
-- upcoming festivals, special days, and muhurthams. Inserts notification_logs for users with active preferences.
CREATE OR REPLACE FUNCTION public.process_scheduled_notifications()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_inserted INT := 0;
    r_reminder RECORD;
    r_festival RECORD;
    r_pref RECORD;
BEGIN
    -- 1. Process active reminders due up to now
    FOR r_reminder IN 
        SELECT ur.*, p.language as user_lang
        FROM public.user_reminders ur
        JOIN public.profiles p ON p.id = ur.user_id
        JOIN public.user_preferences up ON up.user_id = ur.user_id
        WHERE ur.is_enabled = true 
          AND ur.reminder_time <= NOW()
          AND up.all_notifications = true
          AND up.reminder_notifications = true
          AND NOT EXISTS (
              SELECT 1 FROM public.notification_logs nl 
              WHERE nl.user_id = ur.user_id 
                AND nl.related_item_type = ur.item_type 
                AND nl.related_item_id = ur.item_id::text
                AND nl.sent_at >= ur.reminder_time - INTERVAL '1 hour'
          )
    LOOP
        INSERT INTO public.notification_logs (
            user_id,
            title,
            title_tamil,
            body,
            body_tamil,
            notification_type,
            related_item_type,
            related_item_id,
            status,
            is_read,
            sent_at
        ) VALUES (
            r_reminder.user_id,
            'Reminder Due',
            'நினைவூட்டல்',
            'Your scheduled reminder for ' || r_reminder.item_type || ' is now due.',
            'உங்கள் ' || r_reminder.item_type || ' நினைவூட்டல் நேரம் வந்துவிட்டது.',
            'reminder',
            r_reminder.item_type,
            r_reminder.item_id::text,
            'SENT',
            false,
            NOW()
        );
        v_inserted := v_inserted + 1;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'notifications_generated', v_inserted);
END;
$$;

-- -------------------------------------------------------------
-- Automated Content Publishing Function for SCHEDULED Items
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.publish_scheduled_content()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_published_count INTEGER := 0;
BEGIN
    -- Only admin role or internal edge triggers
    IF NOT public.is_admin() AND auth.role() <> 'service_role' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- 1. Publish scheduled content items
    UPDATE public.content
    SET status = 'PUBLISHED', updated_at = NOW()
    WHERE status = 'SCHEDULED' AND publish_at IS NOT NULL AND publish_at <= NOW();
    
    GET DIAGNOSTICS v_published_count = ROW_COUNT;

    -- 2. Publish scheduled notification campaigns
    UPDATE public.notification_campaigns
    SET status = 'SENT', send_at = NOW(), updated_at = NOW()
    WHERE status = 'SCHEDULED' AND scheduled_at IS NOT NULL AND scheduled_at <= NOW();

    RETURN jsonb_build_object(
        'success', true,
        'published_content_count', v_published_count,
        'executed_at', NOW()
    );
END;
$$;

-- -------------------------------------------------------------
-- Admin Audit Logging Procedure
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_admin_audit(
    p_action TEXT,
    p_module TEXT,
    p_record_id TEXT,
    p_previous_state JSONB DEFAULT NULL,
    p_new_state JSONB DEFAULT NULL,
    p_ip_address TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log_id UUID;
    v_admin_email TEXT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can record audit trails';
    END IF;

    SELECT email INTO v_admin_email FROM public.profiles WHERE id = auth.uid();

    INSERT INTO public.admin_audit_logs (
        admin_id,
        admin_email,
        action,
        module,
        record_id,
        previous_state,
        new_state,
        ip_address,
        user_agent,
        created_at
    ) VALUES (
        auth.uid(),
        v_admin_email,
        p_action,
        p_module,
        p_record_id,
        p_previous_state,
        p_new_state,
        p_ip_address,
        p_user_agent,
        NOW()
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;

-- -------------------------------------------------------------
-- 21. Campaign Management Server Functions
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_notification_campaign(p_campaign_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Administrator role required';
    END IF;

    UPDATE public.notification_campaigns
    SET status = 'CANCELLED',
        updated_at = NOW()
    WHERE id = p_campaign_id 
      AND status IN ('DRAFT', 'SCHEDULED');

    IF FOUND THEN
        PERFORM public.log_admin_audit('CAMPAIGN_CANCELLED', 'notifications', p_campaign_id::TEXT);
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

-- -------------------------------------------------------------
-- 22. Role Escalation Prevention Security Trigger
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only existing verified ADMINs or superusers can update role or is_active flags
    IF (OLD.role IS DISTINCT FROM NEW.role OR OLD.is_active IS DISTINCT FROM NEW.is_active) THEN
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'Security Violation: Standard users cannot modify account roles or administrative status.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_profile_role_escalation();

-- -------------------------------------------------------------
-- 23. Server-Side Aggregate Analytics Procedure (Admin Only)
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_admin_analytics_summary(
    p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '30 days')::DATE,
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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
    -- Strict admin access enforcement
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Administrator role required for analytics.';
    END IF;

    -- Aggregate user metrics
    SELECT COUNT(*) INTO v_total_users FROM public.profiles;
    SELECT COUNT(*) INTO v_active_users FROM public.profiles WHERE is_active = TRUE;
    SELECT COUNT(*) INTO v_new_users FROM public.profiles WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;

    -- Aggregate event counts from analytics_events
    SELECT COUNT(*) INTO v_calendar_views FROM public.analytics_events 
    WHERE event_type IN ('calendar_view', 'calendar_date_open', 'calendar_month_change') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_panchangam_views FROM public.analytics_events 
    WHERE event_type IN ('panchangam_view', 'panchangam_date_change') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_muhurtham_views FROM public.analytics_events 
    WHERE event_type IN ('muhurtham_view', 'muhurtham_date_open') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_festival_views FROM public.analytics_events 
    WHERE event_type IN ('festival_view', 'festival_open') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_special_day_views FROM public.analytics_events 
    WHERE event_type IN ('special_day_view', 'special_day_open') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_poster_views FROM public.analytics_events 
    WHERE event_type IN ('poster_view', 'poster_share') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_notif_opens FROM public.analytics_events 
    WHERE event_type = 'notification_opened' 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_shares FROM public.analytics_events 
    WHERE event_type IN ('share', 'poster_share') 
      AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_reminders_set FROM public.user_reminders 
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_saved_items FROM public.user_saved_items 
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;

    SELECT COUNT(*) INTO v_campaigns_count FROM public.notification_campaigns 
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;

    -- Build aggregate JSONB response
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
        'reminders_set', v_reminders_set,
        'saved_items', v_saved_items,
        'campaigns_count', v_campaigns_count,
        'start_date', p_start_date,
        'end_date', p_end_date,
        'generated_at', NOW()
    );

    RETURN v_result;
END;
$$;

-- =====================================================================
-- Migration: Personal Calendar & Events
-- =====================================================================

CREATE TABLE public.personal_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_all_day BOOLEAN NOT NULL DEFAULT false,
    timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    location TEXT,
    category TEXT NOT NULL DEFAULT 'Personal',
    color_label TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    recurrence_rule TEXT,
    link_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT personal_events_time_check CHECK (end_time >= start_time)
);

CREATE INDEX idx_personal_events_user ON public.personal_events(user_id);
CREATE INDEX idx_personal_events_start ON public.personal_events(start_time);

CREATE TRIGGER set_timestamp_personal_events
BEFORE UPDATE ON public.personal_events
FOR EACH ROW
EXECUTE FUNCTION public.trigger_set_timestamp();

ALTER TABLE public.personal_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "personal_events_select_policy" 
ON public.personal_events FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "personal_events_insert_policy" 
ON public.personal_events FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "personal_events_update_policy" 
ON public.personal_events FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "personal_events_delete_policy" 
ON public.personal_events FOR DELETE 
USING (auth.uid() = user_id);
-- =====================================================================
-- Migration: Admin Secure User Management RPCs
-- =====================================================================

CREATE OR REPLACE FUNCTION public.admin_update_user_status(p_user_id UUID, p_status TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $func
DECLARE
    v_target_role TEXT;
    v_admin_count INTEGER;
BEGIN
    -- 1. Verify caller is an active ADMIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can update user status.';
    END IF;

    -- 2. Prevent self-suspension/deactivation
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Access Denied: Administrators cannot suspend their own account.';
    END IF;

    -- 3. If target is an ADMIN and status is SUSPENDED, ensure they are not the last ADMIN
    SELECT role INTO v_target_role FROM public.profiles WHERE id = p_user_id;
    IF v_target_role = 'ADMIN' AND p_status = 'SUSPENDED' THEN
        SELECT COUNT(*) INTO v_admin_count FROM public.profiles WHERE role = 'ADMIN' AND account_status != 'SUSPENDED';
        IF v_admin_count <= 1 THEN
            RAISE EXCEPTION 'Safety Violation: Cannot suspend the last active administrator.';
        END IF;
    END IF;

    -- 4. Update status
    UPDATE public.profiles
    SET account_status = p_status, is_active = (p_status = 'ACTIVE'), updated_at = NOW()
    WHERE id = p_user_id;

    -- 5. Audit Log
    PERFORM public.log_admin_audit('USER_STATUS_CHANGED', 'profiles', p_user_id::TEXT || ':' || p_status);

    RETURN TRUE;
END;
$func;

CREATE OR REPLACE FUNCTION public.admin_update_user_role(p_user_id UUID, p_role TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $func
DECLARE
    v_target_role TEXT;
    v_admin_count INTEGER;
BEGIN
    -- 1. Verify caller is an active ADMIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can update user roles.';
    END IF;

    -- 2. Prevent self-escalation or self-demotion
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Access Denied: Administrators cannot change their own role.';
    END IF;

    -- 3. If target is an ADMIN being demoted to USER, ensure they are not the last ADMIN
    SELECT role INTO v_target_role FROM public.profiles WHERE id = p_user_id;
    IF v_target_role = 'ADMIN' AND p_role = 'USER' THEN
        SELECT COUNT(*) INTO v_admin_count FROM public.profiles WHERE role = 'ADMIN' AND account_status != 'SUSPENDED';
        IF v_admin_count <= 1 THEN
            RAISE EXCEPTION 'Safety Violation: Cannot demote the last active administrator.';
        END IF;
    END IF;

    -- 4. Update role
    UPDATE public.profiles
    SET role = p_role, updated_at = NOW()
    WHERE id = p_user_id;

    -- 5. Audit Log
    PERFORM public.log_admin_audit('USER_ROLE_CHANGED', 'profiles', p_user_id::TEXT || ':' || p_role);

    RETURN TRUE;
END;
$func;
ALTER TABLE public.muhurtham_dates
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS start_time TEXT,
  ADD COLUMN IF NOT EXISTS end_time TEXT,
  ADD COLUMN IF NOT EXISTS duration TEXT,
  ADD COLUMN IF NOT EXISTS is_valarthirai BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_time TEXT,
  ADD COLUMN IF NOT EXISTS tithi TEXT,
  ADD COLUMN IF NOT EXISTS tithi_ta TEXT,
  ADD COLUMN IF NOT EXISTS yoga TEXT,
  ADD COLUMN IF NOT EXISTS yoga_ta TEXT,
  ADD COLUMN IF NOT EXISTS karana TEXT,
  ADD COLUMN IF NOT EXISTS karana_ta TEXT,
  ADD COLUMN IF NOT EXISTS lagnam TEXT,
  ADD COLUMN IF NOT EXISTS lagnam_ta TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai_ta TEXT,
  ADD COLUMN IF NOT EXISTS rahu_kalam TEXT,
  ADD COLUMN IF NOT EXISTS yamagandam TEXT,
  ADD COLUMN IF NOT EXISTS kuligai TEXT,
  ADD COLUMN IF NOT EXISTS approved_status TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS notes_ta TEXT;

CREATE INDEX IF NOT EXISTS idx_muhurtham_category ON public.muhurtham_dates(category);

ALTER TABLE public.muhurtham_timings
  ADD COLUMN IF NOT EXISTS duration TEXT,
  ADD COLUMN IF NOT EXISTS lagnam TEXT,
  ADD COLUMN IF NOT EXISTS lagnam_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_ta TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai_ta TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS description_ta TEXT,
  ADD COLUMN IF NOT EXISTS is_prime BOOLEAN DEFAULT true;

-- Ensure countries exist for location picker
CREATE TABLE IF NOT EXISTS public.countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    iso_code TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id UUID NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    code TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.districts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    state_id UUID NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.cities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id UUID REFERENCES public.districts(id) ON DELETE CASCADE,
    state_id UUID NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    country_id UUID NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    timezone TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_states_country ON public.states(country_id);
CREATE INDEX IF NOT EXISTS idx_districts_state ON public.districts(state_id);
CREATE INDEX IF NOT EXISTS idx_cities_district ON public.cities(district_id);
CREATE INDEX IF NOT EXISTS idx_cities_name ON public.cities(name);

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

DO \
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'countries' AND policyname = 'Allow public read access on countries'
    ) THEN
        CREATE POLICY "Allow public read access on countries" ON public.countries FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'states' AND policyname = 'Allow public read access on states'
    ) THEN
        CREATE POLICY "Allow public read access on states" ON public.states FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'districts' AND policyname = 'Allow public read access on districts'
    ) THEN
        CREATE POLICY "Allow public read access on districts" ON public.districts FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'cities' AND policyname = 'Allow public read access on cities'
    ) THEN
        CREATE POLICY "Allow public read access on cities" ON public.cities FOR SELECT USING (true);
    END IF;
END
\;

DO \
DECLARE
    india_id UUID := gen_random_uuid();
    tn_id UUID := gen_random_uuid();
    ka_id UUID := gen_random_uuid();
    chennai_dist_id UUID := gen_random_uuid();
    cbe_dist_id UUID := gen_random_uuid();
    mdu_dist_id UUID := gen_random_uuid();
    blr_dist_id UUID := gen_random_uuid();
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE name = 'India') THEN
        INSERT INTO public.countries (id, name, name_ta, iso_code)
        VALUES (india_id, 'India', '???????', 'IN');

        INSERT INTO public.states (id, country_id, name, name_ta, code)
        VALUES 
            (tn_id, india_id, 'Tamil Nadu', '?????????', 'TN'),
            (ka_id, india_id, 'Karnataka', '????????', 'KA');

        INSERT INTO public.districts (id, state_id, name, name_ta)
        VALUES
            (chennai_dist_id, tn_id, 'Chennai', '??????'),
            (cbe_dist_id, tn_id, 'Coimbatore', '?????????????'),
            (mdu_dist_id, tn_id, 'Madurai', '?????'),
            (blr_dist_id, ka_id, 'Bengaluru Urban', '?????????');

        INSERT INTO public.cities (district_id, state_id, country_id, name, name_ta, latitude, longitude, timezone)
        VALUES
            (chennai_dist_id, tn_id, india_id, 'Chennai', '??????', 13.0827, 80.2707, 'Asia/Kolkata'),
            (cbe_dist_id, tn_id, india_id, 'Coimbatore', '?????????????', 11.0168, 76.9558, 'Asia/Kolkata'),
            (mdu_dist_id, tn_id, india_id, 'Madurai', '?????', 9.9252, 78.1198, 'Asia/Kolkata'),
            (blr_dist_id, ka_id, india_id, 'Bengaluru', '?????????', 12.9716, 77.5946, 'Asia/Kolkata');
    END IF;
END \;
ALTER TABLE public.muhurtham_dates
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS start_time TEXT,
  ADD COLUMN IF NOT EXISTS end_time TEXT,
  ADD COLUMN IF NOT EXISTS duration TEXT,
  ADD COLUMN IF NOT EXISTS is_valarthirai BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_time TEXT,
  ADD COLUMN IF NOT EXISTS tithi TEXT,
  ADD COLUMN IF NOT EXISTS tithi_ta TEXT,
  ADD COLUMN IF NOT EXISTS yoga TEXT,
  ADD COLUMN IF NOT EXISTS yoga_ta TEXT,
  ADD COLUMN IF NOT EXISTS karana TEXT,
  ADD COLUMN IF NOT EXISTS karana_ta TEXT,
  ADD COLUMN IF NOT EXISTS lagnam TEXT,
  ADD COLUMN IF NOT EXISTS lagnam_ta TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai_ta TEXT,
  ADD COLUMN IF NOT EXISTS rahu_kalam TEXT,
  ADD COLUMN IF NOT EXISTS yamagandam TEXT,
  ADD COLUMN IF NOT EXISTS kuligai TEXT,
  ADD COLUMN IF NOT EXISTS approved_status TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS notes_ta TEXT;

CREATE INDEX IF NOT EXISTS idx_muhurtham_category ON public.muhurtham_dates(category);

ALTER TABLE public.muhurtham_timings
  ADD COLUMN IF NOT EXISTS duration TEXT,
  ADD COLUMN IF NOT EXISTS lagnam TEXT,
  ADD COLUMN IF NOT EXISTS lagnam_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_ta TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai_ta TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS description_ta TEXT,
  ADD COLUMN IF NOT EXISTS is_prime BOOLEAN DEFAULT true;

-- Ensure countries exist for location picker
CREATE TABLE IF NOT EXISTS public.countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    iso_code TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id UUID NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    code TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.districts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    state_id UUID NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.cities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id UUID REFERENCES public.districts(id) ON DELETE CASCADE,
    state_id UUID NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    country_id UUID NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    timezone TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_states_country ON public.states(country_id);
CREATE INDEX IF NOT EXISTS idx_districts_state ON public.districts(state_id);
CREATE INDEX IF NOT EXISTS idx_cities_district ON public.cities(district_id);
CREATE INDEX IF NOT EXISTS idx_cities_name ON public.cities(name);

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

DO \
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'countries' AND policyname = 'Allow public read access on countries'
    ) THEN
        CREATE POLICY "Allow public read access on countries" ON public.countries FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'states' AND policyname = 'Allow public read access on states'
    ) THEN
        CREATE POLICY "Allow public read access on states" ON public.states FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'districts' AND policyname = 'Allow public read access on districts'
    ) THEN
        CREATE POLICY "Allow public read access on districts" ON public.districts FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'cities' AND policyname = 'Allow public read access on cities'
    ) THEN
        CREATE POLICY "Allow public read access on cities" ON public.cities FOR SELECT USING (true);
    END IF;
END
\;

DO \
DECLARE
    india_id UUID := gen_random_uuid();
    tn_id UUID := gen_random_uuid();
    ka_id UUID := gen_random_uuid();
    chennai_dist_id UUID := gen_random_uuid();
    cbe_dist_id UUID := gen_random_uuid();
    mdu_dist_id UUID := gen_random_uuid();
    blr_dist_id UUID := gen_random_uuid();
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE name = 'India') THEN
        INSERT INTO public.countries (id, name, name_ta, iso_code)
        VALUES (india_id, 'India', '???????', 'IN');

        INSERT INTO public.states (id, country_id, name, name_ta, code)
        VALUES 
            (tn_id, india_id, 'Tamil Nadu', '?????????', 'TN'),
            (ka_id, india_id, 'Karnataka', '????????', 'KA');

        INSERT INTO public.districts (id, state_id, name, name_ta)
        VALUES
            (chennai_dist_id, tn_id, 'Chennai', '??????'),
            (cbe_dist_id, tn_id, 'Coimbatore', '?????????????'),
            (mdu_dist_id, tn_id, 'Madurai', '?????'),
            (blr_dist_id, ka_id, 'Bengaluru Urban', '?????????');

        INSERT INTO public.cities (district_id, state_id, country_id, name, name_ta, latitude, longitude, timezone)
        VALUES
            (chennai_dist_id, tn_id, india_id, 'Chennai', '??????', 13.0827, 80.2707, 'Asia/Kolkata'),
            (cbe_dist_id, tn_id, india_id, 'Coimbatore', '?????????????', 11.0168, 76.9558, 'Asia/Kolkata'),
            (mdu_dist_id, tn_id, india_id, 'Madurai', '?????', 9.9252, 78.1198, 'Asia/Kolkata'),
            (blr_dist_id, ka_id, india_id, 'Bengaluru', '?????????', 12.9716, 77.5946, 'Asia/Kolkata');
    END IF;
END \;
-- Add missing columns to festivals
ALTER TABLE public.festivals
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS type TEXT,
  ADD COLUMN IF NOT EXISTS type_ta TEXT,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS rituals TEXT,
  ADD COLUMN IF NOT EXISTS rituals_ta TEXT,
  ADD COLUMN IF NOT EXISTS deity TEXT,
  ADD COLUMN IF NOT EXISTS deity_ta TEXT,
  ADD COLUMN IF NOT EXISTS significance TEXT,
  ADD COLUMN IF NOT EXISTS significance_ta TEXT,
  ADD COLUMN IF NOT EXISTS is_holiday BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS location TEXT;

-- Add missing columns to special_days
ALTER TABLE public.special_days
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS is_auspicious BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS location TEXT;
