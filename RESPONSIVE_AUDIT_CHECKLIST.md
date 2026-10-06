# TNT Complete Responsive Audit Checklist

## Phase 1 - Page-by-Page Audit

### Global / Shared
- [ ] **Scaffolds**: Most screens use `Scaffold` directly. Needs a constrained max-width wrapper (like `TNTResponsiveScaffold`) for Tablet/Desktop support so UI doesn't stretch to infinity.
- [ ] **Modals & Dialogs**: Check `location_selector_modal.dart`, `tnt_reminder_dialog.dart`, etc., to ensure they have constrained widths and don't take up the full screen on tablets.

### Home / Dashboard (`lib/home/screens/home_screen.dart`)
- [ ] **Quick Actions Grid**: `GridView.count` is hardcoded to `crossAxisCount: 4`. On narrow devices (320px) this can clip text. On desktop it leaves too much empty space.
- [ ] **Upcoming Cards**: Ensure they are wrapped correctly and don't overflow on small devices.

### Auth (`lib/auth/screens/`)
- [ ] **Forms**: Ensure `login_screen.dart`, `signup_screen.dart`, etc., use `SafeArea` and bounded constraints so inputs are not full width on desktops.
- [ ] **Keyboard Insets**: Ensure `SingleChildScrollView` is used so that the keyboard doesn't hide the submit buttons.

### Calendar (`lib/calendar/screens/`)
- [ ] **Calendar Grid**: Needs to handle narrow text fitting.
- [ ] **Date Details**: Check for hardcoded spacing that might cause overflow.

### Admin Features (`lib/features/admin/`)
- [ ] **Users Table**: `admin_users_screen.dart` has list items that could overflow horizontally if too much data is placed on a row.
- [ ] **Analytics**: `admin_analytics_screen.dart` check for graphs or charts that aren't responsive.
- [ ] **Campaign Create**: `admin_campaign_create_screen.dart` ensure input forms are scrollable.

### Panchangam / Muhurtham / Festivals
- [ ] **Long Tamil Text**: Needs to wrap correctly. Check `panchangam_screen.dart` and `muhurtham_screen.dart` for unbounded rows without `Expanded`.

### Personal Calendar
- [ ] **Month / Day Selector**: `personal_calendar_screen.dart` uses `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` which is generally safe, but should be tested.

## Phase 2 & 3 - Responsive Strategy & Phone Layout
- Implement `ResponsiveLayout` with breakpoints (Mobile < 600, Tablet < 1024, Desktop >= 1024).
- Create `TNTResponsiveScaffold` to wrap the `body` in a `SafeArea` and `ConstrainedBox(maxWidth: 800)`.
- Apply `TNTResponsiveScaffold` to major screens.
- Use `LayoutBuilder` or `ResponsiveLayout.isMobile(context)` for adaptive column counts in GridViews.

## Phase 4 & 5 - Applying Fixes
- Iterate through screens and apply `TNTResponsiveScaffold` where appropriate.
- Fix any identified bounded boxes, dialog constraints, and typography overflows.
