# TNT Tamil Calendar — App Demonstration & Current Status Report

**Project:** `C:\Users\Vishw\Downloads\TNT`  
**Application Name:** TNT Tamil Calendar (தமிழ் காலண்டர்)  
**Document Version:** 2.0 (Client Submission)  
**Date:** October 2026  

---

## 1. Existing App Demonstration (தற்போதுள்ள திரைகள் & முடிக்கப்பட்ட அம்சங்கள்)

TNT Tamil Calendar is a production-grade Flutter mobile application backed by a scalable Supabase PostgreSQL cloud backend. Below is a comprehensive walkthrough of all completed screens, user workflows, and implemented features.

### Screen 1: Welcome & Onboarding (வரவேற்பு திரை)
* **Location:** `lib/features/auth/presentation/pages/auth_welcome_page.dart`
* **Features Implemented:**
  * **Branded Visual Experience:** Full-screen responsive layout featuring the official TNT logo and Tamil traditional golden theme.
  * **Bilingual Toggle (தமிழ் / English):** One-tap instant language switcher changing all UI labels dynamically.
  * **Guest Mode Entry ("உள்நுழையாமல் தொடரவும்" / Continue as Guest):** Allows users to explore calendar, festivals, and panchangam without mandatory account creation.
  * **Authentication Triggers:** Quick buttons to navigate to Sign In or Sign Up.

### Screen 2: Authentication & Security (பாதுகாப்பு & கணக்கு உள்நுழைவு)
* **Location:** `lib/auth/screens/login_screen.dart`, `lib/features/auth/presentation/pages/email_verification_page.dart`
* **Features Implemented:**
  * **Email & Password Authentication:** Secure session management via Supabase Auth.
  * **Google One-Tap Sign-In:** Integrated Google OAuth with custom deep linking (`tntcalendar://login-callback/`).
  * **6-Digit Email OTP Verification:** Custom SHA-256 hashed 6-digit OTP delivery via Supabase Edge Function with resend cooldown timer (anti-spam).
  * **Role-Based Routing:** Automatically checks server-side admin privileges (`is_admin()`) upon login and reveals the Admin Panel for authorized admins while routing standard users to the main dashboard.
  * **Session Isolation & Token Eviction:** Clear user tokens and reset session state on logout, preventing cross-account data leakage.

### Screen 3: Home Dashboard (முதன்மை முகப்புத் திரை)
* **Location:** `lib/home/screens/home_screen.dart`
* **Features Implemented:**
  * **Header Controls:** Real-time Gregorian date, Tamil date header, language toggle, and location picker (`Coimbatore`, `Chennai`, `Madurai`, `Tiruchirappalli`, `Salem`, etc.).
  * **Today's Date Card:** Large visual display of Gregorian day, month, year alongside Tamil Year (e.g., Krodhi - குரோதி வருடம்), Tamil Month, Tamil Date, Day of the Week (வாரம்), Thithi, and Nakshatra.
  * **Daily Auspicious & Inauspicious Glance:** Real-time calculated cards for:
    * **Sunrise & Sunset (சூரிய உதயம் / அஸ்தமனம்)**
    * **Nalla Neram (நல்ல நேரம் - காலை & மாலை)**
    * **Rahu Kalam (இராகு காலம்)**
    * **Yamagandam (எமகண்டம்)**
    * **Kuligai / Gulika Kalam (குளிகை)**
  * **Gowri Panchangam Glance (கௌரி பஞ்சாங்கம்):** Current auspicious/inauspicious Gowri period (e.g., சுபம், லாபம், தனம் vs ரோகம், சோரம், விஷம்).
  * **Upcoming Festivals & Special Days Carousel:** Horizontal preview cards showing the next upcoming Tamil festivals, fasting days (விரத நாட்கள்), and government holidays with countdown.
  * **Shree Taste & Taste Catering CTA Card:** Dedicated banner allowing users to immediately plan wedding/event catering services with direct WhatsApp/Call triggers.
  * **Quick Navigation Grid:** One-touch access to Monthly Calendar, Daily Panchangam, Muhurtham, Festivals, Special Days, and Personal Reminders.

