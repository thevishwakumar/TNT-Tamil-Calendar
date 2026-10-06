# TNT Dual API Pre-Implementation Audit & Data Flow Report

## Current Data Flow

A. **Calendar**
   - **Source:** Supabase (`calendar_days` table).
   - **Columns:** `id`, `date`, `tamil_date`, `tamil_month`, `tamil_year`, `weekday_tamil`, `weekday_english`
   - **Insert/Update:** Admin scripts/manual data imports.
   - **Select:** `ProductionApiService.getCalendarDay` / `CalendarRepository.getCalendarDays`.
   - **Cache:** App-level caching (Riverpod / local memory).

B. **Panchangam**
   - **Source:** Supabase (`panchangam_entries` table).
   - **Columns:** `id`, `calendar_day_id` (FK), `tithi`, `nakshatra`, `yoga`, `karana`, `sunrise`, `sunset`, `moonrise`, `moonset`.
   - **Insert/Update:** Admin scripts/manual.
   - **Select:** `PanchangRepository.getDailyPanchangam`.
   - **Cache:** App-level caching.

C. **Festivals**
   - **Source:** Supabase (`festivals` table).
   - **Columns:** `id`, `date`, `name_tamil`, `name_english`, `description_tamil`, `description_english`, `is_published`.
   - **Insert/Update:** `AdminContentRepository.upsertFestival`.
   - **Select:** `ProductionApiService.getFestivals` / `FestivalsRepository`.

D. **Special Days**
   - **Source:** Supabase (`special_days` table).
   - **Columns:** `id`, `date`, `name_tamil`, `name_english`, `category` (enum), `description`, `is_published`.
   - **Insert/Update:** `AdminContentRepository.upsertSpecialDay`.
   - **Select:** `ProductionApiService.getSpecialDays`.

E. **Muhurtham Dates**
   - **Source:** Supabase (`muhurtham_dates` table).
   - **Columns:** `id`, `date`, `title_tamil`, `title_english`, `description`, `is_published`, `source_name`.
   - **Insert/Update:** Admin Content Repository.
   - **Select:** `ProductionApiService.getMuhurthamDates`.

F. **Muhurtham Timings**
   - **Source:** Supabase (`muhurtham_timings` table).
   - **Columns:** `id`, `muhurtham_date_id` (FK), `start_time`, `end_time`, `nakshatra...`.
   - **Insert/Update:** Tied to `muhurtham_dates`.
   - **Select:** Joint fetch with `muhurtham_dates`.

G. **Important Timings**
   - **Source:** Supabase (`timing_entries` table).
   - **Columns:** `id`, `calendar_day_id` (FK), `timing_type`, `start_time`, `end_time`.
   - **Insert/Update:** Admin entry.
   - **Select:** `PanchangRepository` locally constructs or queries these based on date.

H. **Admin Manual Entry**
   - Handled via `AdminContentRepository` updating `festivals`, `special_days`, `muhurtham_dates`.
   - Access restricted via RLS & Admin RBAC.

I. **User Dashboard Display**
   - Fetches data securely from Supabase using read-only APIs (`ProductionApiService`).

J. **Caching & Refresh**
   - The app extensively caches fetched responses by date/month to prevent redundant network calls.

K. **RLS Policies**
   - Admin roles can INSERT/UPDATE. Public/User roles can only SELECT `is_published = true` content.

---
## Known Errors & Resolutions (Phase 30)
1. **analytics_events POST 409 (FK user_id):** Resolved in previous session by omitting `user_id` for anonymous users.
2. **calendar_days GET 400 (gregorian_date missing):** Resolved in previous session by matching exactly the `date` column.
3. **important_timings GET 404:** Resolved by delegating to `PanchangRepository.getDailyPanchangam` or utilizing the `timing_entries` table directly.

## Conclusion
The schema provides independent tables for `festivals`, `special_days`, and a normalized relational structure for `calendar_days` + `panchangam_entries` + `timing_entries`. Any external sync must carefully map into this existing normalized PostgreSQL structure without causing duplicate keys or data overwrites.
