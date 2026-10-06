# TNT Security Baseline Audit

## Phase 0 - Security Baseline Findings

### Audit Scope
Inspected the following areas across the TNT Tamil Calendar Flutter repository:
- `lib/` (Flutter source code)
- `android/` (Android configuration, manifest, gradle)
- `supabase_migration.sql` (Database schema and RLS)
- `.env.staging` and `pubspec.yaml` (Assets and Environment Configuration)
- Global search for sensitive credentials (`service_role`, `API_KEY`, `SECRET`, `PASSWORD`, `JWT`, etc.)

### Findings

#### 1. CRITICAL: Sensitive Secrets Exposed in Flutter Assets
- **Finding:** The file `.env.staging` was included in `pubspec.yaml` under `assets:`. This file contained the `NAVAMSHA_API_KEY`, `JWT_SECRET`, `GOOGLE_CLIENT_SECRET`, and `DIRECT_URL` (containing the PostgreSQL database password). 
- **Impact:** Any user could decompile the APK, extract `.env.staging`, and gain full unauthorized access to the Navamsha API, Google OAuth, and the direct PostgreSQL database connection, entirely bypassing RLS and authentication.
- **Action Taken:** Immediately removed the sensitive keys (`DIRECT_URL`, `SMTP_USER`, `SMTP_PASS`, `NAVAMSHA_API_KEY`, `JWT_SECRET`, `GOOGLE_CLIENT_SECRET`) from `.env.staging`. The file now only contains `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GOOGLE_CLIENT_ID`.

#### 2. HIGH: iOS Build/Security Hardening Blocked
- **Finding:** The `ios/` directory does not exist in the repository.
- **Impact:** iOS-specific security configurations (Info.plist, ATS, Keychain, URL Schemes) cannot be audited or hardened.
- **Action Taken:** Marked iOS security tasks as BLOCKED. The app is currently Android-only.

#### 3. MEDIUM: Android Backup Not Explicitly Disabled
- **Finding:** `android:allowBackup` is not explicitly defined in `android/app/src/main/AndroidManifest.xml`. By default, Android may back up application data (including SharedPreferences where auth tokens might be stored) to the user's Google Drive.
- **Impact:** If a user's Google account is compromised, sensitive app data could be extracted from the backup.
- **Action Taken:** Needs remediation in Phase 34 (Android Backup).

#### 4. INFO: Supabase Anonymous Key in Client
- **Finding:** The `SUPABASE_ANON_KEY` is present in `lib/services/supabase_service.dart` (as a fallback) and `.env.staging`.
- **Impact:** Expected behavior. The anonymous key is designed to be public and is secured via Row Level Security (RLS).
- **Action Taken:** No action needed, but depends heavily on RLS being robust.

#### 5. INFO: RLS Enabled on All Tables
- **Finding:** `supabase_migration.sql` contains `ENABLE ROW LEVEL SECURITY` for all tables (e.g., `profiles`, `calendar_days`, `festivals`, `personal_events`, `admin_audit_logs`).
- **Impact:** Strong foundational security. RLS is actively enforced at the database level.
- **Action Taken:** Will proceed to verify the specific RLS policies (SELECT/INSERT/UPDATE/DELETE) in Phase 15.

#### 6. INFO: No `service_role` Key Leaked
- **Finding:** A repository-wide search confirmed that the Supabase `service_role` key is **not** present anywhere in the client code, assets, or configuration.
- **Impact:** Prevents total database compromise.

### Baseline Conclusion
The most critical vulnerability (bundled secrets in `.env.staging`) has been immediately remediated. The codebase fundamentally follows a secure architecture (Edge Functions for Navamsha, RLS enabled, no service_role key in client), but requires further hardening of RLS policies, Android configuration, and API request validation. Proceeding to Threat Modeling and Security Architecture.
