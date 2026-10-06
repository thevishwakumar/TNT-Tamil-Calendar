# TNT Schema & Production API Audit Report

## 1. Error: `calendar_days.gregorian_date does not exist`
* **Root Cause**: The Flutter code (`production_api_service.dart`) was requesting the column `gregorian_date` because it was built against a legacy `supabase_content_schema.sql` draft. The actual deployed normalized schema (`supabase_migration.sql`) uses the column name `date` in the `calendar_days` table.
* **Current Database Column Actually Available**: `date` (of type `DATE`) inside the `calendar_days` table.
* **Exact Flutter Files/Functions Modified**: 
  - `lib/services/production_api_service.dart` 
  - Function: `getCalendarDay(DateTime date)`
  - Modification: Changed `.eq('gregorian_date', dateStr)` to `.eq('date', dateStr)` and safely parsed missing legacy columns (like `tamil_day`, `tithi`) with default fallbacks (`?? ''`) to prevent null assertion crashes.
* **Exact SQL Migration Required**: None. The safest fix was to update the Flutter API call to match the actual, properly normalized Supabase production schema.

## 2. Error: `muhurtham_dates.category does not exist`
* **Root Cause**: The deployed normalized schema `supabase_migration.sql` replaced `category` with `title_tamil` and `title_english`. However, the app's core architecture, `AdminImportService`, and UI repositories strictly rely on the `category` column to organize and upload data. A SQL migration script (`20261006184000_fix_muhurtham_category.sql`) was previously drafted by the team to fix this but was never executed on the live Supabase instance.
* **Current Database Column Actually Available**: The column did not exist on the live Supabase instance.
* **Exact Flutter Files/Functions Modified**: None required.
* **Exact SQL Migration Executed**:
  ```sql
  ALTER TABLE public.muhurtham_dates
    ADD COLUMN IF NOT EXISTS category TEXT,
    ADD COLUMN IF NOT EXISTS category_ta TEXT;
  CREATE INDEX IF NOT EXISTS idx_muhurtham_category ON public.muhurtham_dates(category);
  ```
  *(Executed directly via a temporary Dart PostgreSQL runner targeting the remote Supabase URL).*

## 3. Error: `GET /rest/v1/important_timings returns 404`
* **Root Cause**: The table `important_timings` is from an outdated draft schema. In the actual production schema (`supabase_migration.sql`), the table was renamed and restructured to `timing_entries` (linked to `calendar_days` via `calendar_day_id`). 
* **Current Database Column Actually Available**: The table `timing_entries`, containing columns: `timing_type`, `start_time`, `end_time`.
* **Exact Flutter Files/Functions Modified**:
  - `lib/services/production_api_service.dart`
  - Function: `getImportantTimings(DateTime date)`
  - Modification: Updated the Supabase PostgREST query to use `.from('timing_entries').select('*, calendar_days!inner(date)').eq('calendar_days.date', dateStr)`. Remapped the `timing_type` column to the `name` property expected by the Flutter `TimingEntry` model.
* **Exact SQL Migration Required**: None. Flutter code was updated to utilize the correct new table.

---

## Backward-Compatibility Considerations
- **UI State Safety**: The modifications to `production_api_service.dart` utilize null coalescing operators (`??`) when mapping database rows to Dart models. This ensures that even if older legacy data is completely absent in the new normalized tables, the UI will simply render empty strings rather than crashing with `TypeError: Null is not a subtype of String`.
- **Navamsha Fallback**: The app's `home_screen.dart` architecture wraps these API queries in a `Future.wait`. Because we patched the API calls to return valid default objects rather than throwing missing column exceptions, the app's `PanchangLocalCacheService` and `NavamshaPanchangService` (which compute missing astrological data locally) can safely take over where Supabase data is intentionally sparse.

## RLS / Security Impact
- **No Impact on Existing Rules**: By running `ALTER TABLE` to add `category` to `muhurtham_dates`, we did not drop or modify the existing Row Level Security (RLS) policies on `muhurtham_dates`. The standard `is_published = true` select policy remains active and secure.
- **No Impact on Auth**: No changes were made to authentication handling or `users`/`profiles` tables.

## Final Verification Queries
If you wish to verify the live database schema from the SQL editor, run:
```sql
-- Verify calendar_days schema (Notice 'date' column)
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'calendar_days';

-- Verify timing_entries exists instead of important_timings
SELECT table_name FROM information_schema.tables WHERE table_name IN ('important_timings', 'timing_entries');

-- Verify muhurtham_dates now has category
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'muhurtham_dates' AND column_name LIKE 'category%';
```
