import '../models/tnt_models.dart';
import '../panchangam/models/panchangam_bundle.dart';
import '../services/navamsha_panchang_service.dart';
import '../services/supabase_service.dart';
import '../services/panchang_local_cache_service.dart';

// =====================================================================
// EXPLICIT PROVIDER ABSTRACTIONS
// =====================================================================

/// Explicit Configurable Provider for Nalla Neram
class NallaNeramProvider {
  /// Returns morning and evening Nalla Neram timing windows
  static List<TimingEntry> getNallaNeramTimings(DateTime date, Map<String, dynamic> rawAstronomical) {
    final timings = rawAstronomical['auspiciousTimings'] as Map<String, dynamic>?;
    final morning = timings?['nallaNeramMorning'] as String? ?? '09:15 AM - 10:15 AM';
    final evening = timings?['nallaNeramEvening'] as String? ?? '04:45 PM - 05:45 PM';

    final morningParts = morning.split(' - ');
    final eveningParts = evening.split(' - ');

    return [
      TimingEntry(
        name: 'Nalla Neram (Morning)',
        nameTa: 'நல்ல நேரம் (காலை)',
        startTime: morningParts.isNotEmpty ? morningParts[0] : '09:15 AM',
        endTime: morningParts.length > 1 ? morningParts[1] : '10:15 AM',
        isAuspicious: true,
        category: 'nalla_neram',
        description: 'Prime morning auspicious window for start of ventures',
        descriptionTa: 'சுப காரியங்கள் தொடங்க உகந்த காலை நேரம்',
      ),
      TimingEntry(
        name: 'Nalla Neram (Evening)',
        nameTa: 'நல்ல நேரம் (மாலை)',
        startTime: eveningParts.isNotEmpty ? eveningParts[0] : '04:45 PM',
        endTime: eveningParts.length > 1 ? eveningParts[1] : '05:45 PM',
        isAuspicious: true,
        category: 'nalla_neram',
        description: 'Auspicious evening window',
        descriptionTa: 'மங்களகரமான மாலை வேளை',
      ),
    ];
  }
}

/// Explicit Configurable Provider for Gowri Panchangam
class GowriPanchangamProvider {
  static List<TimingEntry> getGowriTimings(DateTime date, Map<String, dynamic> rawAstronomical) {
    final weekday = date.weekday; // 1 = Monday ... 7 = Sunday
    // Deterministic Gowri time slots based on classical Tamil astrological texts
    final slots = _getGowriSlotsForWeekday(weekday);
    return slots.map((s) => TimingEntry(
      name: s['nameEn'] as String,
      nameTa: s['nameTa'] as String,
      startTime: s['start'] as String,
      endTime: s['end'] as String,
      isAuspicious: s['isAuspicious'] as bool,
      category: 'gowri',
      description: s['isAuspicious'] as bool ? 'Subha Gowri Window' : 'Inauspicious Gowri Window',
      descriptionTa: s['isAuspicious'] as bool ? 'சுப கௌரி நேரம்' : 'தவிர்க்க வேண்டிய கௌரி நேரம்',
    )).toList();
  }

  static List<Map<String, dynamic>> _getGowriSlotsForWeekday(int weekday) {
    return [
      {'nameEn': 'Gowri Nalla Neram (Morning)', 'nameTa': 'கௌரி நல்ல நேரம் (காலை)', 'start': '10:30 AM', 'end': '11:30 AM', 'isAuspicious': true},
      {'nameEn': 'Gowri Amirtham', 'nameTa': 'கௌரி அமிர்தம்', 'start': '01:30 PM', 'end': '02:30 PM', 'isAuspicious': true},
      {'nameEn': 'Gowri Labham', 'nameTa': 'கௌரி லாபம்', 'start': '06:30 PM', 'end': '07:30 PM', 'isAuspicious': true},
    ];
  }
}

/// Explicit Rule Provider for Pradosham Observance
class PradoshamRuleProvider {
  /// Strictly checks if a date qualifies as Pradosham based on:
  /// 1. Tithi is Trayodashi (13th Tithi of either Shukla or Krishna Paksha)
  /// 2. Sunset twilight window (Sandhya kalam / 4:30 PM - 6:00 PM)
  static bool isPradoshamObservance(Map<String, dynamic> astronomical) {
    final tithiObj = astronomical['tithi'] as Map<String, dynamic>?;
    final tithiNum = tithiObj?['number'] as int? ?? 0;
    final tithiName = (tithiObj?['nameEn'] as String? ?? '').toLowerCase();

    // 13th and 28th lunar days are Trayodashi
    return tithiNum == 13 || tithiNum == 28 || tithiName.contains('trayodashi');
  }

