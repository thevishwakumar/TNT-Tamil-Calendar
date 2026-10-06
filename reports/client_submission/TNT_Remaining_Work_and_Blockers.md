# TNT Remaining Work and Blockers

## Critical
- **Missing SMS OTP Provider**: The SupabaseEdgeFunctionSmsOtpProvider needs to be fully implemented and verified for production use.
- **Visual Capture Limitations**: End-to-End screenshot captures require a physical device or a headed emulator/browser environment to succeed.

## High
- **Responsive UI Audit**: Remaining screens (Festivals, Auth forms, Admin panels) need to be migrated to `TNTResponsiveScaffold` to prevent layout overflow on narrow mobile screens.
- **Security Key Review**: Validate that the Supabase `service-role` key is strictly isolated to Edge Functions and not bundled in the Flutter client.

## Medium
- **Analyzer Warnings**: Clean up the 138 remaining `flutter analyze` warnings and infos (e.g., `avoid_print`, `library_private_types_in_public_api`) to ensure long-term code health.

## Low
- **Notifications UI**: Polish the notification campaigns screen for admin users.
