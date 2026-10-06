# TNT Integration Map

## 1. Authentication Flow (Email OTP)
1. **UI entry point**: `auth/screens/login_screen.dart`
2. **Input parameters**: Email address
3. **Client-side validation**: Format checking in UI layer
4. **Repository method**: `signInWithOtp` via `auth_state_manager.dart`
5. **Service method**: `SupabaseService.signIn`
6. **Supabase table/endpoint**: Supabase Auth `/otp` endpoint & `profiles` table (via trigger)
7. **Authentication requirements**: Unauthenticated allowed to request OTP.
8. **RLS policy**: `profiles` restricted to self. Trigger `handle_new_user` handles creation.
9. **Database operation**: Insert into `profiles` and `user_preferences`.
10. **Expected response**: Auth Session object.
11. **Model parsing**: Supabase User object to local auth state.
12. **State update**: `AuthStateManager` updates to `authenticatedUser`.
13. **UI rendering**: Routes to `TNTMainContainer` -> `HomeScreen`.
14. **Error and retry behavior**: UI displays errors. Retry allowed.
15. **Test evidence**: Unit tested in `authorization_and_security_test.dart` (Status: RUNNING). Live E2E: BLOCKED (No Supabase Staging credentials).

## 2. Panchangam Flow
1. **UI entry point**: `panchangam/screens/panchangam_screen.dart`
2. **Input parameters**: Selected Date, Location
3. **Client-side validation**: Date must be valid.
4. **Repository method**: `PanchangamRepository.fetchPanchangam`
5. **Service method**: `PanchangLocalCacheService` / `SupabaseService`
6. **Supabase table**: `panchangam_entries`, `calendar_days`
7. **Authentication requirements**: Optional / authenticated
8. **RLS policy**: `panchangam_entries_select_policy` (TO authenticated, anon USING true)
9. **Database operation**: SELECT from `panchangam_entries`
10. **Expected response**: JSON with Tithi, Nakshatra, Yoga, Karana
11. **Model parsing**: `PanchangamBundle.fromJson`
12. **State update**: UI state rebuilt with data.
13. **UI rendering**: Cards displayed for timings.
14. **Error and retry behavior**: Local cache fallback.
15. **Test evidence**: E2E BLOCKED.

## 3. Muhurtham Fetch Flow
1. **UI entry point**: `muhurtham/screens/muhurtham_screen.dart`
2. **Input parameters**: Month/Year
3. **Client-side validation**: None specific.
4. **Repository method**: Fetch muhurtham dates
5. **Service method**: `SupabaseService`
6. **Supabase table**: `muhurtham_dates`, `muhurtham_timings`
7. **Authentication requirements**: None/Auth
8. **RLS policy**: SELECT USING `is_published = true OR public.is_admin()`
9. **Database operation**: SELECT
10. **Expected response**: List of dates.
11. **Model parsing**: `MuhurthamDate` model.
12. **State update**: StateProvider or setState.
13. **UI rendering**: List of dates rendered.
14. **Error and retry behavior**: Retry on network failure.
15. **Test evidence**: E2E BLOCKED.

## 4. Admin Dashboard
1. **UI entry point**: `admin/screens/admin_dashboard.dart`
2. **Input parameters**: Admin navigation tabs
3. **Client-side validation**: None.
4. **Repository method**: Admin repository methods.
5. **Service method**: `SupabaseService`
6. **Supabase table**: All tables.
7. **Authentication requirements**: JWT role = 'ADMIN'
8. **RLS policy**: `is_admin()` function checks profiles table.
9. **Database operation**: CRUD operations.
10. **Expected response**: Data lists or Success bools.
11. **Model parsing**: Admin models.
12. **State update**: UI rebuilt.
13. **UI rendering**: Admin forms and lists.
14. **Error and retry behavior**: Alerts on failure.
15. **Test evidence**: E2E BLOCKED.
