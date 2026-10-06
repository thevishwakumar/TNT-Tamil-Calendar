# TNT Security Audit

## 1. Authentication Checks
- **Method**: Supabase Auth (Email OTP/Mobile OTP)
- **Status**: The `profiles` table requires users to be authenticated to select/update their own data. The `handle_new_user` trigger properly defaults new sign-ups to `USER` role.
- **Vulnerability**: No immediate vulnerability found in DB schema.

## 2. Authorization & RLS Checks
- **USER isolation**: `user_preferences`, `user_saved_items`, `user_reminders`, `user_devices`, `notification_logs`, `user_important_dates`, `user_personal_notes`, `user_saved_locations` all have RLS policies restricting access to `auth.uid() = user_id`.
- **ADMIN access**: Admin is verified through a `SECURITY DEFINER` function `is_admin()`, which prevents recursion and checks the `profiles` table. Admin has `FOR ALL USING (public.is_admin())` on all administrative tables.
- **Cross-user isolation tests**: **BLOCKED** due to lack of staging Supabase credentials. But RLS policies inspected in `supabase_migration.sql` seem correctly configured.

## 3. Secret-handling Findings
- Looked at `.env.example` and `.env.staging`. No sensitive keys or Service Role keys found in source code. `SUPABASE_ANON_KEY` is present as a placeholder, which is safe to be exposed on clients.

## 4. Storage Security
- `media_assets` table has RLS, but the exact Supabase Storage bucket policies are not present in the migration file. Storage RLS policies need independent verification.

## 5. API Security
- Row Level Security properly handles authorization on DB queries. Edge functions are not audited as they weren't discovered in the repository's main lib structure.

## 6. Unresolved Risks
- **Testing Limitation**: Live backend/E2E testing could not be completed, so we rely solely on static code analysis of the SQL schemas and Flutter repositories. Real world test requires actual DB.