### Screen 4: Monthly Calendar Grid (மாத நாள்காட்டி திரை)
* **Location:** `lib/calendar/screens/calendar_screen.dart`
* **Features Implemented:**
  * **Dual Date System:** Clear calendar grid displaying Gregorian dates with embedded Tamil numerical dates on each cell.
  * **Astrological & Festival Indicators:** Color-coded visual dots and badges for:
    * **Amavasai (அமாவாசை) & Pournami (பௌர்ணமி)**
    * **Pradosham (பிரதோஷம்) & Sashti (சஷ்டி)**
    * **Ekadasi (ஏகாதசி) & Sankatahara Chaturthi (சங்கடஹர சதுர்த்தி)**
    * **Subha Muhurtham Dates (சுப முகூர்த்த நாட்கள்)**
    * **Government Holidays (அரசு விடுமுறை)**
  * **Month & Year Navigation:** Seamless swipe and dropdown selector across all 12 months.
  * **Interactive Date Bottom Sheet:** Tapping any date opens an instant summary card with that date's Thithi, Nakshatra, Chandrashtamam, festivals, and timings.
  * **15-Minute In-Memory Caching:** Ultra-fast sub-millisecond calendar grid rendering using `TNTMemoryCache`.

### Screen 5: Comprehensive Daily Panchangam (முழுமையான தினசரி பஞ்சாங்கம்)
* **Location:** `lib/panchangam/screens/panchangam_detail_screen.dart`
* **Features Implemented:**
  * **Five Core Limbs (பஞ்ச-அங்கம்):**
    * **Thithi (திதி):** Shukla/Krishna Paksha with exact start and completion times.
    * **Nakshatra (நட்சத்திரம்):** Active star with Pada (பாதம்) and end timing.
    * **Yoga (யோகம்):** Siddha, Amrita, Marana yoga indicators.
    * **Karana (கரணம்):** Active Karana calculation.
    * **Vara (வாரம்):** Day of the week with planetary ruler.
  * **Extended Astrological Timings:**
    * **Abhijit Muhurtham & Brahma Muhurtham** (பிரம்ம முகூர்த்தம்).
    * **Durmuhurtham & Varjyam** (துர்முஹூர்த்தம் & வர்ஜ்யம்).
    * **Detailed Hora Chart (ஹோரை அட்டவணை):** 24-hour planetary hour cycle (Surya, Chandra, Angaraka, Budha, Guru, Sukra, Sani hora) with auspiciousness colors.
    * **Full 8-Slot Gowri Panchangam Chart:** Complete breakdown for Day (பகல்) and Night (இரவு).
  * **Zero-Network Mathematical Calculation Engine:** Operates 100% offline using astronomical calculation algorithms when no internet connection is present.

### Screen 6: Subha Muhurtham Dates (சுப முகூர்த்த நாட்கள் திரை)
* **Location:** `lib/muhurtham/screens/muhurtham_screen.dart`, `lib/muhurtham/screens/muhurtham_detail_screen.dart`
* **Features Implemented:**
  * **Categorized Muhurtham Listings:**
    * **Marriage Muhurtham (திருமண முகூர்த்தம்)**
    * **Grihapravesham (வீடு புகுவிழா முகூர்த்தம்)**
    * **General Subha Muhurtham (பொது சுப முகூர்த்தம்)**
  * **Valarpirai / Theipirai Filter (வளர்பிறை / தேய்பிறை வடிகட்டி):** Filter dates by waxing or waning lunar cycles.
  * **Timing Windows & Astrological Rationale:** Displays auspicious Lagnam, Thithi, Nakshatra, and exact morning/evening hours for ceremonies.
  * **Direct Catering Integration:** Every Muhurtham date includes a direct CTA: *"Contact Shree Taste & Taste Catering for this date"*, pre-populating the selected date into the inquiry form.

### Screen 7: Festivals & Special Days (பண்டிகைகள் & சிறப்பு நாட்கள் திரை)
* **Location:** `lib/festivals/screens/festivals_screen.dart`
* **Features Implemented:**
  * **Category Tabs:** All Festivals, Hindu Festivals, Christian Festivals, Muslim Festivals, Government Holidays.
  * **Viratha Naatkal (விரத நாட்கள்):** Dedicated section for recurring monthly fasting days (Kiruthigai, Thiruvonam, Chathurthi, Sivarathiri).
  * **Dynamic Remote Sync & In-Memory Cache:** Automatically synchronizes with Supabase database and caches data for fast offline viewing.

