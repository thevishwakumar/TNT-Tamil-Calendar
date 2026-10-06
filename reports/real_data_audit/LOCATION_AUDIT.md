# LOCATION SYSTEM AUDIT

## Current Architecture
The application currently uses an entirely hardcoded, local static dataset for countries, states, districts, and cities.

## Finding Details
- **File:** lib/models/location_models.dart
- **Implementation:** Hardcoded List<TNTCountry>, List<TNTState>, List<TNTDistrict>, List<TNTCity>.
- **Limitation:** The cities list only contains ~20 cities (Chennai, Coimbatore, Madurai, etc. and a few global diaspora cities). 
- **Violation:** Directly violates Phase 2 mandate: "Do NOT use a small manually hardcoded city list."

## Action Plan (Phase 2 Remediations)
1. **Schema Migration:** Verify if countries, states, districts, cities tables exist in Supabase. If not, create a SQL migration file to initialize them.
2. **Dynamic Repository:** Create LocationRepository to query Supabase directly using search, pagination, and relational joins.
3. **UI Refactoring:** Update city_selector_sheet.dart to use a 4-step dynamic selector (Country -> State -> District -> City) with debounced search.
4. **Data Seed:** Provide a SQL script to seed authoritative India location data.
5. **Delete Hardcoded Data:** Remove the static datasets from location_models.dart.
