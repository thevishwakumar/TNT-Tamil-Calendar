import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../models/panchangam_bundle.dart';
import '../../repositories/panchang_repository.dart';

/// Abstract Data Provider Contract for extensible Panchangam data sources
abstract class PanchangamDataProvider {
  Future<PanchangamDailyBundle?> getDailyPanchangam(DateTime date, String location);
}

/// Supabase & Navamsha Single Source of Truth Provider
class SupabasePanchangamProvider implements PanchangamDataProvider {
  final ITNTApiService apiService;
  final PanchangRepository _panchangRepo = PanchangRepository();

  SupabasePanchangamProvider({required this.apiService});

  @override
  Future<PanchangamDailyBundle?> getDailyPanchangam(DateTime date, String location) async {
    try {
      final userLocation = UserLocationItem(
        id: 'loc-$location',
        userId: 'active-user',
        name: location,
        city: location,
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      );

      final bundle = await _panchangRepo.getDailyPanchangam(date: date, location: userLocation);

      // Supplement with curated festivals and muhurtham dates from client-approved metadata
      List<SpecialDay> allSpecials = [];
      List<Festival> allFestivals = [];
      List<MuhurthamDate> allMuhurthams = [];
      
      try {
        final futures = await Future.wait([
          apiService.getSpecialDays(date.year, date.month),
          apiService.getFestivals(date.year, date.month),
          apiService.getMarriageMuhurthams(date.year, date.month),
        ]);
        allSpecials = futures[0] as List<SpecialDay>;
        allFestivals = futures[1] as List<Festival>;
        allMuhurthams = futures[2] as List<MuhurthamDate>;
      } catch (e) {
        print('Warning: Failed to fetch supplemental panchangam data: ');
      }

      final daySpecials = allSpecials.where((s) =>
        s.date.year == date.year &&
        s.date.month == date.month &&
        s.date.day == date.day
      ).toList();

      final dayFestivals = allFestivals.where((f) =>
        f.date.year == date.year &&
        f.date.month == date.month &&
        f.date.day == date.day
      ).toList();

      final dayMuhurthams = allMuhurthams.where((m) =>
        m.date.year == date.year &&
        m.date.month == date.month &&
        m.date.day == date.day
      ).toList();

      return PanchangamDailyBundle(
        date: date,
        location: location,
        calendarDay: bundle.calendarDay,
        panchangam: bundle.panchangam,
        timings: bundle.timings,
        specialDays: [...bundle.specialDays, ...daySpecials],
        festivals: dayFestivals,
        muhurthams: dayMuhurthams,
        isFromOfflineCache: bundle.isFromOfflineCache,
        cachedAt: bundle.cachedAt,
      );
    } catch (e, stack) {
      print('SupabasePanchangamProvider Error: $e\n$stack');
      rethrow;
    }
  }
}

/// Panchangam Repository with in-memory caching and request deduplication
class PanchangamRepository {
  final PanchangamDataProvider dataProvider;
  final Map<String, PanchangamDailyBundle> _cache = {};

  PanchangamRepository({required this.dataProvider});

  String _cacheKey(DateTime date, String location) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_$location';
  }

  /// Fetches the Panchangam bundle for a date and location
  Future<PanchangamDailyBundle?> getPanchangamBundle(
    DateTime date, {
    String location = 'Chennai',
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(date, location);

    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key];
    }

    final bundle = await dataProvider.getDailyPanchangam(date, location);
    if (bundle != null) {
      _cache[key] = bundle;
    }
    return bundle;
  }

  void clearCache() {
    _cache.clear();
  }
}

/// Location Repository for managing user-selected cities and coordinates
class LocationRepository {
  static const List<String> availableCities = [
    'Chennai',
    'Madurai',
    'Coimbatore',
    'Trichy',
    'Salem',
    'Tirunelveli',
    'Bengaluru',
    'Mumbai',
    'Delhi',
    'Singapore',
    'Kuala Lumpur',
    'Colombo',
  ];

  String _currentLocation = 'Chennai';
  bool _useGps = false;

  String get currentLocation => _currentLocation;
  bool get useGps => _useGps;

  void setLocation(String city) {
    if (availableCities.contains(city)) {
      _currentLocation = city;
      _useGps = false;
    }
  }

  void setUseGps(bool value) {
    _useGps = value;
    if (value) {
      // Trigger actual GPS resolution upstream instead of mocking
      _currentLocation = '';
    }
  }
}
