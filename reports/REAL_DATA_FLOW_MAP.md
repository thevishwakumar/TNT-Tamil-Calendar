# REAL DATA FLOW MAP

## 1. Calendar Module
**SCREEN:** CalendarScreen (lib/calendar/screens/calendar_screen.dart)
**REPOSITORY/SERVICE:** SupabaseApiService (getFestivals, getSpecialDays, getMarriageMuhurthams)
**SUPABASE TABLE:** estivals, special_days, muhurtham_dates
**QUERY:** .select().eq('month', month).eq('year', year)
**MODEL:** Festival, SpecialDay, MuhurthamDate
**UI:** Dynamic Grid mapping directly to these 3 lists.

## 2. Muhurtham Module
**SCREEN:** MuhurthamScreen
**REPOSITORY/SERVICE:** SupabaseApiService (getMuhurthamDates)
**SUPABASE TABLE:** muhurtham_dates
**QUERY:** .select().eq('month', month).eq('year', year)
**MODEL:** MuhurthamDate
**UI:** List of MuhurthamDateCard widgets rendering real DB properties.

## 3. Festivals Module
**SCREEN:** FestivalsScreen
**REPOSITORY/SERVICE:** SupabaseApiService (getFestivals)
**SUPABASE TABLE:** estivals
**QUERY:** .select().eq('month', month).eq('year', year)
**MODEL:** Festival
**UI:** List view bound to the real Festival objects.

## 4. Special Days Module
**SCREEN:** SpecialDaysScreen
**REPOSITORY/SERVICE:** SupabaseApiService (getSpecialDays)
**SUPABASE TABLE:** special_days
**QUERY:** .select().eq('month', month).eq('year', year)
**MODEL:** SpecialDay
**UI:** Expandable card list mapping to DB entities.

## 5. Location Module
**SCREEN:** CitySelectorSheet
**REPOSITORY/SERVICE:** LocationRepository (searchCities)
**SUPABASE TABLE:** cities, districts, states, countries
**QUERY:** .select().eq('is_active', true).ilike('name', '%query%').limit(50)
**MODEL:** TNTCity, TNTDistrict, TNTState, TNTCountry
**UI:** Typeahead search bound to Supabase query.

## 6. Personal Calendar Module
**SCREEN:** PersonalCalendarScreen
**REPOSITORY/SERVICE:** PersonalEventRepository (getEventsForDate, createEvent)
**SUPABASE TABLE:** personal_events
**QUERY:** .select().eq('user_id', currentUser).gte('start_time', dayStart).lte('end_time', dayEnd)
**MODEL:** PersonalEvent
**UI:** Event list reflecting exactly what exists in DB for this user.

## 7. Panchangam Module
**SCREEN:** PanchangamScreen
**REPOSITORY/SERVICE:** PanchangamRepository -> SupabasePanchangamProvider -> NavamshaPanchangService
**SUPABASE TABLE:** Hybrid (Calculated Ephemeris locally via swisseph logic in Dart + augments with estivals, special_days, muhurtham_dates from DB)
**QUERY:** Ephemeris equations (Math) + .select() for daily specials.
**MODEL:** PanchangamDailyBundle
**UI:** Complex layout showing dynamic astronomical positions and static database events.

## 8. Dashboard Analytics Module
**SCREEN:** AdminDashboardScreen
**REPOSITORY/SERVICE:** AdminAnalyticsRepository
**SUPABASE TABLE:** profiles, user_saved_items, user_reminders
**QUERY:** .select('id', const FetchOptions(count: CountOption.exact, forceResponse: true))
**MODEL:** AdminDashboardMetrics
**UI:** 4 KPI Cards bound to actual Postgres COUNT headers.
