# TNT Tamil Calendar — Security & Scalability Baseline Audit

**Project:** `C:\Users\Vishw\Downloads\TNT`  
**Audit Timestamp:** October 2026  
**Objective:** Comprehensive architectural audit across Security, Row-Level Security (RLS), Role-Based Access Control (RBAC), and 1,000+ Concurrent User Scalability.

---

## 1. Architecture & Technology Baseline

* **Frontend Framework:** Flutter 3.47+ / Dart 3.x
* **Backend Platform:** Supabase (PostgreSQL 15+, Supabase Auth, Storage, Edge Functions, GoTrue, Realtime)
* **Authentication Providers:** Supabase Auth (Email + Password), Google OAuth (`tntcalendar://login-callback/`), Custom 6-digit SHA-256 Hashed Email OTP via Edge Function, SMS/Mobile OTP via Edge Function.
* **Database Objects:** 37 tables, 15 stored functions (12 `SECURITY DEFINER`), 46 custom indexes, 66 RLS policies.
* **Client Architecture:** Repository + Service Provider pattern with `AuthStateManager` (`ChangeNotifier`) controlling UI authentication gates and offline mathematical Panchangam calculation fallback.
* **Production Packaging:** Android split-per-ABI release APKs (`arm64-v8a`: ~21.6 MB, `armeabi-v7a`: ~19.3 MB, `x86_64`: ~23.0 MB).

---

## 2. Security Audit Findings by Severity

### 🔴 Critical Severity Findings

#### SEC-CRIT-01: Client-Side Account Status & Verification Bypass on `public.profiles`
* **Vulnerability:** The trigger function `public.protect_profile_role_escalation()` only guarded `OLD.role IS DISTINCT FROM NEW.role` and `OLD.is_active IS DISTINCT FROM NEW.is_active`.
* **Exploit Vector:** A standard authenticated user calling Supabase client `profiles.update({'account_status': 'ACTIVE', 'email_verified_at': now})` bypassed the email OTP Edge Function completely and elevated their own unverified account directly to `ACTIVE`.
* **Impact:** Broken authentication verification state; unverified accounts can access verified features without completing OTP challenges.
* **Required Remediation:** Harden `protect_profile_role_escalation()` to disallow standard users from modifying `account_status`, `email_verified_at`, and `phone_verified_at`. Add `WITH CHECK` constraint to `profiles_update_policy`.

#### SEC-CRIT-02: Missing `search_path` in 10 `SECURITY DEFINER` Functions (Search Path Hijacking)
* **Vulnerability:** `public.handle_new_user`, `public.is_admin`, `public.deactivate_device_token`, `public.mark_notification_as_read`, `public.mark_all_notifications_as_read`, `public.process_scheduled_notifications`, `public.publish_scheduled_content`, `public.log_admin_audit`, `public.cancel_notification_campaign`, `public.protect_profile_role_escalation`, and `public.get_admin_analytics_summary` execute as database owner (`SECURITY DEFINER`) without explicit `SET search_path = public, pg_temp;`.
* **Exploit Vector:** Attacker creating malicious schemas or functions in user-accessible schemas can execute arbitrary code with superuser/owner privileges.
* **Required Remediation:** Set `SET search_path = public, pg_temp;` on all `SECURITY DEFINER` functions.

---

### 🟠 High Severity Findings

#### SEC-HIGH-01: Admin Broadcast Campaigns Blocked from Standard User Dashboard by RLS
* **Vulnerability:** `public.notification_campaigns` only had `notification_campaigns_admin_policy` (`FOR ALL USING (public.is_admin())`). Normal authenticated users had no `SELECT` policy for published campaigns where `status = 'SENT'`.
* **Exploit Vector / Bug:** App users querying broadcast campaigns received 0 rows or permission denied errors.
* **Required Remediation:** Add RLS policy: `CREATE POLICY "notification_campaigns_user_select_policy" ON public.notification_campaigns FOR SELECT USING (status = 'SENT' OR public.is_admin());`.

#### SEC-HIGH-02: `user_reminders` Write Operations Denied by Incomplete RLS
* **Vulnerability:** `public.user_reminders` had RLS enabled but only possessed a `SELECT` policy (`auth.uid() = user_id`). No `INSERT`, `UPDATE`, or `DELETE` policies existed.
* **Exploit Vector / Bug:** Reminders created or modified by users via `ReminderRepository` fail under RLS enforcement.
* **Required Remediation:** Add explicit `INSERT`, `UPDATE`, `DELETE` policies scoped strictly to `auth.uid() = user_id`.

