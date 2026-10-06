# Permission & Privacy Audit Report
**App:** TNT Tamil Calendar
**Date:** 2026-10-04
**Status:** ⚠️ PENDING REAL DEVICE EXECUTION

## 1. Location Permission
- **Feature requiring it:** Accurate Panchangam, sunrise/sunset, location-based events.
- **Where requested:** Via `PermissionService` when explicitly requested by user (e.g., Privacy & Permissions settings).
- **Android permission:** `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`
- **iOS permission:** N/A (App does not currently build for iOS, Info.plist omitted).
- **User explanation:** "Allow location access to provide accurate Panchangam, timings and location-based calendar information for your area."
- **Denied behavior:** App functions normally with manual location selection fallback.
- **Permanently denied behavior:** Shows dialog directing user to App Settings.
- **Data handling:** Location is not continuously tracked or permanently stored; used only for localized API requests.
- **Status:** PENDING QA

## 2. Notification Permission
- **Feature requiring it:** Festival updates, calendar reminders, important announcements.
- **Where requested:** Via `PermissionService` when explicitly requested.
- **Android permission:** `POST_NOTIFICATIONS`
- **iOS permission:** N/A.
- **User explanation:** "Allow notifications to receive festival updates, calendar reminders and important announcements."
- **Denied behavior:** Notifications will not be received. App functionality remains intact.
- **Permanently denied behavior:** Shows dialog directing user to App Settings.
- **Data handling:** Notification tokens used strictly for routing messages.
- **Status:** PENDING QA

## 3. General Privacy Guidelines Checked
- **Camera/Microphone/Contacts/SMS:** None of these permissions are requested in AndroidManifest.xml or codebase. The app strictly follows the "Minimum Permission Required" principle.
- **Location Default:** No hardcoded city is forcibly used if location is denied; manual selection is used.
- **Auth:** Email OTP does not request SMS reading permissions.
- **API Keys:** No API keys exposed; backend Navamsha fetching uses edge function secrets.
- **Settings:** A new `Privacy & Permissions` screen has been added to give the user visibility and control over Location and Notification permissions.

## Acceptance Criteria Checklist (Pre-QA)
✓ No unnecessary permissions are requested.
✓ No permission popup appears on first launch without a real need.
✓ Location is requested contextually.
✓ Denied permissions do not crash or block the app.
✓ Permanently denied permissions provide Settings guidance.
✓ Privacy/permission status is visible to the user.
✓ Android Manifest contains only required permissions.
✓ Navamsha API security is preserved.
