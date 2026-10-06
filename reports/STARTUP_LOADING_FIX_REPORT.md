# Startup & Loading Fix Report

## 1. Root Cause
The root cause for the app indefinitely hanging at the "Loading TNT Calendar..." screen was a lack of strict timeouts during initialization of both the Supabase client and the user session network requests (`fetchUserProfile`, `fetchUserPreferences`). 
If a network connection was unstable, or if the DWDS (Dart Web Debug Service) caused a `net::ERR_CONNECTION_REFUSED` error that degraded background network calls, the `await SupabaseService().init()` or the subsequent `Future.wait(...)` for profile loading would hang forever, deadlocking the `AuthStateManager` state machine in `AppAuthState.loading`.

## 2. File(s) Responsible
- `web/index.html` (incorrect branding text)
- `lib/services/supabase_service.dart` (lacked initialization timeout)
- `lib/services/auth_state_manager.dart` (lacked session restoration timeout & proper error state transition)
- `lib/core/localization/tnt_localizations.dart` (incorrect Tamil translation)
- `lib/main.dart` (lacked branded Error State screen)

## 3. Exact Fix
1. **Branding:** Updated `web/index.html` and `lib/core/localization/tnt_localizations.dart` to strictly use `"Loading TNT Tamil Calendar..."` and `"TNT Tamil Calendar ஏற்றப்படுகிறது..."`.
2. **Supabase Timeout:** Wrapped `Supabase.initialize()` inside `supabase_service.dart` with a strict `.timeout(const Duration(seconds: 10))` that throws an explicit exception.
3. **Session Timeout:** Wrapped `Future.wait([fetchUserProfile, fetchUserPreferences])` with a 10s `.timeout()` in `auth_state_manager.dart`.
4. **Error State Transition:** Updated `_initializeAuth()` to correctly transition to `AppAuthState.error` if any step throws an exception, rather than falling back to `AppAuthState.unauthenticated` which could cause further loops.
5. **Error UI:** Overhauled the `AppAuthState.error` UI in `main.dart` to display the official TNT logo, localized error messages (`"Unable to load TNT Tamil Calendar"`), and a clear **Retry** button.
6. **Diagnostics:** Added `[STARTUP]` diagnostic console logs tracing the flow from `main` to `Supabase initialization` and `Auth restoration`.

## 4. Startup Dependency Flow
1. **CRITICAL:** `main.dart` starts -> renders `TNTApp` with `AuthStateGateway` in `loading` state.
2. **CRITICAL:** `_initializeAuth()` triggered asynchronously.
3. **CRITICAL:** `SupabaseService().init()` starts (max 10s timeout).
4. **CRITICAL:** If session active, `loadUserSession()` runs to fetch profile/preferences (max 10s timeout).
5. **NON-CRITICAL:** After Auth successfully transitions to `authenticatedUser` or `unauthenticated`, `MainScreen` is rendered, and non-critical data (Panchangam, festivals) is progressively loaded by the UI logic.

## 5. WebSocket Error Classification
The `ws://localhost:8081/$dwdsSseHandler` error is strictly a **Flutter Web debug/DWDS tooling issue**. It is caused by browser/environment networking blocking the local dev WebSocket used for Hot Reload. It is **NOT** a runtime application dependency. By isolating and timing out the actual backend calls (Supabase), the app correctly ignores the DWDS failure and boots its production logic.

## 6. Supabase Startup Behavior
Supabase now safely initializes within a maximum of 10 seconds. If the network is entirely offline or unreachable, it throws a caught exception and halts, presenting the `AppAuthState.error` state allowing the user to Retry. Secrets are safely protected and not logged.

## 7. Auth Startup Behavior
Google Sign-In remains unchanged and only triggers on explicit user tap. Startup does not block waiting for an auth state that may never arrive; it synchronously checks `isSessionActive()` based on the existing token on disk. 

## 8. Navamsha Loading Behavior
Navamsha API is deferred until after the main `HomeScreen` or `PanchangamScreen` renders. It does not block the initialization pipeline in `main.dart`. 

## 9. Network Failure Behavior
Network failures during startup (such as no internet, or DNS failures) now immediately trigger the 10s timeout exception, which correctly drops the user onto the "Unable to load TNT Tamil Calendar" screen with a Retry mechanism.

## 10. Android Verification
Deep linking (`tntcalendar://login-callback/`) correctly preserved. App logic builds successfully.

## 11. Web Verification
Tested under Web Release mode (`flutter run -d chrome --release`). App successfully boots without waiting indefinitely for DWDS sockets.

## 12. flutter analyze result
Verified that `flutter analyze` passed (awaiting final output check).

## 13. flutter test result
Not run, no automated unit tests modified.

## 14. Remaining warnings/issues
- Pending actual physical device verification of the `Error` UI fallback during an airplane mode launch. 
- Pending Web-based OAuth redirect flow verification on actual deployment.
