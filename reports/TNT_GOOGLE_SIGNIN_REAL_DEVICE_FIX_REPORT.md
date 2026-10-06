# TNT_GOOGLE_SIGNIN_REAL_DEVICE_FIX_REPORT.md

## 1. Exact root cause
When `AuthStateManager` received `SIGNED_IN` from Google OAuth, it attempted to call `loadUserSession()`. Inside this method, `ProfileRepository.upsertUserProfile()` was triggered to create a database profile for the newly authenticated Google user. 
However, `upsertUserProfile` was internally using `.update()` instead of `.upsert()`. In Supabase, `.update()` strictly targets existing rows and will not insert a new row. The failure to create a profile resulted in an exception being thrown during the session initialization, which `loadUserSession` caught silently, forcefully resetting the `_state` back to `AppAuthState.unauthenticated`. This caused the app to instantly drop the user back onto the Sign In page despite a successful Google OAuth handshake.

By fixing `upsertUserProfile` to actually use `.upsert()`, the profile is correctly created. I also added extensive debug logging directly to `AuthStateManager` so we can trace the exact event lifecycle (`SIGNED_IN`, `fetchUserProfile`, `upsertUserProfile`, state transitions) via `adb logcat` during your test.

## 2. OAuth flow before fix
Continue with Google → Google Account Picker → Deep link `tntcalendar://login-callback/` returned to app → `onAuthStateChange` fires `SIGNED_IN` → `loadUserSession` runs → Profile fails to create due to `.update` on non-existent row → Exception caught silently → `_state` reverts to `unauthenticated` → User permanently stuck on Sign In page.

## 3. OAuth flow after fix
Continue with Google → Google Account Picker → Deep link `tntcalendar://login-callback/` returned to app → `onAuthStateChange` fires `SIGNED_IN` → `loadUserSession` runs → `fetchUserProfile` returns null (new user) → `upsertUserProfile` creates new record using `.upsert()` → User preferences generated → `_state` successfully transitions to `authenticatedUser` → MainScreen/Home renders.

## 4. Files modified
- `lib/repositories/tnt_repositories.dart`: Changed `.update()` to `.upsert()` in `upsertUserProfile()`.
- `lib/services/auth_state_manager.dart`: Added detailed `print` logging for all Auth events, session variables, and state changes to make ADB debugging transparent.

## 5. AndroidManifest verification
- `android/app/src/main/AndroidManifest.xml` contains the correct deep-link intent filter: `<data android:scheme="tntcalendar" android:host="login-callback" />`
- **Status**: PASS

## 6. Redirect URI verification
- Dart code successfully passes `redirectTo: 'tntcalendar://login-callback'` for Android/iOS. 
- **Status**: PASS

## 7. Supabase configuration status
- **Status**: BLOCKED – Supabase Dashboard redirect configuration requires manual verification. Please log into Supabase > Authentication > URL Configuration > Redirect URLs and ensure `tntcalendar://login-callback/` is explicitly added.

## 8. Deep-link callback evidence
- **Status**: BLOCKED - Awaiting physical device test. ADB Logcat will now print `TNT Auth Event: signedIn` upon successful callback interception.

## 9. Supabase session evidence
- **Status**: BLOCKED - Awaiting physical device test. ADB Logcat will now print `Session exists: true`.

## 10. onAuthStateChange evidence
- **Status**: BLOCKED - Awaiting physical device test. ADB Logcat will print `TNT Auth: SIGNED_IN for user <id>`.

## 11. AuthStateManager evidence
- **Status**: BLOCKED - Awaiting physical device test. ADB Logcat will print `TNT Auth: Starting loadUserSession` followed by `Final state: AppAuthState.authenticatedUser`.

## 12. Navigation evidence
- **Status**: BLOCKED - Awaiting physical device test.

## 13. Profile creation evidence
- **Status**: BLOCKED - Awaiting physical device test. ADB Logcat will confirm `fetchUserProfile returned: false` followed by successful load.

## 14. Google cancel test
- **Status**: BLOCKED - Awaiting physical device test. 

## 15. Google success test
- **Status**: BLOCKED - Awaiting physical device test. 

## 16. App restart session persistence
- **Status**: BLOCKED - Awaiting physical device test. 

## 17. Background/resume test
- **Status**: BLOCKED - Awaiting physical device test. 

## 18. Logout test
- **Status**: BLOCKED - Awaiting physical device test. 

## 19. Language selector fix
- Confirmed that `login_screen.dart`, `signup_screen.dart`, and `auth_welcome_page.dart` contain proper `தமிழ்` string literals.
- **Status**: PASS

## 20. Loading text verification
- Confirmed that `tnt_localizations.dart` strictly uses `Loading TNT Tamil Calendar...` and `தமிழ் நாட்காட்டி ஏற்றப்படுகிறது...`.
- **Status**: PASS

## 21. flutter analyze
- **Status**: PASS (0 compilation errors)

## 22. flutter test
- **Status**: NOT TESTED 

## 23. release APK build
- Currently compiling `app-release.apk`.

## 24. remaining blocked items
- All manual real-device interactions on the Vivo V2312.
