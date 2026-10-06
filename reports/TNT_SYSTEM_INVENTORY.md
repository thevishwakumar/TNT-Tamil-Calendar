# TNT System Inventory

## Modules and Features

### 1. Authentication
* **Feature name:** Authentication (Login, Signup, Forgot Password, Profile)
* **Screen or route:** `auth/screens/login_screen.dart`, `auth/screens/signup_screen.dart`, `auth/screens/forgot_password_screen.dart`, `auth/screens/profile_screen.dart`
* **Models:** Handled through Supabase auth state (`services/auth_state_manager.dart`)
* **Repository/Service:** `services/supabase_service.dart`, `features/auth/domain/*`
* **Backend:** Supabase Auth (Email OTP/Mobile OTP)
* **Verification method:** E2E UI testing and Unit Tests

### 2. Home Dashboard
* **Feature name:** Home Dashboard
* **Screen or route:** `home/screens/home_screen.dart`
* **Main widgets:** `TNTMainContainer` in `main.dart`
* **Backend endpoint or Supabase operation:** Fetching today's data from `supabase_service.dart`

### 3. Calendar
* **Feature name:** Calendar view and Date Details
* **Screen or route:** `calendar/screens/calendar_screen.dart`, `calendar/screens/date_details_screen.dart`
* **Repository:** `features/admin/calendar_management/` (Admin), `services/supabase_service.dart` (User)

### 4. Panchangam
* **Feature name:** Panchangam details, Navamsha, local cache
* **Screen or route:** `panchangam/screens/panchangam_screen.dart`
* **Repository:** `panchangam/repositories/panchangam_repository.dart`, `services/panchang_local_cache_service.dart`
* **Database tables:** `panchangam_entries` etc.

### 5. Muhurtham
* **Feature name:** Muhurtham Dates & Details
* **Screen or route:** `muhurtham/screens/muhurtham_screen.dart`, `muhurtham/screens/muhurtham_detail_screen.dart`
* **Backend:** Fetch from Supabase tables `muhurtham_dates`, `muhurtham_timings`

### 6. Special Days & Festivals
* **Feature name:** Special Days & Festivals Listings
* **Screen or route:** `special_days/screens/special_days_screen.dart`, `festivals/screens/festivals_screen.dart`
* **Database tables:** `special_days`, `festivals`

### 7. Reminders & Saved Items
* **Feature name:** User Reminders and Saved Items
* **Screen or route:** `reminders/screens/reminders_screen.dart`, `saved/screens/saved_items_screen.dart`
* **Service:** `services/reminder_service.dart`, `services/saved_items_service.dart`
* **Database tables:** `user_reminders`, `user_saved_items`

### 8. Notifications
* **Feature name:** Notifications and Settings
* **Screen or route:** `notifications/screens/notifications_screen.dart`, `notifications/screens/notification_settings_screen.dart`
* **Service:** `services/notification_service.dart`
* **Database tables:** `notification_campaigns`, `notification_logs`

### 9. Admin Dashboard
* **Feature name:** Admin operations (Content, Analytics, Users, Bulk Import)
* **Screen or route:** `admin/screens/admin_dashboard.dart`, `features/admin/*`
* **Authentication/Authorization:** Admin role required (`core/authorization/admin_route_guard.dart`)
* **Database operations:** CRUD on various tables

### 10. Jathagam
* **Feature name:** Horoscope/Jathagam
* **Screen or route:** `jathagam/screens/jathagam_screen.dart`
* **Models:** `jathagam/models/horoscope_model.dart`
* **Service:** `jathagam/services/horoscope_service.dart`

### Known defects / Implementation status
- Full analysis pending `flutter analyze` and `flutter test` execution.
- Will inspect exact DB tables and backend dependencies after Supabase schema discovery.
