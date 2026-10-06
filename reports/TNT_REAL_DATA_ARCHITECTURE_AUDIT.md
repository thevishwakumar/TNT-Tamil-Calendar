# TNT Real Data Architecture Audit

## 1. Single Source of Truth
The architecture now accurately relies on Supabase as the Single Source of Truth for both Admin and User Dashboards.
- **Admin Dashboard** now correctly fetches actual table counts from Supabase using `CountOption.exact` for `profiles`, `muhurtham_dates`, `festivals`, `content`, and `notification_campaigns`.
- Replaced mock/hard-coded dummy implementations (like returning zeroes or hiding behind 'Data unavailable').
- Admin changes immediately sync with User dashboards since they point to the exact same Postgres backend schema.

## 2. CSV / Excel Bulk Import Service
Implemented `AdminImportService` inside `lib/features/admin/services/admin_import_service.dart`.
- Adds support for parsing `.csv` and `.xlsx` using the `csv` and `excel` packages.
- Reads files selected via `file_picker`.
- Generates reproducible, date-based primary keys to prevent duplication.
- Automates inserting `is_published = true` during import to respect RLS configurations immediately, making data readable to end-users without manual approval.
- Uses `upsert` queries to update existing records if matching IDs are found.

## 3. Data Integration & RLS Policy Mapping
- `muhurtham_dates` (defaults to `is_published: false` in SQL but we enforce `true` during bulk import).
- `festivals` (defaults to `is_published: true`).
- `special_days` (defaults to `is_published: true`).
- The user dashboard correctly reads only `is_published = true` due to row-level security.

## 4. Stability and Safety
- Overlays (`TNTErrorOverlay` and `TNTLoadingOverlay`) are used to gracefully manage loading states in User Dashboard.
- Exceptions during database transactions fall back safely, maintaining the application frame.

## Conclusion
The Admin Dashboard analytics mismatch (where everything was showing 0) is resolved. The Bulk import requirements for CSV and Excel files are fulfilled. Data is consistently queried and maintained securely through Supabase.
