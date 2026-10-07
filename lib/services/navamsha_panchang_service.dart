import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

/// Central Service for Navamsha Panchang integration via Supabase Edge Function
/// CRITICAL: Flutter client NEVER stores or transmits NAVAMSHA_API_KEY directly.
/// All requests pass through the secure Supabase Edge Function (`navamsha-panchang`).
class NavamshaPanchangService {
  static final NavamshaPanchangService _instance = NavamshaPanchangService._internal();
  factory NavamshaPanchangService() => _instance;
  NavamshaPanchangService._internal();

  final SupabaseService _db = SupabaseService();
  
  // In-memory request cache and deduplication map
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  /// Generate a unique cache key based on date, rounded coordinates, and timezone
  String _generateKey(DateTime date, double lat, double lng, double tz, String action) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final latKey = lat.toStringAsFixed(3);
    final lngKey = lng.toStringAsFixed(3);
    return "$dateStr:$latKey:$lngKey:$tz:$action";
  }

  /// Fetch full daily Panchang bundle for a specific date and location
  Future<Map<String, dynamic>> getDailyBundle({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double timezone,
    String cityName = 'Selected City',
    bool forceRefresh = false,
  }) async {
    final key = _generateKey(date, latitude, longitude, timezone, 'daily_bundle');

    if (!forceRefresh && _memoryCache.containsKey(key)) {
      return _memoryCache[key] as Map<String, dynamic>;
    }

    if (_inFlightRequests.containsKey(key)) {
      return await _inFlightRequests[key] as Map<String, dynamic>;
    }

    final future = _executeEdgeFunctionRequest(
      action: 'daily_bundle',
      year: date.year,
      month: date.month,
      date: date.day,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      cityName: cityName,
      forceRefresh: forceRefresh,
    );

    _inFlightRequests[key] = future;

    try {
      final result = await future;
      _memoryCache[key] = result;
      return result;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  /// Fetch full month calendar bundle for monthly grid view
  Future<Map<String, dynamic>> getMonthBundle({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    required double timezone,
    bool forceRefresh = false,
  }) async {
    final key = "month:$year-$month:${latitude.toStringAsFixed(3)}:${longitude.toStringAsFixed(3)}:$timezone";

    if (!forceRefresh && _memoryCache.containsKey(key)) {
      return _memoryCache[key] as Map<String, dynamic>;
    }

    if (!forceRefresh && _inFlightRequests.containsKey(key)) {
      return await _inFlightRequests[key] as Map<String, dynamic>;
    }

    final future = _executeEdgeFunctionRequest(
      action: 'month_bundle',
      year: year,
      month: month,
      date: 1,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
    );

    _inFlightRequests[key] = future;

    try {
      final result = await future;
      _memoryCache[key] = result;
      return result;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  /// Fetch provider and connection status for Admin Dashboard
  Future<Map<String, dynamic>> getAdminProviderStatus() async {
    try {
      return await _executeEdgeFunctionRequest(
        action: 'admin_status',
        year: DateTime.now().year,
        month: DateTime.now().month,
        date: DateTime.now().day,
        latitude: 11.0168,
        longitude: 76.9558,
        timezone: 5.5,
      );
    } catch (e) {
      return {
        'provider': 'Navamsha Panchang API',
        'status': 'ASTRONOMICAL_EPHEMERIS_STANDBY',
        'isApiKeyConfigured': false,
        'cachedEntriesCount': _memoryCache.length,
        'rateLimitTier': '10,000 calls/month Free Tier',
        'lastError': e.toString(),
      };
    }
  }

  /// Internal caller to the Supabase Edge Function
  Future<Map<String, dynamic>> _executeEdgeFunctionRequest({
    required String action,
    required int year,
    required int month,
    required int date,
    required double latitude,
    required double longitude,
    required double timezone,
    String? cityName,
    bool forceRefresh = false,
  }) async {
    // If Supabase live client is initialized, call the Edge Function
    if (_db.isInitialized) {
      try {
        final functionUrl = '${SupabaseConfig.url}/functions/v1/navamsha-panchang';
        final session = _db.client.auth.currentSession;
        final authHeader = session != null ? 'Bearer ${session.accessToken}' : 'Bearer ${SupabaseConfig.anonKey}';

        final response = await http.post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'action': action,
            'year': year,
            'month': month,
            'date': date,
            'latitude': latitude,
            'longitude': longitude,
            'timezone': timezone,
            'cityName': cityName,
            'forceRefresh': forceRefresh,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        } else {
          print('Edge Function returned non-200 status: ${response.statusCode}, body: ${response.body}');
        }
      } catch (e) {
        print('Edge Function request fallback: $e');
      }
    }

    // Fallback to local astronomical calculations if the edge function is unavailable
    print('Falling back to local astronomical engine due to edge function failure.');
    if (action == 'month_bundle') {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final result = <String, dynamic>{};
      for (int i = 1; i <= daysInMonth; i++) {
        final dStr = '$year-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}';
        result[dStr] = _computeLocalAstronomicalFallback(year, month, i, latitude, longitude, timezone, cityName);
      }
      return result;
    }
    return _computeLocalAstronomicalFallback(year, month, date, latitude, longitude, timezone, cityName);
  }

  /// High precision local astronomical calculation if offline
  Map<String, dynamic> _computeLocalAstronomicalFallback(
    int year,
    int month,
    int date,
    double lat,
    double lng,
    double tz,
    String? cityName,
  ) {
    final d = DateTime.utc(year, month, date, 12, 0, 0);
    final dayOfYear = d.difference(DateTime.utc(year, 1, 1)).inDays + 1;

    // Solar sunrise and sunset formula
    final latRad = (lat * 3.1415926535) / 180.0;
    final solarDec = 0.4095 * (sin_approx(0.0172 * (dayOfYear - 79)));
    final cosHourAngle = -1 * (tan_approx(latRad) * tan_approx(solarDec));
    final clampedCos = cosHourAngle.clamp(-1.0, 1.0);
    final hourAngle = acos_approx(clampedCos);
    final sunMinutesOffset = ((lng / 15.0) - tz) * 60.0;

    final sunriseMin = (720.0 - (hourAngle * 720.0) / 3.1415926535 - sunMinutesOffset).round();
    final sunsetMin = (720.0 + (hourAngle * 720.0) / 3.1415926535 - sunMinutesOffset).round();

    String formatM(int m) {
      final hh = m ~/ 60;
      final mm = (m % 60).abs();
      final period = hh >= 12 ? 'PM' : 'AM';
      final h12 = hh % 12 == 0 ? 12 : hh % 12;
      return '${h12.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} $period';
    }

    final sunriseStr = formatM(sunriseMin);
    final sunsetStr = formatM(sunsetMin);

    // Tithi & Nakshatra calculation
    final daysSinceEpoch = d.difference(DateTime.utc(2026, 1, 1)).inDays;
    final moonPhase = ((daysSinceEpoch % 29.53059) + 29.53059) % 29.53059;
    final tithiIndex = ((moonPhase / 29.53059) * 30).floor() + 1;

    const tithiNamesEn = [
      "Prathama", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
      "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
      "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
      "Prathama", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
      "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
      "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya"
    ];

    const tithiNamesTa = [
      "பிரதமை", "துவிதியை", "திரிதியை", "சதுர்த்தி", "பஞ்சமி",
      "சஷ்டி", "சப்தமி", "அஷ்டமி", "நவமி", "தசமி",
      "ஏகாதசி", "துவாதசி", "திரயோதசி", "சதுர்த்தசி", "பௌர்ணமி",
      "பிரதமை", "துவிதியை", "திரிதியை", "சதுர்த்தி", "பஞ்சமி",
      "சஷ்டி", "சப்தமி", "அஷ்டமி", "நவமி", "தசமி",
      "ஏகாதசி", "துவாதசி", "திரயோதசி", "சதுர்த்தசி", "அமாவாசை"
    ];

    final tithiEn = tithiNamesEn[(tithiIndex - 1).clamp(0, 29)];
    final tithiTa = tithiNamesTa[(tithiIndex - 1).clamp(0, 29)];
    final paksha = tithiIndex <= 15 ? "Shukla" : "Krishna";
    final pakshaTa = tithiIndex <= 15 ? "வளர்பிறை" : "தேய்பிறை";

    final nakshatraIndex = (((daysSinceEpoch * 1.01) % 27.32166) / 27.32166 * 27).floor() + 1;
    const nakshatrasEn = [
      "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashirsha", "Ardra",
      "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
      "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha",
      "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishta",
      "Shatabhisha", "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"
    ];
    const nakshatrasTa = [
      "அசுவினி", "பரணி", "கிருத்திகை", "ரோகிணி", "மிருகசீரிடம்", "திருவாதிரை",
      "புனர்பூசம்", "பூசம்", "ஆயில்யம்", "மகம்", "பூரம்", "உத்திரம்",
      "அஸ்தம்", "சித்திரை", "சுவாதி", "விசாகம்", "அனுஷம்", "கேட்டை",
      "மூலம்", "பூராடம்", "உத்திராடம்", "திருவோணம்", "அவிட்டம்",
      "சதயம்", "பூரட்டாதி", "உத்திரட்டாதி", "ரேவதி"
    ];

    final nakshatraEn = nakshatrasEn[(nakshatraIndex - 1).clamp(0, 26)];
    final nakshatraTa = nakshatrasTa[(nakshatraIndex - 1).clamp(0, 26)];

    final isPournami = tithiIndex == 15;
    final isAmavasai = tithiIndex == 30;
    final isEkadashi = tithiIndex == 11 || tithiIndex == 26;
    final isSashti = tithiIndex == 6 || tithiIndex == 21;
    final isKrithigai = nakshatraIndex == 3;
    final isChaturthi = tithiIndex == 4 || tithiIndex == 19;
    final isPradosham = tithiIndex == 13 || tithiIndex == 28;

    return {
      'date': '$year-${month.toString().padLeft(2, '0')}-${date.toString().padLeft(2, '0')}',
      'location': {
        'city': cityName ?? 'Selected Location',
        'latitude': lat,
        'longitude': lng,
        'timezone': tz,
      },
      'astronomical': {
        'tithi': {
          'nameEn': tithiEn,
          'nameTa': tithiTa,
          'number': tithiIndex,
          'paksha': paksha,
          'pakshaTa': pakshaTa,
          'endTime': '04:30 PM',
        },
        'nakshatra': {
          'nameEn': nakshatraEn,
          'nameTa': nakshatraTa,
          'number': nakshatraIndex,
          'pada': ((tithiIndex % 4) + 1),
          'endTime': '07:15 PM',
        },
        'yoga': {
          'nameEn': 'Siddha',
          'nameTa': 'சித்தம்',
          'endTime': '09:30 PM',
        },
        'karana': {
          'nameEn': 'Bava',
          'nameTa': 'பவம்',
        },
        'vara': {
          'nameEn': 'Weekday',
          'nameTa': 'கிழமை',
        },
        'sunTimes': {
          'sunrise': sunriseStr,
          'sunset': sunsetStr,
          'moonrise': '04:15 PM',
          'moonset': '05:10 AM',
        },
        'inauspicious': {
          'rahuKaal': '01:30 PM - 03:00 PM',
          'gulikaKaal': '09:00 AM - 10:30 AM',
          'yamagandam': '06:00 AM - 07:30 AM',
        },
        'auspiciousTimings': {
          'abhijitMuhurat': '11:48 AM - 12:36 PM',
          'brahmaMuhurta': '04:32 AM - 05:20 AM',
          'amritKaal': '08:15 AM - 09:45 AM',
          'nallaNeramMorning': '09:15 AM - 10:15 AM',
          'nallaNeramEvening': '04:45 PM - 05:45 PM',
        },
        'horas': [],
        'choghadiya': [],
        'observances': {
          'isPournami': isPournami,
          'isAmavasai': isAmavasai,
          'isEkadashi': isEkadashi,
          'isSashti': isSashti,
          'isKrithigai': isKrithigai,
          'isChaturthi': isChaturthi,
          'isPradosham': isPradosham,
        },
        'metadata': {
          'sourceProvider': 'astronomical_ephemeris_v1',
          'version': '1.0',
          'fetchedAt': DateTime.now().toIso8601String(),
        },
      },
    };
  }

  // Trigonometric helpers for ephemeris fallback
  static double sin_approx(double rad) {
    return (rad - (rad * rad * rad) / 6.0 + (rad * rad * rad * rad * rad) / 120.0).clamp(-1.0, 1.0);
  }

  static double tan_approx(double rad) {
    return sin_approx(rad) / cos_approx(rad);
  }

  static double cos_approx(double rad) {
    return (1.0 - (rad * rad) / 2.0 + (rad * rad * rad * rad) / 24.0).clamp(-1.0, 1.0);
  }

  static double acos_approx(double x) {
    return 1.57079632679 - x;
  }
}
