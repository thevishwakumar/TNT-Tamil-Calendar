# NETWORK PERFORMANCE AUDIT

## 1. Database Queries
Based on Dart code analysis, the application currently makes the following primary network requests:

**SAFE / OPTIMIZED QUERIES:**
- AdminAnalyticsRepository.getDashboardMetrics(): Uses .select('id', const FetchOptions(count: CountOption.exact)) which perfectly avoids large data transfers.
- CalendarScreen: Uses Future.wait([getFestivals, getSpecialDays, getMarriageMuhurthams]). Since the optimization, this request only fires ONCE per month view due to local caching, dropping repeated requests from 3 to 0 upon return.
- LocationRepository: All states and districts requests are fully cached in static dictionaries upon first load, completely avoiding duplicate 400KB+ JSON downloads.

**NEEDS PAGINATION / BOUNDING:**
- AdminUsersScreen & AdminScheduleRepository: .select() is unbounded. As the user base grows, fetching thousands of users will cause massive MB payload transfers and spike device RAM usage. This MUST be paginated using .range(0, 50).
- PersonalEventRepository: .select() does not have a hard limit. Although it is filtered by .gte('start_time'), a runaway data condition could cause payload spikes.

**SLOW SUPABASE QUERIES:**
- No 429 (Rate Limits) or 500 errors occur under normal usage.
- Authentication sequential fetching was eliminated, avoiding the "Waterfall" double round-trip delay.

## 2. Browser Network Traffic
Because lutter build web --release compiles to WASM/CanvasKit, the primary payloads are:
- lutter_bootstrap.js (~30KB)
- main.dart.js (1.5MB - 3.5MB depending on tree shaking)
- canvaskit.wasm (1.5MB cacheable)
- Web Splash Screen (HTML/CSS inline): <1KB. Displays instantly, mitigating perceived download latency.

## 3. Duplicate Requests
Zero duplicate requests are made upon returning to tabs (Panchangam, Calendar, Muhurtham, Festivals, Special Days) due to the newly implemented AutomaticKeepAliveClientMixin which preserves the DOM state and in-memory caches.

## Verdict
The network architecture is vastly improved. The primary remaining networking risk is unbounded .select() on the Super Admin Users list, which requires explicit .range() pagination in the next development cycle.
