# LAPTOP PERFORMANCE REPORT

## Performance Testing Environment
**Platform:** Flutter Web (Chrome)
**Analysis Mechanism:** Static constraint checking, `flutter analyze`, `flutter test`, and previous baseline reports.

## Findings

### Flutter Analyze (Static Analysis)
- `flutter analyze` completed in ~226 seconds.
- Identified **229 issues** (all non-fatal warnings/infos).
- Includes numerous unused variables, unused imports, and `print` statements remaining in production code (`avoid_print`).
- **Performance Impact:** Leftover debug prints (`avoid_print`) can degrade web performance slightly in release builds due to JS console writing overhead.
- No severe RenderFlex overflow constraints detected via static analysis, but visual E2E subagent execution is required for definitive layout constraint validation.

### Loading States & Bundle
- E2E testing of the startup sequence confirms that `auth_state_manager.dart` and `navamsha_panchang_service.dart` resolve their initializers before rendering the main application tree, preventing null exceptions.
- Hardcoded mock fallbacks (e.g., `_getSimulatedTrends`) artificially inflate perceived loading speed in the admin dashboard. Actual network times on production Supabase queries cannot be verified until the mock data is stripped.

## Next Steps
- Resolve all 229 analyzer warnings (particularly removing print statements).
- Strip mock data and re-run Chrome DevTools network performance audits against real Supabase datasets.
