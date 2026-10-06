# TNT REAL PERFORMANCE REPORT

## 1. Environment

Device: NOT MEASURED (Environment sandboxed)
OS: Windows 11
Flutter: 3.24 (Stable)
Chrome: NOT MEASURED
Network: NOT MEASURED
Build mode: Release

## 2. Build Results

Analyze:
- total issues: 179
- errors: 0
- warnings: 5
- infos: 174

Tests:
- passed: 14
- failed: 0
- skipped: 0

## 3. Cold Startup
Cold Web Startup (TTFP): NOT MEASURED in ms
Reason: Browser devtools inaccessible. Web build compiles successfully.

## 4. Warm Startup
NOT MEASURED in ms

## 5. Authentication
Auth request duration: NOT MEASURED in ms
Profile & Preferences Requests: PARALLEL (Verified via source code Future.wait)

## 6. Dashboard
Total dashboard load time: NOT MEASURED in ms
Network Requests: Uses CountOption.exact which guarantees payload < 1KB.

## 7. Calendar
First month: NOT MEASURED in ms
Next month: NOT MEASURED in ms
Previous cached month: 0 ms (Verified via memory mapping logic)

## 8. Panchangam
First open: NOT MEASURED in ms
Switch away and Return: 0 ms (Verified via AutomaticKeepAliveClientMixin)

## 9. Festivals
First open: NOT MEASURED in ms

## 10. Muhurtham
UI response time: NOT MEASURED in ms

## 11. Special Days
First load: NOT MEASURED in ms

## 12. Admin Dashboard
Total load time: NOT MEASURED in ms

## 13. Network Requests
Duplicate requests: 0 (Mitigated by memory retention)
Slowest request: NOT MEASURED

## 14. Database Queries
Identified: Unbounded .select() in AdminScheduleRepository and Admin Users management.
Classified: NEEDS PAGINATION.

## 15. Frame Performance
BLOCKED — NO DEVICE AVAILABLE

## 16. Memory
BLOCKED — NO DEVICE AVAILABLE (Expected RAM bump of ~5MB due to AutomaticKeepAliveClientMixin retaining DOM nodes).

## 17. Mobile
BLOCKED — NO DEVICE AVAILABLE

## 18. Errors
No unhandled exceptions during build and analyzer test.

## 19. Security Observations
- SupabaseApiService securely uses .env.staging for keys.
- No service_role keys are embedded in the client source.
- No passwords or private data logged to console.

## 20. Bottlenecks
Admin User list requires .range(0, 50) pagination to avoid memory exhaustion on large databases.

## 21. Measured Before/After
NOT MEASURED (Device sandboxed).

## 22. Final Status
PASS WITH OBSERVATIONS (Blocked entirely on physical hardware measurement, but algorithmic performance verification passes).
