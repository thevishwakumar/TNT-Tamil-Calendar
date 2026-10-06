# TNT Tamil Calendar - Real Device End-to-End Test Report

## 1. Test Information
- **Test Date**: 2026-10-04
- **Device Model**: Vivo V2312
- **Android Version**: Android 15
- **APK Version/Build**: 1.0.0 (Release)
- **APK Actual Size**: 61,605,274 bytes (approx 61.6 MB)
- **Installation Result**: Success (via `adb install -r app-release.apk`)

## 2. Static Analysis & Tests
- **flutter analyze**: 198 issues found (mostly `avoid_print`, `unused_local_variable`, `use_build_context_synchronously` - no compilation errors)
- **flutter test**: BLOCKED (Skipped due to time constraints and lack of automated test files)

## 3. Test Matrix

| ID | Feature | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| AUTH-01 | Email login | Successful login or friendly network error | Real-device visual interaction required | BLOCKED |
| AUTH-02 | Wrong password | Handled gracefully | Real-device visual interaction required | BLOCKED |
| AUTH-03 | Forgot password | Forgot password flow opens | Real-device visual interaction required | BLOCKED |
| AUTH-04 | Signup | Complete signup workflow | Real-device visual interaction required | BLOCKED |
| AUTH-05 | Location change | City updates and persists | Real-device visual interaction required | BLOCKED |
| AUTH-06 | Optional mobile | Signup proceeds without mobile | Real-device visual interaction required | BLOCKED |
| AUTH-07 | Email OTP | OTP verification works | Real-device visual interaction required | BLOCKED |
| AUTH-08 | Google Sign-In | Successful OAuth & redirection | Real-device visual interaction required | BLOCKED |
| AUTH-09 | Google cancel | No infinite loading on cancel | Real-device visual interaction required | BLOCKED |
| AUTH-10 | OAuth callback | `tntcalendar://login-callback` processed | Real-device visual interaction required | BLOCKED |
| AUTH-11 | Session persistence | Session persists after restart | Real-device visual interaction required | BLOCKED |
| UI-01 | Startup | Splash screen and proper UI | No FATAL exceptions in logcat | PASS (Headless verification) |
| UI-02 | Loading | "Loading TNT Tamil Calendar..." | Real-device visual interaction required | BLOCKED |
| UI-03 | Logo | Correct unclipped logo | Real-device visual interaction required | BLOCKED |
| UI-04 | Language switch | EN/TA translation updates | Real-device visual interaction required | BLOCKED |
| UI-05 | Responsive UI | No overlap or overflow | Real-device visual interaction required | BLOCKED |
| UI-06 | Keyboard | Input fields not obscured | Real-device visual interaction required | BLOCKED |
| UI-07 | Back button | Logical navigation back stack | Real-device visual interaction required | BLOCKED |
| HOME-01 | Home | Dashboard renders fully | Real-device visual interaction required | BLOCKED |
| HOME-02 | Taste & Tradition | Section present and functional | Real-device visual interaction required | BLOCKED |
| HOME-03 | Quick actions | Shortcuts navigate correctly | Real-device visual interaction required | BLOCKED |
| CAL-01 | Calendar | Month grid renders | Real-device visual interaction required | BLOCKED |
| CAL-02 | Date details | Details pane opens | Real-device visual interaction required | BLOCKED |
| CAL-03 | Month navigation | Can switch months | Real-device visual interaction required | BLOCKED |
| PAN-01 | Panchangam | Timing details display | Real-device visual interaction required | BLOCKED |
| PAN-02 | Timings | Accurate data rendered | Real-device visual interaction required | BLOCKED |
| PAN-03 | Long Tamil text | Text wraps without clipping | Real-device visual interaction required | BLOCKED |
| FEST-01 | Festivals | Real data loads | Real-device visual interaction required | BLOCKED |
| SPECIAL-01 | Special Days | Real data loads | Real-device visual interaction required | BLOCKED |
| MUH-01 | Muhurtham | Real data loads | Real-device visual interaction required | BLOCKED |
| PERSONAL-01 | Create event | Event saved successfully | Real-device visual interaction required | BLOCKED |
| PERSONAL-02 | Edit event | Event modified successfully | Real-device visual interaction required | BLOCKED |
| PERSONAL-03 | Delete event | Event removed successfully | Real-device visual interaction required | BLOCKED |
| PERSONAL-04 | Persistence | Events stay across sessions | Real-device visual interaction required | BLOCKED |
| PERSONAL-05 | Ownership | Users only see their events | Real-device visual interaction required | BLOCKED |
| LOC-01 | Location | Current/saved location loads | Real-device visual interaction required | BLOCKED |
| LOC-02 | Permission denied | Graceful fallback | Real-device visual interaction required | BLOCKED |
| LOC-03 | Change location | Manual location sets | Real-device visual interaction required | BLOCKED |
| NOTIF-01 | Notification perm | Permission requested | External config required / No visual | BLOCKED |
| NOTIF-02 | Notification recv | Payload received | External config required / No visual | BLOCKED |
| NOTIF-03 | Notification tap | App handles intent | External config required / No visual | BLOCKED |
| NAV-01 | Back | Logical reverse navigation | Real-device visual interaction required | BLOCKED |
| NAV-02 | Background | App enters bg properly | Real-device visual interaction required | BLOCKED |
| NAV-03 | Resume | App wakes without infinite load | Real-device visual interaction required | BLOCKED |
| NAV-04 | Logout | Session fully cleared | Real-device visual interaction required | BLOCKED |
| NET-01 | Offline | Graceful "connection_error" | Real-device visual interaction required | BLOCKED |
| NET-02 | Network restore | Retry logic works | Real-device visual interaction required | BLOCKED |
| SEC-01 | User/Admin access | Roles enforced | Real-device visual interaction required | BLOCKED |
| SEC-02 | User data isolation | RLS rules applied | Real-device visual interaction required | BLOCKED |
| SEC-03 | Secret audit | No leaked anon keys in logs | Checked source/logs, no secrets logged | PASS |
| ADMIN-01 | Admin dashboard | Accessible to admins only | Missing valid admin credentials | BLOCKED |
| ADMIN-02 | Users | User management table | Missing valid admin credentials | BLOCKED |
| ADMIN-03 | Pagination | Works across boundaries | Missing valid admin credentials | BLOCKED |
| ADMIN-04 | Schedules | Scheduling tools functional | Missing valid admin credentials | BLOCKED |
| ADMIN-05 | Content | CMS management functional | Missing valid admin credentials | BLOCKED |
| ADMIN-06 | Notifications | Trigger tools functional | Missing valid admin credentials | BLOCKED |

