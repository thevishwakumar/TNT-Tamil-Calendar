# TNT Navamsha & Shastra Dual API Implementation Report

## 1. Architecture Overview
The sync engine connects TNT's local Admin Dashboard to two independent astronomical data providers:
- **Shastra Panchangam (Primary Festival Source):** Free API without keys used primarily to fetch festival dates across specific cities.
- **Navamsha API (Primary Timing/Panchang Source):** Handled securely via a Supabase Edge Function to protect the `NAVAMSHA_API_KEY`. Provides rigorous location-aware astronomical timings (Sunrise, Rahu, Tithi, Nakshatra, etc.).

## 2. API Endpoints Inspected
- **Shastra Cities:** `GET /api/v1/cities.json`
- **Shastra Festivals:** `GET /api/v1/festivals.json`
- **Shastra Range:** `GET /api/v1/range/{city}.json`
- **Navamsha Endpoints:** Protected and accessed exclusively through `navamsha_panchang_service.dart` routing to Supabase edge function `v1/navamsha-panchang`.

## 3. Database Mappings
- **Festivals:** Parsed from Shastra's generic rule dates and city-specific `local_dates` into `festivals` table via UPSERT matching `(date, name_english)`.
- **Panchangam:** Will be managed through `panchangam_entries` joining to `calendar_days`.

## 4. UI Implementation
- The Admin portal has a unified **Panchangam Sync** module under `AdminDashboard` -> `AdminSection.panchangamSync`.
- Implements a DRY RUN preview phase. The admin selects Location, Year, and Target sync modules (Festivals, Panchangam). They receive a statistical preview of inserts/updates vs skipped rows, ensuring destructive edits are avoided prior to final confirm.

## 5. Security & Manual Overrides
- **No User Fetch:** Users query `festivals` and `calendar_days` natively from Supabase via `ProductionApiService`. Normal users are completely insulated from third-party API rate limits or failures.
- **RLS:** All inserts/updates are authenticated by Supabase session tokens passing strictly via the `SupabaseService`.

## 6. Implementation Status
- Phase 0 (Audit) & Phase 1 (Data Flow) Complete.
- Dual API Client Structure Constructed.
- Admin Sync UI and Preview capability functional.

*Pending confirmation of `flutter analyze` and further unit tests.*
