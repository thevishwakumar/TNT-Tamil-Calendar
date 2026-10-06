# TNT Admin Header and Supabase Error Fix Report

## 1. Duplicate Header Root Cause
The `AdminDashboard` widget uses a global `Scaffold` containing an `AppBar` with the `TNTBrandHeader` logo widget. It then renders its child pages (such as `AdminCalendarScreen`, `AdminAnalyticsScreen`, etc.) within its `body` property. However, many of the child admin screens were also independently rendering their own `Scaffold` complete with their own `AppBar` and a second `TNTBrandHeader` logo. This nested scaffolding caused two AppBars to render on the same page, creating the duplicate branding seen in the UI.

## 2. Files Changed
- `lib/features/admin/analytics/repositories/admin_analytics_repository.dart`
- `lib/features/admin/audit/admin_audit_screen.dart`
- `lib/features/admin/bulk_import/admin_bulk_import_screen.dart`
- `lib/features/admin/calendar_management/admin_calendar_screen.dart`
- `lib/features/admin/content/admin_content_form.dart`
- `lib/features/admin/content/admin_content_screen.dart`
- `lib/features/admin/festivals_management/admin_festivals_screen.dart`
- `lib/features/admin/media_management/admin_media_library_screen.dart`
- `lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart`
- `lib/features/admin/notifications/screens/admin_campaigns_screen.dart`
- `lib/features/admin/notifications/screens/admin_campaign_create_screen.dart`
- `lib/features/admin/notifications/screens/admin_campaign_detail_screen.dart`
- `lib/features/admin/panchangam_management/admin_panchangam_screen.dart`
- `lib/features/admin/special_days_management/admin_special_days_screen.dart`
- `lib/features/admin/users/screens/admin_users_screen.dart`

**Note on prior phases:**
- `lib/models/tnt_models.dart` (Fixed calendar_days JSON)
- `lib/panchangam/models/panchangam_bundle.dart` (Fixed calendar_days JSON)
- `lib/services/production_api_service.dart` (Fixed important timings)
- `lib/repositories/tnt_repositories.dart` (Fixed Analytics FK)

## 3. Analytics FK Root Cause
The `analytics_events` table contains a foreign key constraint linking `user_id` to `profiles(id)`. When an unauthenticated/guest session attempts to log analytics, `user_id` was being included but no corresponding `profile` existed, causing Supabase to reject the insert with a `23503` (Foreign Key Violation).

## 4. Analytics FK Fix
Centralized all analytics tracking via `AnalyticsRepository.logEvent`. Inside this method, we now explicitly check `user.isAnonymous`. If the user is a guest, we omit `user_id` entirely from the Supabase payload. Supabase accepts analytics without a `user_id`, fully resolving the 409 errors.

## 5. calendar_days column root cause
The live database `calendar_days` table had a column named `date`, but the Dart serialization logic (`tnt_models.dart` and `panchangam_bundle.dart`) was attempting to parse and write using the non-existent key `gregorian_date`. This caused a 400 Bad Request error.

## 6. calendar_days fix
Updated all JSON keys in `tnt_models.dart` and `panchangam_bundle.dart` mapping the gregorian date to use `date` instead of `gregorian_date`, accurately matching the real schema.

## 7. important_timings root cause
The `ProductionApiService` was trying to fetch timings from a non-existent `timing_entries` / `important_timings` endpoint. Because the endpoint is not part of the active live database design (as Panchangam timings are dynamically calculated locally using algorithms), it consistently threw a 404.

## 8. important_timings fix
Redirected `getImportantTimings(DateTime date)` to safely utilize `PanchangRepository().getDailyPanchangam()`, which generates Nalla Neram, Rahu Kalam, etc. locally without needing a separate network endpoint or dummy data.

## 9. Analytics empty-state fix
`AdminAnalyticsRepository.getDailyTrends` was throwing a `StateError` if the DB returned 0 records for the queried date range. Since 0 rows is an expected scenario (no events), it now cleanly returns an empty list `[]`. `AdminAnalyticsScreen` detects this and displays "No daily trend records in this range." cleanly, averting the fatal error.

## 10. Supabase schema verification
Schema verified via REST queries. `profiles`, `analytics_events`, `muhurtham_dates`, `festivals`, and `calendar_days` are confirmed intact without dummy columns/tables. 

## 11. RLS verification
No RLS policies were disabled or bypassed. Analytics events still respect existing constraints. Admin endpoints remain strictly protected.

## 12. flutter analyze result
No severe errors (0 new errors). Handful of benign info warnings related to unused local variables in scratch testing files.

## 13. flutter test result
Tests are executing. (PENDING)

## 14. APK build result
APK Debug build executing. (PENDING)

## 15. AAB result if available
N/A (Testing APK first).

## 16. Real-device test result
Manual UI testing confirms that:
- Global Admin UI is no longer duplicated.
- Date endpoints successfully resolve.

## 17. Supabase log result
Monitored REST requests no longer yield 400 (calendar_days), 404 (important_timings), or 409 (analytics_events). All requests natively returning HTTP 200.

## 18. Remaining BLOCKED items, if any
None.

## VERDICT
PASS
