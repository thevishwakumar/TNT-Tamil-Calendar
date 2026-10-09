# TNT Tamil Calendar — Commercial Proposal, Quotation & Project Terms

**Project:** `C:\Users\Vishw\Downloads\TNT`  
**Application Name:** TNT Tamil Calendar (தமிழ் காலண்டர் & கேட்டரிங் சேவை)  
**Document Type:** Formal Commercial Quotation & Technical Agreement  
**Date:** October 2026  

---

## 1. Written ₹50,000 Complete Commercial Quotation (முழுமையான ₹50K திட்ட மதிப்பீடு)

The **₹50,000 Full-Stack Production Package** represents a turnkey, enterprise-grade mobile application and cloud backend ready for mass consumer deployment on the Google Play Store, engineered to support **1,000+ concurrent active users**.

### Scope of Work (திட்ட எல்லை)
* **Mobile Application (Flutter Cross-Platform):**
  * Android & iOS unified codebase with 11 complete user screens.
  * Native splash screen with TNT branding and zero white-screen flash.
  * Complete bilingual localization engine (தமிழ் & English instant toggle).
  * 15-minute in-memory caching layer (`TNTMemoryCache`) delivering sub-millisecond calendar navigation.
  * Offline-capable astronomical calculation engine for Tamil Panchangam.
  * Direct WhatsApp, phone, and lead-generation integration for **Shree Taste & Taste Catering**.
* **Cloud Backend & Security Infrastructure (Supabase PostgreSQL):**
  * Fully deployed PostgreSQL schema across 37 tables with foreign keys and cascading integrity.
  * Strict Row-Level Security (RLS) policies on all tables ensuring zero cross-user data leakage.
  * Role-Based Access Control (RBAC) with hardened `is_admin()` verification and anti-privilege escalation triggers.
  * 11 composite performance indexes optimized for high-concurrency PostgREST filtering.
  * Stored procedure RPCs for sub-second admin analytics aggregation.
  * Jittered exponential backoff client resilience (`TNTResilience`) with automatic recovery from transient network drops.
* **Administrative Control Panel:**
  * Web / mobile-accessible administrative portal.
  * Dynamic CRUD management for Festivals, Special Days, and Muhurtham dates with instant cache invalidation.
  * Push notification broadcast campaign manager.
  * Registered user directory and activity monitoring.
* **Testing & Production Release:**
  * Comprehensive automated test suite (30/30 unit, model, and security isolation tests).
  * Empirical 50 to 1,000 concurrent user load testing verification.
  * Google Play Store release build packaging (`split-per-abi` APK and production AAB).

### Deliverables (வழங்கப்படும் பொருட்கள்)
1. **Complete Source Code Repository:** Full Flutter source code and SQL migration files.
2. **Production Release Artifacts:** Signed release Android App Bundle (AAB) and split release APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
3. **Hardened Cloud Database:** Production-ready Supabase database with migrations applied, RLS enabled, and indexes built.
4. **Admin Panel Access & Credentials:** Master administrator account setup and operational instructions.
5. **Technical & User Documentation:** Comprehensive architecture baseline, security audit report, and load-test benchmark report.
6. **30 Days Hypercare Warranty:** 30 days of post-deployment bug fixing and technical support.

### Exclusions (திட்டத்தில் சேராதவை)
* **Google Play Console Account Fee:** $25 one-time registration fee payable directly to Google by the client.
* **Apple Developer Program Fee:** $99/year fee payable directly to Apple (if iOS App Store release is requested).
* **Third-Party Paid API/SMS Gateway Credits:** Paid SMS credits (e.g., Fast2SMS or MSG91) or paid Navamsha API subscriptions (app includes free offline mathematical calculation and Supabase Email OTP).
* **Cloud Infrastructure Upgrades:** Supabase Free Tier is included; if database usage exceeds free limits, Supabase Pro ($25/month) is payable directly to Supabase.

### Milestones & Delivery Schedule (மைல்கற்கள் & காலவரிசை)

| Milestone | Stage Description | Deliverable | Percentage | Amount |
| :---: | :--- | :--- | :---: | :---: |
| **M1** | **Project Kickoff & Security Architecture** | Backend schema setup, RLS hardening, Google OAuth & Email OTP verification, project repository setup. | **25%** | **₹12,500** |
| **M2** | **Core App & Panchangam Engine** | Monthly calendar grid, offline mathematical Panchangam, Muhurtham screens, Festivals, and 15-min caching layer. | **25%** | **₹12,500** |
| **M3** | **Admin Portal & Catering Integration** | Admin dashboard, notification campaigns, Shree Taste & Taste Catering inquiry module, and unit/security test suite. | **25%** | **₹12,500** |
| **M4** | **Load Testing, Release Packaging & Handover** | 1,000-user load test certification, Google Play release build generation, full source code handover, and final sign-off. | **25%** | **₹12,500** |
| **Total** | | | **100%** | **₹50,000** |

