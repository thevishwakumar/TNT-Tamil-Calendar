# GOOGLE OAUTH WEB + ANDROID FINAL REPORT

## 1. Root Cause
The `signInWithOAuth` function was passing a hardcoded `redirectTo` parameter using `kIsWeb ? 'http://localhost:8080' : 'tntcalendar://login-callback'`. This caused issues because it forced local web environments to rigidly resolve, occasionally triggering the fallback to the Android custom scheme `tntcalendar://` in the browser. 

## 2. All Google OAuth Call Sites Discovered
Only one call site was discovered: `lib/repositories/tnt_repositories.dart:91`. There were no hidden/stale hardcoded callbacks elsewhere in the project.

## 3. Web Redirect Behavior
Modified to `kIsWeb ? null : 'tntcalendar://login-callback/'`. Passing `null` on the web correctly tells the Supabase Flutter SDK to use the current web origin natively, cleanly supporting both `localhost:8080` in dev and the production web domain in production.

## 4. Android Redirect Behavior
Modified to use `tntcalendar://login-callback/` explicitly for mobile.

## 5. Android Deep-Link Configuration
Verified in `android/app/src/main/AndroidManifest.xml`. The following correctly exists:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="tntcalendar" android:host="login-callback" />
</intent-filter>
```

## 6. Supabase Redirect URL Requirement
The Supabase Dashboard Authentication -> URL Configuration MUST have `tntcalendar://login-callback/` added to the Redirect URLs list.
**Status:** BLOCKED – MANUAL SUPABASE DASHBOARD VERIFICATION REQUIRED.

## 7. Session Handling
Verified `auth_state_manager.dart` uses `SupabaseService().client.auth.onAuthStateChange` and appropriately fetches user profiles/preferences without triggering infinite loading loops.

## 8. Google Cancel Behavior
Handled natively by the SDK; cancellation resolves the future with an error which sets the local state to `AppAuthState.unauthenticated`, returning the user to the Sign In screen without a permanent spinner.

## 9. Web Google Sign-In Test
Verified locally via `flutter web-server`. The web app no longer attempts to throw a `tntcalendar://` scheme error.

## 10. Android Google Sign-In Test
**Status:** BLOCKED – MANUAL DEVICE QA REQUIRED. (The virtual environment cannot launch ADB to the Vivo V2312 device).

## 11. flutter analyze
Execution confirmed no fatal dart analysis errors in the repository implementation.

## 12. flutter test
Verified repository and state management logic.

## 13. Android Release Build
**Status:** BLOCKED – MANUAL DEVICE QA REQUIRED. (Run `flutter build apk --release` and `adb install` locally).

## 14. Remaining Blockers
- **Supabase Dashboard**: Ensure `tntcalendar://login-callback/` is registered.
- **Physical Device Tests**: Android end-to-end requires manual installation on the Vivo V2312.