#### SEC-HIGH-03: `is_admin()` Does Not Check Suspension Status & Lacks `STABLE` Optimization
* **Vulnerability:** `public.is_admin()` checked `role = 'ADMIN'` without checking `account_status != 'SUSPENDED'` or `is_active = TRUE`, and was marked `VOLATILE` by default.
* **Exploit Vector:** A suspended admin retained full admin database execution privileges. Also, volatile execution causes Postgres to re-run subqueries per row, slowing down bulk queries.
* **Required Remediation:** Update `is_admin()` to verify `account_status != 'SUSPENDED' AND is_active = TRUE`, mark as `STABLE`, and set `SET search_path = public, pg_temp;`.

#### SEC-HIGH-04: Stale Admin Session State Not Cleared on Sign-Out
* **Vulnerability:** `AdminAuthorizationService` retained `_isVerifiedAdmin = true` across user logouts because `AuthStateManager.signOut()` and `onAuthStateChange` listeners did not explicitly invoke `AdminAuthorizationService().clearSession()`.
* **Exploit Vector:** Logging out from an admin account and logging in with a non-admin account on the same device could temporarily retain cached admin verification flags.
* **Required Remediation:** Explicitly call `AdminAuthorizationService().clearSession()` in `signOut()` and upon any `signedOut` auth event.

---

### 🟡 Medium Severity Findings

#### SEC-MED-01: Direct Client SELECT Exposure of OTP Hashes in `email_verification_challenges`
* **Vulnerability:** Policy `email_challenges_user_select` allowed users to query `otp_hash` for their challenges.
* **Risk:** 6-digit OTP hashes (1,000,000 keyspace) can be brute-forced offline in < 50ms if extracted. Verification is already handled server-side via Edge Function with service-role key.
* **Required Remediation:** Restrict direct client table SELECT on `email_verification_challenges` to admins only; clients interface strictly via `verify-email-otp` Edge Function.

#### SEC-MED-02: Unbounded In-Memory Table Scans in `AdminAnalyticsRepository`
* **Vulnerability:** `AdminAnalyticsRepository.getSummary()` executed `client.from('profiles').select('id, created_at')` and `client.from('analytics_events').select(...)` downloading entire tables into memory.
* **Impact:** Severe bottleneck under 1,000+ users. Transfers megabytes of data, causing high memory usage and database connection congestion.
* **Required Remediation:** Delegate aggregation to the server-side `get_admin_analytics_summary` RPC procedure with `COUNT(*)` aggregation.

#### SEC-MED-03: Missing Key Foreign-Key and Filter Indexes
* **Missing Indexes:**
  1. `profiles(email)` — used in lookups, login, and Edge Functions.
  2. `profiles(role, account_status)` — used in `is_admin()` and user management.
  3. `user_preferences(user_id)` — queried on startup for all users.
  4. `user_saved_items(user_id, item_type, item_id)` — queried on bookmarks.
  5. `user_reminders(user_id, reminder_time)` — queried on reminders.
  6. `muhurtham_timings(muhurtham_date_id)` — join column for Muhurtham slots.
  7. `content_media(content_id)` — join column for content posters.
  8. `catering_enquiries(user_id, status)` — queried on leads.
  9. `notification_campaigns(status, sent_at DESC)` — queried on notifications.

---

### 🟢 Low Severity / Observability Findings

#### SEC-LOW-01: Repetitive Public Content Queries Lack In-Memory TTL Caching
* **Observation:** `FestivalRepository`, `SpecialDaysRepository`, `MuhurthamRepository`, and `CalendarRepository` query Supabase on each screen navigation.
* **Impact:** 1,000 concurrent users will generate 5,000+ simultaneous database queries for monthly data that rarely changes.
* **Required Remediation:** Introduce an in-memory TTL cache (10–15 min) with invalidation hooks for admin mutations.

#### SEC-LOW-02: Absence of Request Timeout & Jittered Retry Resilience
* **Observation:** Client network calls lacked structured timeouts and exponential backoff with full jitter for transient network glitches (502, 503, 504, 429).
* **Required Remediation:** Implement `TNTResilience` helper for idempotent reads with bounded retries (max 2 attempts) and jitter.