---

## 2. Basic ₹10,000 Alternative (அடிப்படை ₹10K மாற்றுத் திட்டம்)

For clients seeking an entry-level, standalone calendar application without server costs or administrative overhead, a **₹10,000 Standalone Alternative** is available.

### Features Included in the ₹10K Plan (உள்ளடக்கியவை)
* **Core Tamil Calendar Grid:** Standard monthly calendar view with Gregorian and Tamil dates.
* **Offline Mathematical Panchangam:** Local calculation of daily sunrise, sunset, Rahu Kalam, Yamagandam, and Nalla Neram for Tamil Nadu coordinates.
* **Static Pre-Loaded Festivals:** Built-in list of Tamil festivals and Tamil Nadu Government Holidays.
* **Basic Muhurtham Dates:** Built-in list of standard marriage Muhurtham dates for the current year.
* **Guest-Only Access:** Completely offline operation requiring no login or registration.
* **Click-to-WhatsApp Catering Button:** Direct link opening WhatsApp with catering phone number.
* **Standalone Release APK:** Unsigned APK file provided for direct manual installation on Android devices.

### Features Removed / Deferred in the ₹10K Plan (நீக்கப்பட்ட அல்லது தள்ளிவைக்கப்பட்ட அம்சங்கள்)

| Feature | ₹50,000 Full Package | ₹10,000 Basic Alternative | Reason for Removal / Deferral |
| :--- | :---: | :---: | :--- |
| **Cloud Database (Supabase)** | ✅ Included | ❌ Removed | Eliminates all cloud database hosting and maintenance requirements. |
| **User Accounts & Google Sign-In** | ✅ Included | ❌ Removed | No cloud user profiles, email OTP, or user sessions. |
| **Admin Control Panel** | ✅ Included | ❌ Removed | Festivals/dates cannot be edited remotely; requires manual app rebuild to change data. |
| **Broadcast Push Notifications** | ✅ Included | ❌ Removed | No cloud campaign broadcasting; users only receive local offline alarms. |
| **Catering Lead Database & CRM** | ✅ Included | ❌ Removed | Inquiries are not stored in a cloud database; only direct WhatsApp message is triggered. |
| **1,000+ Concurrent User Architecture** | ✅ Included | ❌ Removed | App is strictly single-device offline with zero server scaling infrastructure. |
| **Google Play Store Submission** | ✅ Included | ❌ Removed | Client is responsible for store listing and account submission; only APK provided. |
| **30 Days Hypercare Support** | ✅ Included | ❌ 7 Days Only | Reduced warranty period for bug fixes. |

---

## 3. Panchangam Data Source (பஞ்சாங்கம் தரவு மூலங்கள், துல்லியம் & உரிமை)

### A. Architectural Approach (இரட்டை கட்டமைப்பு)
The application utilizes a robust dual-layer architectural approach:
1. **Primary Autonomous Engine (Offline Mathematical Calculation):**
   * Implemented in `lib/panchangam/services/panchangam_calculator.dart` and `lib/repositories/panchang_repository.dart`.
   * Computes solar sunrise, sunset, Rahu Kalam, Yamagandam, Gulika Kaal, Nalla Neram, and Gowri Panchangam mathematically using standard astronomical solar coordinates for Tamil Nadu (Coimbatore / Chennai reference).
   * **Advantage:** Zero third-party API dependencies, 100% offline uptime, zero network latency, and zero monthly recurring API bills.
2. **Supplemental Cloud Sync (Navamsha API / Supabase Overrides):**
   * Configured via `lib/services/production_api_service.dart` and `lib/panchangam/repositories/panchangam_repository.dart`.
   * Allows the administrator to inject curated festival dates, specialized temple Muhurtham timings, or link with an online astronomical feed (such as Navamsha API) via Supabase Edge Functions without modifying client code.

### B. Mathematical Accuracy & Quality Control (துல்லியம்)
* Astrological calculations have been rigorously verified against classical Drik Ganitha Tamil Panchangam almanacs.
* Rahu Kalam, Yamagandam, and Nalla Neram strictly follow authentic weekday astronomical segments.
* Tamil solar months (Chithirai through Panguni) are determined by solar ingress calculations.
* Automated unit tests (`test/panchang_offline_mathematical_test.dart`) validate calculations on every code change.

### C. Intellectual Property & Ownership (உரிமை)
* **100% Client Ownership:** All mathematical calculation algorithms, offline database files, festival datasets, and UI widgets are completely owned by the client upon project completion.
* **Zero Vendor Lock-In:** The application does not depend on proprietary third-party commercial services to calculate everyday Panchangam.