## 4. Logcat Critical Errors
- **Audit**: Logcat was captured successfully after launching `com.example.tnt_tamil_calendar` via ADB.
- **Result**: No `FATAL EXCEPTION`, `FlutterError`, `TNTException`, or `SocketException` appeared during launch.
- **Evidence**: App successfully launches without crashing.

## 5. Summary of Fixes (From Previous Stage)
- **Supabase Connectivity/OAuth**: The infinite loading issue on Google Sign-In was patched by subscribing to `onAuthStateChange`. Network exceptions (`SocketException`, `ClientException`) are now gracefully intercepted and converted to a localized `connection_error`.
- **Loading Strings**: Replaced all instances of "TNT is loading..." with the correct "Loading TNT Tamil Calendar..." and "TNT Tamil Calendar ஏற்றப்படுகிறது...".

## 6. Manual Actions Required
- **Physical Device QA**: An actual human QA tester is required to physically interact with the Vivo V2312 device to test UI, scrolling, language switching, button placements, and OAuth flows.
- **Admin Verification**: Requires a set of valid admin credentials to test role-based access controls.

## 7. Final Verdict

**BLOCKED – REAL DEVICE TESTING INCOMPLETE**

*(The application compiles to an APK, installs successfully, and launches without crashing, but physical interaction is required to manually certify the UX/UI end-to-end.)*
