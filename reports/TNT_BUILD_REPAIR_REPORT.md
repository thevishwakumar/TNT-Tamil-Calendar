# TNT Android Build Repair Report

## Diagnosis
The build originally failed with the following issues:
1. Missing Android NDK version `28.2.13676358`.
2. Incompatible dependencies due to `compileSdkVersion` set to `34`.
3. Outdated `share_plus` plugin which enforced `compileSdk` to `33` overriding transitive dependencies.

## Fixes Implemented
1. **NDK Installation:** Manually installed NDK `28.2.13676358` via Android `sdkmanager`.
2. **SDK Version Override:** Modified `android/app/build.gradle.kts` to explicitly set `compileSdk = 36` to satisfy dependencies requiring newer Android APIs (such as `app_links`, `url_launcher_android`).
3. **Plugin Upgrade:** Upgraded `share_plus` from `7.2.2` to `13.3.0` using `flutter pub add share_plus` to resolve the KGP warning and its old hardcoded `compileSdk = 33` constraint.

## Verification
- Cleaned the build using `flutter clean`.
- Resolved dependencies using `flutter pub get`.
- Executed `flutter build apk --debug` successfully.
- Verified the generated artifact at: `C:\Users\Vishw\Downloads\TNT\build\app\outputs\flutter-apk\app-debug.apk`.