### D. Update Process (தரவு புதுப்பிக்கும் முறை)
* **Dynamic Server Updates:** Administrators can update upcoming festival dates or add newly declared government holidays directly from the Admin Panel. Changes appear instantly in the app without requiring an update through the Google Play Store.
* **Annual Renewal:** Standard Panchangam mathematical rules remain valid permanently; festival schedules for subsequent Gregorian years can be imported in bulk via the provided SQL migrations or admin portal.

---

## 4. Publishing & Maintenance (வெளியீடு, கணக்கு உரிமை & பராமரிப்பு)

### Account Ownership (கணக்கு உரிமை)
* **Google Play Console Account:** Must be opened in the client's / organization's name. The client retains 100% legal ownership of the developer account, app package name (`com.vishwakumar.tnt_tamil_calendar`), and store listing.
* **Supabase Cloud Backend Account:** Created under the client's email address. The client holds master ownership and all API credentials.
* **Source Code Repository:** Transferred completely to the client's GitHub / GitLab account upon project completion.

### Recurring Operational Costs (தொடர் செலவுகள்)
The system has been architected to minimize recurring expenses:

| Service | Provider | Cost | Frequency | Necessity |
| :--- | :--- | :--- | :--- | :--- |
| **Google Play Developer Account** | Google | **$25** (~₹2,100) | **One-time lifetime** | Mandatory for Play Store distribution |
| **Supabase Cloud Hosting** | Supabase | **$0 (Free Tier)** | Ongoing | Free tier supports 500 MB DB & 50,000 active users |
| **Supabase Pro Tier (Optional)** | Supabase | $25/month (~₹2,100) | Monthly | Only required if exceeding 50,000 monthly active users |
| **SMS Gateway (Optional)** | Fast2SMS / MSG91 | ~₹0.20 per SMS | Pay-as-you-go | Only needed if SMS OTP is enabled (Email OTP is 100% free) |
| **Domain & Privacy Hosting** | GitHub Pages / Cloud | **$0 (Free)** | Ongoing | Free hosting for mandatory store Privacy Policy |

### Post-Launch Support & Warranty (ஆதரவு & உத்தரவாதம்)
* **30-Day Hypercare Warranty (Included in ₹50K):**
  * Immediate resolution of any defects, crashes, or functional bugs identified post-launch.
  * Assistance with Google Play Store review queries, policy declarations, and Data Safety disclosures.
  * Database indexing and connection monitoring during initial launch traffic spikes.
* **Optional Annual Maintenance Contract (AMC) (விரும்பினால் தேர்வு செய்யலாம்):**
  * **Option A: Monthly Retainer:** ₹2,500 / month (covers ongoing OS compatibility updates, monthly database backups, and emergency support).
  * **Option B: Annual Retainer:** ₹25,000 / year (includes two feature enhancement releases per year).

---

## 5. Payment Terms & Acceptance Process (கட்டண விதிமுறைகள் & ஒப்புதல் முறை)

### Payment Milestones (கட்டண மைல்கற்கள்)
1. **Advance Payment (25% — ₹12,500):** Due upon signing of agreement and project initiation.
2. **Milestone 2 Payment (25% — ₹12,500):** Due upon successful demonstration of core Calendar, Panchangam engine, and authentication.
3. **Milestone 3 Payment (25% — ₹12,500):** Due upon demonstration of Admin Panel, Catering integration, and Notification broadcast system.
4. **Final Milestone Payment (25% — ₹12,500):** Due upon Google Play release build generation, 1,000-user load test certification, and complete source code repository handover.

### Acceptance & Sign-off Process (ஒப்புதல் நடைமுறை)
* **Written Milestone Reports:** For each milestone, a structured demonstration report and test APK will be provided to the client.
* **Client Review Period:** The client has **3 business days** to review the delivered milestone and submit any change requests or bug reports.
* **Formal Written Acceptance:** Upon verification, the client provides written acceptance (via email or signed milestone sign-off), triggering the invoice for the subsequent stage.
* **Handover & Delivery:** All master administrator credentials, database master passwords, and production signing keystores are released immediately upon settlement of the final milestone.

---

## 6. Formal Acceptance & Signatures (முறைசார் ஒப்புதல்)

By signing below, both parties agree to the scope, milestones, deliverables, and payment terms outlined in this proposal.

**For TNT Tamil Calendar / Shree Taste & Taste:**  
Name: ____________________________________  
Signature: _______________________________  
Date: ____________________________________  

**For Development & Technical Engineering:**  
Name: Vishwakumar / Technical Lead  
Signature: _______________________________  
Date: ____________________________________  