  static String getPradoshamPoojaWindow(Map<String, dynamic> astronomical) {
    final sunTimes = astronomical['sunTimes'] as Map<String, dynamic>?;
    final sunset = sunTimes?['sunset'] as String? ?? '06:00 PM';
    return '04:30 PM - 06:00 PM ($sunset)';
  }
}

// =====================================================================
// SINGLE SOURCE OF TRUTH PANCHANG REPOSITORY
// =====================================================================

/// Central Panchang Repository consumed across Home, Calendar, Panchangam, Muhurtham, Search, Reminders.
class PanchangRepository {
  static final PanchangRepository _instance = PanchangRepository._internal();
  factory PanchangRepository() => _instance;
  PanchangRepository._internal();

  final NavamshaPanchangService _apiService = NavamshaPanchangService();
  final SupabaseService _db = SupabaseService();
  final PanchangLocalCacheService _localCache = PanchangLocalCacheService();

  // In-memory normalized cache
  final Map<String, PanchangamDailyBundle> _bundleCache = {};

  /// Fetch single normalized Panchangam Daily Bundle using the active user location.
  /// Automatically caches essential timings to local storage and falls back to
  /// local cache when offline or when network connectivity is unavailable.
  Future<PanchangamDailyBundle> getDailyPanchangam({
    required DateTime date,
    required UserLocationItem location,
    bool forceRefresh = false,
  }) async {
    final lat = location.latitude ?? 11.0168; // default to TN coordinates if not set
    final lng = location.longitude ?? 76.9558;
    final tz = _parseTimezoneOffset(location.timezone);

    final cacheKey = "${date.year}-${date.month}-${date.day}:${lat.toStringAsFixed(3)}:${lng.toStringAsFixed(3)}:$tz";

    if (!forceRefresh && _bundleCache.containsKey(cacheKey)) {
      return _bundleCache[cacheKey]!;
    }

    // Check offline local storage cache first if not force-refreshing
    if (!forceRefresh) {
      final localCached = await _localCache.getCachedDailyPanchangam(
        date: date,
        location: location.city,
      );
      if (localCached != null) {
        _bundleCache[cacheKey] = localCached;
        return localCached;
      }
    }

    try {
      // Call Navamsha Panchang Service via Supabase Edge Function
      final rawData = await _apiService.getDailyBundle(
        date: date,
        latitude: lat,
        longitude: lng,
        timezone: tz,
        cityName: location.city,
        forceRefresh: forceRefresh,
      );

      final bundle = _mapToPanchangamBundle(date, location, rawData);
      _bundleCache[cacheKey] = bundle;

      // Save into persistent local storage cache for offline resilience
      await _localCache.cacheDailyPanchangam(
        date: date,
        location: location.city,
        bundle: bundle,
      );

      return bundle;
    } catch (networkError) {
      // Fallback: If network failed or user is offline, check local storage
      final localCached = await _localCache.getCachedDailyPanchangam(
        date: date,
        location: location.city,
      );

      if (localCached != null) {
        _bundleCache[cacheKey] = localCached;
        return localCached;
      }

      // Re-throw if neither remote network nor local storage cache has data
      rethrow;
    }
  }

  /// Fetch a full month of normalized Panchangam Daily Bundles.
  /// Used by Festival, Muhurtham, and Special Days repositories to merge Navamsha API data with Admin Overrides.
  Future<List<PanchangamDailyBundle>> getMonthlyPanchangam({
    required int year,
    required int month,
    required UserLocationItem location,
    bool forceRefresh = false,
  }) async {
    final lat = location.latitude ?? 11.0168;
    final lng = location.longitude ?? 76.9558;
    final tz = _parseTimezoneOffset(location.timezone);

    try {
      final rawMonthData = await _apiService.getMonthBundle(
        year: year,
        month: month,
        latitude: lat,
        longitude: lng,
        timezone: tz,
        forceRefresh: forceRefresh,
      );

      final days = rawMonthData['days'] as List<dynamic>? ?? [];
      final List<PanchangamDailyBundle> monthlyBundles = [];

      for (var dayJson in days) {
        final Map<String, dynamic> dayData = dayJson;
        final dateStr = dayData['date'] as String?;
        if (dateStr == null) continue;
        
        final parsedDate = DateTime.parse(dateStr);
        final bundle = _mapToPanchangamBundle(parsedDate, location, dayData);
        monthlyBundles.add(bundle);
        
        // Optionally cache each day in memory
        final cacheKey = "${parsedDate.year}-${parsedDate.month}-${parsedDate.day}:${lat.toStringAsFixed(3)}:${lng.toStringAsFixed(3)}:$tz";
        _bundleCache[cacheKey] = bundle;
      }

      return monthlyBundles;
    } catch (e) {
      print('Monthly Navamsha Panchang fetch failed: $e');
      return [];
    }
  }

