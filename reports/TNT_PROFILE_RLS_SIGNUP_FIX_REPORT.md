# TNT — FINAL PROFILE RLS SIGNUP FIX REPORT

## 1. Root Cause Analysis
During the Create Account flow, a 42501 (Forbidden) RLS violation error was occurring when the app tried to upsert a profile immediately after calling signUp(). 
Upon inspecting the SQL migrations and schema, I discovered:
* public.profiles does **not** have an INSERT policy. It only has policies for SELECT and UPDATE (uth.uid() = id).
* The system is designed to use a SECURITY DEFINER database trigger (on_auth_user_created) to automatically insert a user's initial profile into public.profiles the moment they are added to uth.users.
* Because upsertUserProfile was using Supabase's .upsert() method (which logically acts as an INSERT ... ON CONFLICT DO UPDATE), PostgreSQL evaluated whether the authenticated role had INSERT privileges. 
* Since the mobile client only has UPDATE permissions, the INSERT check failed immediately, throwing the 42501 error before even attempting the update.

## 2. Implemented Fix
As requested, I did **not** weaken the security by adding an INSERT policy to public.profiles. The database trigger architecture was fully preserved.
Instead, I updated the client-side logic to respect this architecture:
* **File Modified**: lib/repositories/tnt_repositories.dart
* **Change**: Replaced the .upsert(profile.toJson()) call in upsertUserProfile with .update(profile.toJson()).eq('id', profile.id).
* **Why it works**: Because the DB trigger has already guaranteed the row's existence, the client only needs to perform an UPDATE. The .update() explicitly skips the INSERT permission check and relies exclusively on the existing profiles_update_policy (USING (auth.uid() = id)), which succeeds securely.

## 3. Security Validation
- **Anonymous Users**: Cannot update profiles because their uth.uid() is null.
- **Authenticated User A**: Can only update their own profile because the policy enforces uth.uid() = id. User A cannot modify User B.
- **Trigger Integrity**: on_auth_user_created still controls the initial profile insertion natively at the database level.
- **Guest Field**: isGuest remains local to the Flutter state and is successfully omitted from UserProfile.toJson().

## 4. Test Results
- lutter analyze: Passed with 0 errors (only existing info/warnings).
- lutter build apk --debug: Compilation successfully triggered and building in the background.

## 5. Live Verification
**Status: BLOCKED (Awaiting Device Testing)**
I am unable to test this on the Vivo V2312 device or verify against the live database directly. You must install the generated APK on the physical Android 15 device and run through the exact signup flow:
* Create Account -> Step 1 -> Email OTP -> Step 2 Location & Terms -> Sign Up & Continue.
* The expected result is that the profile is saved securely without throwing PROFILE_UPSERT_FAILED or RLS 42501, and you successfully progress to the next screen.
