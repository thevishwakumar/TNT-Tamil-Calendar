# CONTENT MODULES AUDIT (Calendar, Muhurtham, Festivals, Special Days)

## Current Architecture
The application injects DevelopmentApiService as the primary ITNTApiService in main.dart. 

## Finding Details
- **File:** lib/services/supabase_service.dart (Lines 100-600)
- **Implementation:** DevelopmentApiService contains massive static JSON arrays for CalendarDay, PanchangamEntry, MuhurthamDate, Festival, and SpecialDay.
- **Violation:** This violates the absolute core mandate of the Real-Data Policy. The app is entirely relying on hardcoded content arrays masquerading as API responses.

## Action Plan (Phase 3 & Phase 8-11 Remediations)
To completely decouple the application from fake data, we must:
1. **Schema Migration:** Create SQL tables in Supabase for calendar_days, muhurtham_dates, estivals, and special_days.
2. **Production Service:** Implement SupabaseApiService that implements ITNTApiService using real Supabase queries (_db.client.from('muhurtham_dates').select()).
3. **Dependency Injection:** Swap DevelopmentApiService for SupabaseApiService in main.dart.
4. **Purge:** Delete DevelopmentApiService from the codebase entirely.

NOTE: Panchangam data is the only exception; it correctly uses 
avamsha_panchang_service.dart for genuine offline mathematical calculations. However, the API interface still needs to be routed through the production service.