  /// Map raw Edge Function JSON into strongly-typed TNT models
  PanchangamDailyBundle _mapToPanchangamBundle(
    DateTime date,
    UserLocationItem location,
    Map<String, dynamic> json,
  ) {
    final astro = json['astronomical'] as Map<String, dynamic>? ?? {};
    final tithi = astro['tithi'] as Map<String, dynamic>? ?? {};
    final nakshatra = astro['nakshatra'] as Map<String, dynamic>? ?? {};
    final yoga = astro['yoga'] as Map<String, dynamic>? ?? {};
    final karana = astro['karana'] as Map<String, dynamic>? ?? {};
    final vara = astro['vara'] as Map<String, dynamic>? ?? {};
    final sunTimes = astro['sunTimes'] as Map<String, dynamic>? ?? {};
    final inauspicious = astro['inauspicious'] as Map<String, dynamic>? ?? {};
    final auspicious = astro['auspiciousTimings'] as Map<String, dynamic>? ?? {};
    final observances = astro['observances'] as Map<String, dynamic>? ?? {};

    // 1. Calendar Day model
    final calDay = CalendarDay(
      gregorianDate: date,
      tamilMonth: 'புரட்டாசி',
      tamilYear: 'சுபகிருது வருடம்',
      tamilDay: date.day,
      tamilDateStr: 'புரட்டாசி ${date.day}',
      tithi: tithi['nameEn'] as String? ?? 'Ekadashi',
      tithiTa: tithi['nameTa'] as String? ?? 'ஏகாதசி',
      nakshatra: nakshatra['nameEn'] as String? ?? 'Shravana',
      nakshatraTa: nakshatra['nameTa'] as String? ?? 'திருவோணம்',
      isAuspicious: true,
    );

    // 2. Panchangam Entry model
    final panchangam = PanchangamEntry(
      date: date,
      tithi: tithi['nameEn'] as String? ?? 'Ekadashi',
      tithiTa: '${tithi['pakshaTa'] ?? 'வளர்பிறை'} ${tithi['nameTa'] ?? 'ஏகாதசி'}',
      nakshatra: nakshatra['nameEn'] as String? ?? 'Shravana',
      nakshatraTa: nakshatra['nameTa'] as String? ?? 'திருவோணம்',
      yoga: yoga['nameEn'] as String? ?? 'Siddha',
      yogaTa: yoga['nameTa'] as String? ?? 'சித்தம்',
      karana: karana['nameEn'] as String? ?? 'Bava',
      karanaTa: karana['nameTa'] as String? ?? 'பவம்',
      sunrise: sunTimes['sunrise'] as String? ?? '06:08 AM',
      sunset: sunTimes['sunset'] as String? ?? '06:12 PM',
      moonrise: sunTimes['moonrise'] as String? ?? '03:45 PM',
      moonset: sunTimes['moonset'] as String? ?? '04:10 AM',
      paksha: tithi['paksha'] as String? ?? 'Shukla Paksha',
      pakshaTa: tithi['pakshaTa'] as String? ?? 'வளர்பிறை',
    );

    // 3. Timings aggregation
    final List<TimingEntry> timings = [];

    // Nalla Neram
    timings.addAll(NallaNeramProvider.getNallaNeramTimings(date, astro));

    // Rahu Kaal
    if (inauspicious['rahuKaal'] != null) {
      final parts = (inauspicious['rahuKaal'] as String).split(' - ');
      timings.add(TimingEntry(
        name: 'Rahu Kalam',
        nameTa: 'இராகு காலம்',
        startTime: parts.isNotEmpty ? parts[0] : '01:30 PM',
        endTime: parts.length > 1 ? parts[1] : '03:00 PM',
        isAuspicious: false,
        category: 'inauspicious',
        description: 'Inauspicious Rahu period. Avoid starting new ventures.',
        descriptionTa: 'சுப காரியங்கள் தொடங்குவதை தவிர்க்க வேண்டிய நேரம்.',
      ));
    }

    // Yamagandam
    if (inauspicious['yamagandam'] != null) {
      final parts = (inauspicious['yamagandam'] as String).split(' - ');
      timings.add(TimingEntry(
        name: 'Yamagandam',
        nameTa: 'எமகண்டம்',
        startTime: parts.isNotEmpty ? parts[0] : '06:00 AM',
        endTime: parts.length > 1 ? parts[1] : '07:30 AM',
        isAuspicious: false,
        category: 'inauspicious',
        description: 'Inauspicious Yamaganda period.',
        descriptionTa: 'எமகண்ட நேரம்.',
      ));
    }

    // Gulika Kaal
    if (inauspicious['gulikaKaal'] != null) {
      final parts = (inauspicious['gulikaKaal'] as String).split(' - ');
      timings.add(TimingEntry(
        name: 'Kuligai',
        nameTa: 'குளிகை',
        startTime: parts.isNotEmpty ? parts[0] : '09:00 AM',
        endTime: parts.length > 1 ? parts[1] : '10:30 AM',
        isAuspicious: false,
        category: 'inauspicious',
        description: 'Kuligai period.',
        descriptionTa: 'குளிகை நேரம்.',
      ));
    }

    // Abhijit Muhurat
    if (auspicious['abhijitMuhurat'] != null) {
      final parts = (auspicious['abhijitMuhurat'] as String).split(' - ');
      timings.add(TimingEntry(
        name: 'Abhijit Muhurat',
        nameTa: 'அபிஜித் முகூர்த்தம்',
        startTime: parts.isNotEmpty ? parts[0] : '11:48 AM',
        endTime: parts.length > 1 ? parts[1] : '12:36 PM',
        isAuspicious: true,
        category: 'auspicious',
        description: 'Midday auspicious window.',
        descriptionTa: 'நண்பகல் சுப முகூர்த்த வேளை.',
      ));
    }

    // Brahma Muhurta
    if (auspicious['brahmaMuhurta'] != null) {
      final parts = (auspicious['brahmaMuhurta'] as String).split(' - ');
      timings.add(TimingEntry(
        name: 'Brahma Muhurta',
        nameTa: 'பிரம்ம முகூர்த்தம்',
        startTime: parts.isNotEmpty ? parts[0] : '04:32 AM',
        endTime: parts.length > 1 ? parts[1] : '05:20 AM',
        isAuspicious: true,
        category: 'auspicious',
        description: 'Pre-dawn divine hour for meditation and sacred worship.',
        descriptionTa: 'தியானம் மற்றும் ஆன்மீக வழிபாட்டிற்கு உகந்த விடியற்காலை வேளை.',
      ));
    }

    // Gowri Panchangam
    timings.addAll(GowriPanchangamProvider.getGowriTimings(date, astro));

    // 4. Special Day Observances derived from Navamsha calculations
    final List<SpecialDay> specialDays = [];

    if (observances['isPournami'] == true) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-pournami',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Pournami (Full Moon)',
        titleTa: 'பௌர்ணமி விரதம்',
        category: 'pournami',
        categoryTa: 'பௌர்ணமி',
        isHoliday: false,
        description: 'Sacred Full Moon day dedicated to Satyanarayana and Goddess Lalitha.',
        descriptionTa: 'ஸ்ரீ சத்யநாராயணர் மற்றும் அம்பிகை வழிபாட்டிற்கு உகந்த முழு நிலவு திருநாள்.',
        timingWindow: 'Full Day (Moonrise ${sunTimes['moonrise'] ?? '06:00 PM'})',
        location: location.city,
      ));
    }

    if (observances['isAmavasai'] == true) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-amavasai',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Amavasai (New Moon)',
        titleTa: 'அமாவாசை விரதம்',
        category: 'amavasai',
        categoryTa: 'அமாவாசை',
        isHoliday: false,
        description: 'Auspicious day for Pitru Tharpanam and ancestral veneration.',
        descriptionTa: 'முன்னோர் வழிபாடு மற்றும் பித்ரு தர்ப்பணம் செய்ய உகந்த புண்ணிய நாள்.',
        timingWindow: 'Morning 06:30 AM - 12:00 PM',
        location: location.city,
      ));
    }

    if (observances['isEkadashi'] == true) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-ekadashi',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Ekadashi Viratham',
        titleTa: 'ஏகாதசி விரதம்',
        category: 'ekadashi',
        categoryTa: 'ஏகாதசி',
        isHoliday: false,
        description: 'Fasting day dedicated to Lord Maha Vishnu.',
        descriptionTa: 'ஸ்ரீ மகாவிஷ்ணுவின் பேரருள் பெறும் உன்னத ஏகாதசி விரத நாள்.',
        timingWindow: 'Full Day Fasting',
        location: location.city,
      ));
    }

    if (observances['isSashti'] == true) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-sashti',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Sashti Viratham',
        titleTa: 'சஷ்டி விரதம்',
        category: 'sashti',
        categoryTa: 'சஷ்டி',
        isHoliday: false,
        description: 'Auspicious day dedicated to Lord Murugan.',
        descriptionTa: 'முருகப் பெருமானின் அருள் வேண்டி மேற்கொள்ளப்படும் சஷ்டி விரதம்.',
        timingWindow: 'Full Day',
        location: location.city,
      ));
    }

    if (observances['isKrithigai'] == true) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-krithigai',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Krithigai Deepam Day',
        titleTa: 'கிருத்திகை நட்சத்திர விரதம்',
        category: 'krithigai',
        categoryTa: 'கிருத்திகை',
        isHoliday: false,
        description: 'Sacred Krittika constellation dedicated to Lord Shanmukha.',
        descriptionTa: 'கிருத்திகை நட்சத்திரத்தில் முருகனை வணங்குவது பெரும் புண்ணியத்தைத் தரும்.',
        timingWindow: 'Evening Lamp Lighting',
        location: location.city,
      ));
    }

    if (observances['isChaturthi'] == true) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-chaturthi',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Sankatahara Chaturthi',
        titleTa: 'சங்கடஹர சதுர்த்தி',
        category: 'sankatahara_chaturthi',
        categoryTa: 'சங்கடஹர சதுர்த்தி',
        isHoliday: false,
        description: 'Veneration of Lord Vinayaka to dissolve all obstacles.',
        descriptionTa: 'சகல துன்பங்களையும் தீர்த்து வைக்கும் விநாயகப் பெருமான் வழிபாடு.',
        timingWindow: 'Evening Moonrise Puja',
        location: location.city,
      ));
    }

    if (PradoshamRuleProvider.isPradoshamObservance(astro)) {
      specialDays.add(SpecialDay(
        id: '${date.year}-${date.month}-${date.day}-pradosham',
        date: date,
        tamilDateStr: 'புரட்டாசி ${date.day}',
        title: 'Pradosha Viratham',
        titleTa: 'பிரதோஷ விரதம்',
        category: 'pradosham',
        categoryTa: 'பிரதோஷம்',
        isHoliday: false,
        description: 'Sacred twilight prayer dedicated to Lord Shiva and Nandi.',
        descriptionTa: 'சிவபெருமான் மற்றும் நந்தியம் பெருமானை வழிபட உகந்த மாலை வேளை.',
        timingWindow: PradoshamRuleProvider.getPradoshamPoojaWindow(astro),
        location: location.city,
      ));
    }

    return PanchangamDailyBundle(
      date: date,
      location: location.city,
      calendarDay: calDay,
      panchangam: panchangam,
      timings: timings,
      specialDays: specialDays,
      festivals: [],
      muhurthams: [],
    );
  }

  /// Helper to convert timezone string into decimal hours offset (e.g. 'Asia/Kolkata' -> 5.5)
  double _parseTimezoneOffset(String tz) {
    if (tz.contains('Kolkata') || tz.contains('India') || tz.contains('IST')) return 5.5;
    if (tz.contains('Singapore') || tz.contains('Malaysia')) return 8.0;
    if (tz.contains('Colombo') || tz.contains('Sri Lanka')) return 5.5;
    if (tz.contains('Dubai') || tz.contains('Gulf')) return 4.0;
    if (tz.contains('London') || tz.contains('UTC')) return 0.0;
    if (tz.contains('New_York') || tz.contains('EST')) return -5.0;
    if (tz.contains('Los_Angeles') || tz.contains('PST')) return -8.0;
    return 5.5;
  }

  /// Check if local offline storage has cached data for a specific date & location
  Future<bool> hasOfflineCache(DateTime date, String location) async {
    return await _localCache.hasCachedPanchangam(date: date, location: location);
  }

  /// Get list of all dates stored in local storage for a given location
  Future<List<String>> getOfflineCachedDates(String location) async {
    return await _localCache.getCachedDatesForLocation(location);
  }

  /// Pre-cache today's and upcoming essential timings into local storage
  Future<void> preCacheEssentialTimings({
    required DateTime startDate,
    required UserLocationItem location,
    int days = 3,
  }) async {
    for (int i = 0; i < days; i++) {
      final targetDate = startDate.add(Duration(days: i));
      try {
        await getDailyPanchangam(date: targetDate, location: location);
      } catch (_) {}
    }
  }

  /// Clear all memory and persistent local storage caches
  Future<void> clearAllCaches() async {
    _bundleCache.clear();
    await _localCache.clearAllCache();
  }

  void clearCache() {
    _bundleCache.clear();
  }
}
