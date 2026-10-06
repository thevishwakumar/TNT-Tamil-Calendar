# TNT PERFORMANCE BASELINE

## Methodology
- Ran lutter analyze (171 minor issues/warnings, 0 fatal errors).
- Ran lutter test --reporter=expanded (14/14 tests passed, 0 failures).
- Inspected the startup sequence (main.dart -> SupabaseService -> AuthStateManager).
- Inspected existing querying architecture (production_api_service.dart, dmin_dashboard.dart, etc).
- Codebase size and dependency check.

## Baseline Measurements

1. **Cold Startup Time:** NOT MEASURED (Estimated slow due to sequential awaiting of SupabaseService().init(), dotenv.load(), and AuthStateManager()._initializeAuth()).
2. **Time Until First Visible UI:** NOT MEASURED (Blocked by multiple asynchronous operations in main() before unApp).
3. **Login Duration:** NOT MEASURED.
4. **Dashboard Loading Duration:** NOT MEASURED (Currently blocks until profile is fetched).
5. **Calendar Loading Duration:** NOT MEASURED.
6. **Panchangam Loading Duration:** NOT MEASURED.
7. **Admin Dashboard Loading Duration:** NOT MEASURED (Uses .select('*') leading to over-fetching).
8. **Navigation Transition Time:** NOT MEASURED.
9. **Android Runtime Performance:** NOT MEASURED.

## Preliminary Bottlenecks Discovered

1. **Sequential Startup Blocking:** main() halts execution for dotenv.load() and SupabaseService().init() before even invoking unApp(). This delays the first frame (Splash Screen).
2. **Auth Initialization Waterfall:** AuthStateManager triggers loadUserSession which sequentially awaits _profileRepo.fetchUserProfile followed by _prefRepo.fetchUserPreferences instead of parallelizing them.
3. **N+1 / Sub-optimal Queries:** Throughout the admin panel, large selects like .select('*') are used for aggregations which pulls massive payloads just to count rows.
4. **Calendar Cell Rebuilds:** The Calendar relies on heavy widget structures that rebuild frequently on month navigation.
5. **Missing Caching for Immutable Data:** Muhurtham and Festival data are static per year but fetched repeatedly without local memory caching.

*This baseline will serve as the reference point before applying Phases 1-22 optimizations.*
