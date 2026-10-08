import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_tamil_calendar/models/tnt_models.dart';
import 'package:tnt_tamil_calendar/repositories/panchang_repository.dart';
import 'package:tnt_tamil_calendar/services/navamsha_panchang_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Panchangam Offline Mathematical Computation Tests', () {
    final navamshaService = NavamshaPanchangService();
    final panchangRepo = PanchangRepository();

    test('Computes solar sunrise and sunset mathematically for Tamil Nadu coordinates', () {
      final date = DateTime(2026, 10, 8);
      final fallback = navamshaService.computeLocalAstronomicalFallback(
        year: date.year,
        month: date.month,
        date: date.day,
        latitude: 13.0827, // Chennai
        longitude: 80.2707,
        timezone: 5.5,
        cityName: 'Chennai',
      );

      final sunTimes = fallback['astronomical']['sunTimes'] as Map<String, dynamic>;
      expect(sunTimes['sunrise'], isNotEmpty);
      expect(sunTimes['sunset'], isNotEmpty);
      expect(sunTimes['sunrise'], contains('AM'));
      expect(sunTimes['sunset'], contains('PM'));
      expect(sunTimes['dayDuration'], isNotEmpty);
      expect(sunTimes['nightDuration'], isNotEmpty);
    });

    test('Computes weekday-accurate Rahu Kalam, Yamagandam, Gulika Kaal and Nalla Neram', () {
      // Test Monday (Weekday 1)
      final monday = DateTime(2026, 10, 5); // Monday
      expect(monday.weekday, equals(DateTime.monday));

      final monFallback = navamshaService.computeLocalAstronomicalFallback(
        year: monday.year,
        month: monday.month,
        date: monday.day,
        latitude: 11.0168,
        longitude: 76.9558,
        timezone: 5.5,
      );

      final monInauspicious = monFallback['astronomical']['inauspicious'] as Map<String, dynamic>;
      final monAuspicious = monFallback['astronomical']['auspiciousTimings'] as Map<String, dynamic>;

      // Monday Rahu Kaal: 07:30 AM - 09:00 AM
      expect(monInauspicious['rahuKaal'], equals('07:30 AM - 09:00 AM'));
      // Monday Yamagandam: 10:30 AM - 12:00 PM
      expect(monInauspicious['yamagandam'], equals('10:30 AM - 12:00 PM'));
      // Monday Nalla Neram Morning: 06:15 AM - 07:15 AM
      expect(monAuspicious['nallaNeramMorning'], equals('06:15 AM - 07:15 AM'));

      // Test Thursday (Weekday 4)
      final thursday = DateTime(2026, 10, 8); // Thursday
      expect(thursday.weekday, equals(DateTime.thursday));

      final thuFallback = navamshaService.computeLocalAstronomicalFallback(
        year: thursday.year,
        month: thursday.month,
        date: thursday.day,
        latitude: 11.0168,
        longitude: 76.9558,
        timezone: 5.5,
      );

      final thuInauspicious = thuFallback['astronomical']['inauspicious'] as Map<String, dynamic>;
      final thuAuspicious = thuFallback['astronomical']['auspiciousTimings'] as Map<String, dynamic>;

      // Thursday Rahu Kaal: 01:30 PM - 03:00 PM
      expect(thuInauspicious['rahuKaal'], equals('01:30 PM - 03:00 PM'));
      // Thursday Yamagandam: 06:00 AM - 07:30 AM
      expect(thuInauspicious['yamagandam'], equals('06:00 AM - 07:30 AM'));
      // Thursday Nalla Neram Morning: 09:15 AM - 10:15 AM
      expect(thuAuspicious['nallaNeramMorning'], equals('09:15 AM - 10:15 AM'));
    });

    test('Computes dynamic Tamil Date (Month, Day, Year) correctly', () {
      final oct8 = DateTime(2026, 10, 8);
      final tamilOct8 = PanchangRepository.computeTamilDate(oct8);
      expect(tamilOct8['tamilMonth'], equals('புரட்டாசி'));
      expect(tamilOct8['tamilDay'], equals(22));
      expect(tamilOct8['tamilYear'], contains('வருடம்'));
      expect(tamilOct8['tamilDateStr'], equals('புரட்டாசி 22'));

      final apr14 = DateTime(2026, 4, 14);
      final tamilApr14 = PanchangRepository.computeTamilDate(apr14);
      expect(tamilApr14['tamilMonth'], equals('சித்திரை'));
      expect(tamilApr14['tamilDay'], equals(1));
      expect(tamilApr14['tamilDateStr'], equals('சித்திரை 1'));

      final jan15 = DateTime(2026, 1, 15);
      final tamilJan15 = PanchangRepository.computeTamilDate(jan15);
      expect(tamilJan15['tamilMonth'], equals('தை'));
      expect(tamilJan15['tamilDay'], equals(2));
      expect(tamilJan15['tamilDateStr'], equals('தை 2'));
    });

    test('Panchangam mapToPanchangamBundle creates a complete bundle with all timings', () {
      final date = DateTime(2026, 10, 8);
      final loc = UserLocationItem(
        id: 'loc-coimbatore',
        userId: 'test-user',
        name: 'Coimbatore',
        city: 'Coimbatore',
        timezone: 'Asia/Kolkata',
        latitude: 11.0168,
        longitude: 76.9558,
        createdAt: DateTime.now(),
      );

      final mathData = navamshaService.computeLocalAstronomicalFallback(
        year: date.year,
        month: date.month,
        date: date.day,
        latitude: 11.0168,
        longitude: 76.9558,
        timezone: 5.5,
        cityName: 'Coimbatore',
      );

      final bundle = panchangRepo.mapToPanchangamBundle(date, loc, mathData, isOffline: true);

      expect(bundle.isFromOfflineCache, isTrue);
      expect(bundle.panchangam.sunrise, isNotEmpty);
      expect(bundle.panchangam.sunset, isNotEmpty);
      expect(bundle.panchangam.tithi, isNotEmpty);
      expect(bundle.panchangam.nakshatra, isNotEmpty);
      expect(bundle.calendarDay.tamilMonth, equals('புரட்டாசி'));
      expect(bundle.calendarDay.tamilDateStr, equals('புரட்டாசி 22'));

      // Check Timings contain Nalla Neram, Rahu Kalam, Yamagandam, Kuligai, etc.
      final timingCategories = bundle.timings.map((t) => t.category).toSet();
      expect(timingCategories, contains('nalla_neram'));
      expect(timingCategories, contains('inauspicious'));
      expect(timingCategories, contains('auspicious'));
      expect(bundle.timings.any((t) => t.name.contains('Nalla Neram')), isTrue);
      expect(bundle.timings.any((t) => t.name.contains('Rahu Kalam')), isTrue);
      expect(bundle.timings.any((t) => t.name.contains('Yamagandam')), isTrue);
      expect(bundle.timings.any((t) => t.name.contains('Kuligai')), isTrue);
    });

    test('getDailyPanchangam does NOT throw and returns fallback bundle when offline', () async {
      final date = DateTime(2026, 12, 1);
      final loc = UserLocationItem(
        id: 'loc-test',
        userId: 'test-user',
        name: 'Madurai',
        city: 'Madurai',
        timezone: 'Asia/Kolkata',
        latitude: 9.9252,
        longitude: 78.1198,
        createdAt: DateTime.now(),
      );

      // Force refresh on uncached date - Edge function will fail/timeout or offline fallback
      final bundle = await panchangRepo.getDailyPanchangam(date: date, location: loc, forceRefresh: true);

      expect(bundle, isNotNull);
      expect(bundle.panchangam.sunrise, isNotEmpty);
      expect(bundle.panchangam.sunset, isNotEmpty);
      expect(bundle.timings, isNotEmpty);
      expect(bundle.calendarDay.tamilMonth, isNotEmpty);
    });
  });
}