### Screen 8: Personal Events & Reminders (சுய நிகழ்வுகள் & நினைவூட்டல்கள்)
* **Location:** `lib/personal/screens/personal_events_screen.dart`
* **Features Implemented:**
  * **Custom Event Creation:** Add family birthdays, anniversaries, temple poojas, and personal reminders.
  * **Local Push Notification Scheduling:** Alarms and notifications trigger locally on the device at the selected date and time.
  * **Row-Level Security (RLS) Isolation:** All personal events are stored under `public.user_reminders` with strict `auth.uid() = user_id` isolation—no user or administrator can read another user's personal events.

### Screen 9: Shree Taste & Taste Catering Booking (கேட்டரிங் முன்பதிவு திரை)
* **Location:** `lib/features/catering/screens/catering_enquiry_screen.dart`
* **Features Implemented:**
  * **Event Planning Form:** Name, phone number, event type (Wedding, Reception, Housewarming, Birthday, Corporate), event date, guest count, and location.
  * **Triple Action Integration:**
    * **1. WhatsApp Direct Chat:** Auto-generates a pre-formatted Tamil/English WhatsApp inquiry message with all event details and opens WhatsApp with one tap.
    * **2. Direct Phone Call:** Launches telephone dialer with Shree Taste & Taste contact number.
    * **3. Supabase Lead Management:** Submits inquiry record to `public.catering_enquiries` database with offline local storage fallback.

### Screen 10: In-App Notifications (அறிவிப்புகள் திரை)
* **Location:** `lib/notifications/screens/notifications_screen.dart`
* **Features Implemented:**
  * **Admin Broadcast Feed:** View official calendar announcements, festival greetings, and auspicious alerts sent by the management.
  * **Unread Badge & Status Tracking:** Mark notifications as read, delete alerts, and badge counters on the home app bar.

### Screen 11: Admin Management Portal (நிர்வாக கட்டுப்பாட்டு அறை)
* **Location:** `lib/features/admin/`
* **Features Implemented:**
  * **Server-Verified Security Gate:** Checks authenticated user's role in `public.profiles` (`is_admin()`); unauthorized users are completely blocked.
  * **Festival & Special Day Management:** Add, edit, or delete festivals with instant client-cache invalidation.
  * **Muhurtham Date Management:** Add and update auspicious dates and timings.
  * **Notification Campaign Broadcast:** Compose title, message, schedule time, and send broadcast alerts to all users.
  * **User Directory & Verification:** View registered user accounts, email verification status, and account activity.
  * **Analytics Dashboard:** Fast aggregate metrics (total users, active campaigns, catering inquiries) powered by server-side PostgreSQL stored procedures.

---

## 2. Remaining Work List (இன்னும் முடிக்க வேண்டிய பணிகள் & Bugs)

Below is the objective audit of items required for final turnkey delivery:

| Item | Component | Current State | Required Work for 100% Turnkey Launch | Effort / Priority |
| :--- | :--- | :--- | :--- | :--- |
| **1. SMS Gateway Provider** | Authentication (`sms_otp_provider.dart`) | Email OTP works 100%. SMS provider interface exists but has no active paid gateway integration. | Connect commercial SMS Gateway (Fast2SMS / MSG91) via Supabase Edge Function if client requires SMS OTP in addition to Email OTP. | Medium (Optional if Email OTP suffices) |
| **2. Firebase FCM Push Production Credentials** | Notifications (`google-services.json`) | Supabase campaign DB and client notification UI are complete. | Client must supply production Firebase project configuration for background device notification broadcasts. | Low (Setup task) |
| **3. Google Play Console Listing & Signing** | Release Distribution | Release APKs compile cleanly and split-per-ABI. | Generate production release keystore (`.jks`), prepare store graphics (icon 512x512, feature graphic 1024x500, screenshots), and fill Play Store Data Safety form. | Medium (Standard launch task) |
| **4. Analyzer Warning Cleanup** | Code Maintenance | 0 fatal compile errors. 138 minor linter suggestions (e.g., `avoid_print`, deprecated widget params). | Routine cleanup of informational lint suggestions before final code delivery. | Low (Polish) |
| **5. Privacy Policy Webpage** | Legal Compliance | Mandatory requirement for Google Play Store approval. | Host a standard static Privacy Policy webpage (can be hosted free on GitHub Pages or client website). | Low (Setup task) |

---
