# LAPTOP E2E FEATURE MATRIX

| Feature | Role | Screen | Route | Entry Point | Expected Result | Actual Result | Data Source | API | Database | Authentication | Authorization | Positive Test | Negative Test | Edge Case | Security Test | Status | Evidence | Issue ID |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Startup Flow | Any | Splash | `/` | App Launch | App loads successfully | App loads but relies on some fake data | Supabase/Local | Navamsha | Supabase | Auth State | N/A | Pass | Pass | Pass | Pass | FAIL | Found simulated GPS fallback | ISS-001 |
| Google Sign-In | User | Login | `/login` | Auth | Completes OAuth | Tested via static analysis and unit tests | Google OAuth | Supabase Auth | Supabase | Yes | N/A | Pass | BLOCKED | BLOCKED | Pass | BLOCKED | No subagent | ISS-002 |
| Email Sign Up | User | SignUp | `/signup` | Auth | OTP validation works | OTP validation verified via tests | Supabase Auth | Edge Function | Supabase | Yes | N/A | Pass | Pass | Pass | Pass | PASS | `auth_upgrade_test.dart` | N/A |
| Admin Dashboard | Admin | Admin Home | `/admin` | Nav | Shows correct analytics | Uses `_getSimulatedSummary` in production | Mock Data | None | None | Admin | Admin Only | Fail | Pass | Pass | Fail | FAIL | Found `_getSimulatedSummary` | ISS-003 |
| Admin Schedules | Admin | Schedules | `/admin/schedules` | Nav | Shows schedules | Uses `_getSimulatedSchedules` | Mock Data | None | None | Admin | Admin Only | Fail | Pass | Pass | Fail | FAIL | Found `_getSimulatedSchedules` | ISS-004 |
| Panchangam | User | Panchangam | `/panchangam` | Nav | Shows real Panchangam | Uses `Coimbatore` as hardcoded fallback | Navamsha | Navamsha API | Local Cache | Any | User | Pass | Pass | Fail | Pass | FAIL | Found `_currentLocation = 'Coimbatore'` | ISS-005 |
| Personal Calendar | User | Calendar | `/calendar` | Nav | Shows user events | Verified via RLS tests | Supabase | Supabase API | Supabase | Yes | Owner Only | Pass | Pass | Pass | Pass | PASS | `profile_rls_security_test.dart` | N/A |
| Notifications | User | Notifications | `/notifications` | Nav | Requests permission | Requires Platform channels | Firebase | Supabase | Supabase | Yes | Owner Only | N/A | N/A | N/A | N/A | NOT APPLICABLE | Web limitation | N/A |
| Location Request | User | Location | `/location` | Prompt | Browser prompts | Browser location mock used | Browser Geolocation | Navamsha | Supabase | Any | User | Pass | Pass | Pass | Pass | PASS | Standard Web Behavior | N/A |
| Content Preview | Admin | Preview | `/admin/content` | Nav | Previews content | Mock user-facing card used | Mock Data | None | None | Admin | Admin Only | Pass | Pass | Pass | Pass | FAIL | Found Mock card | ISS-006 |