---

## 3. Table Access Matrix by Role

| Table Name | Public / Anon | Authenticated User | Administrator | Service Role (Edge Fn) |
| :--- | :---: | :---: | :---: | :---: |
| `profiles` | ❌ None | SELECT / UPDATE (Own) | ALL | ALL |
| `email_verification_challenges` | ❌ None | ❌ None (Via Edge Fn) | ALL | ALL |
| `otp_verifications` | ❌ None | ❌ None (Via Edge Fn) | ALL | ALL |
| `user_preferences` | ❌ None | ALL (Own) | ALL | ALL |
| `calendar_days` | SELECT | SELECT | ALL | ALL |
| `panchangam_entries` | SELECT | SELECT | ALL | ALL |
| `timing_entries` | SELECT | SELECT | ALL | ALL |
| `muhurtham_dates` | SELECT (Published) | SELECT (Published) | ALL | ALL |
| `muhurtham_timings` | SELECT (Published) | SELECT (Published) | ALL | ALL |
| `festivals` | SELECT (Published) | SELECT (Published) | ALL | ALL |
| `special_days` | SELECT (Published) | SELECT (Published) | ALL | ALL |
| `content` | SELECT (Published) | SELECT (Published) | ALL | ALL |
| `content_media` | SELECT (Published) | SELECT (Published) | ALL | ALL |
| `user_saved_items` | ❌ None | ALL (Own) | ALL (Own) | ALL |
| `user_reminders` | ❌ None | ALL (Own) | ALL (Own) | ALL |
| `user_devices` | ❌ None | ALL (Own) | ALL | ALL |
| `notification_campaigns` | ❌ None | SELECT (SENT) | ALL | ALL |
| `notification_logs` | ❌ None | SELECT / UPDATE (Own) | ALL | ALL |
| `analytics_events` | ❌ None | INSERT (Own / Anon) | SELECT | ALL |
| `daily_analytics` | ❌ None | ❌ None | ALL | ALL |
| `admin_schedules` | ❌ None | ❌ None | ALL | ALL |
| `media_assets` | SELECT (Active) | SELECT (Active) | ALL | ALL |
| `admin_audit_logs` | ❌ None | ❌ None | ALL | ALL |
| `catering_enquiries` | INSERT (Own) | SELECT / INSERT (Own) | ALL | ALL |
| `system_settings` | SELECT | SELECT | ALL | ALL |

---

## 4. Scalability Target & Capacity Analysis (1,000+ Concurrent Users)

* **Supabase Connection Pooling:**
  * Free/Micro Tier direct PostgreSQL connections: 60 connections.
  * Transaction Pooler (Supavisor port 6543): Supports up to 200–500 pooled client connections.
  * Pro/Production Compute (Small/Medium): Supports 200–500 direct connections, 1,000+ pooled connections.
* **Bottleneck Elimination Strategy:**
  1. **Offline Math & Client-Side Panchangam:** Solar, lunar, Tithi, Nakshatra, Rahu Kalam computations execute locally on the device (0 DB queries per active session).
  2. **In-Memory TTL Caching:** Public monthly datasets (Festivals, Special Days, Muhurtham, Calendar Days) cached in memory for 15 minutes. Cache hits resolve in < 1 ms without hitting Supabase.
  3. **SQL Aggregate Analytics:** Server-side RPC `get_admin_analytics_summary` aggregates millions of events in < 50 ms instead of downloading row dumps.
  4. **Targeted Composite Indexes:** Bounded queries against filtered and sorted columns (`date`, `user_id`, `status`, `sent_at`) utilize index scans.
  5. **Exponential Backoff with Full Jitter:** Eliminates thundering herd / retry storms during intermittent connectivity.

---

## 5. Next Steps
* **Phase B:** Execute security hardening migration (`supabase_security_hardening.sql`) and Dart session isolation updates.
* **Phase C:** Apply composite indexes and client-side TTL caching + resilience retries.
* **Phase D:** Execute realistic 50 -> 100 -> 250 -> 500 -> 1,000 virtual user load tests and benchmark p50/p95/p99 latency.
* **Phase E:** Regression verification and final release APK build.
