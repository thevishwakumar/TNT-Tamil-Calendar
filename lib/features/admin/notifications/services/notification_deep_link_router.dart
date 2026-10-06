import 'package:tnt_tamil_calendar/services/production_api_service.dart';
import 'package:flutter/material.dart';
import '../../../../calendar/screens/date_details_screen.dart';
import '../../../../festivals/screens/festival_detail_screen.dart';
import '../../../../muhurtham/screens/muhurtham_detail_screen.dart';
import '../../../../panchangam/screens/panchangam_screen.dart';
import '../../../../reminders/screens/reminders_screen.dart';
import '../../../../services/supabase_service.dart';
import '../../../../special_days/screens/special_day_detail_screen.dart';

/// Notification Deep Link Payload Model
class NotificationDeepLinkPayload {
  final String rawUri;
  final String scheme;
  final String path;
  final Map<String, String> queryParameters;

  NotificationDeepLinkPayload({
    required this.rawUri,
    required this.scheme,
    required this.path,
    required this.queryParameters,
  });

  factory NotificationDeepLinkPayload.parse(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      return NotificationDeepLinkPayload(
        rawUri: uriString,
        scheme: uri.scheme.isNotEmpty ? uri.scheme : 'tnt',
        path: uri.host.isNotEmpty ? uri.host + uri.path : uri.path,
        queryParameters: uri.queryParameters,
      );
    } catch (_) {
      return NotificationDeepLinkPayload(
        rawUri: uriString,
        scheme: 'tnt',
        path: uriString,
        queryParameters: {},
      );
    }
  }
}

/// Centralized Notification Deep Link Router
/// Safely routes notification payload clicks to exact feature screens.
class NotificationDeepLinkRouter {
  static final NotificationDeepLinkRouter _instance = NotificationDeepLinkRouter._internal();
  factory NotificationDeepLinkRouter() => _instance;
  NotificationDeepLinkRouter._internal();

  /// Presets available in Admin Campaign Creator
  static const List<Map<String, String>> presetDeepLinks = [
    {
      'label': 'Today Panchangam',
      'uri': 'tnt://panchangam',
      'category': 'PANCHANGAM',
    },
    {
      'label': 'Upcoming Auspicious Muhurtham',
      'uri': 'tnt://muhurtham',
      'category': 'MUHURTHAM',
    },
    {
      'label': 'Navaratri Festival Details',
      'uri': 'tnt://festival/fest-001',
      'category': 'FESTIVAL',
    },
    {
      'label': 'Pradosham Observance Details',
      'uri': 'tnt://special_day/sp-003',
      'category': 'SPECIAL_DAY',
    },
    {
      'label': 'User Reminders Hub',
      'uri': 'tnt://reminders',
      'category': 'REMINDER',
    },
    {
      'label': 'Important Tamil Calendar Updates',
      'uri': 'tnt://calendar',
      'category': 'IMPORTANT_UPDATE',
    },
    {
      'label': 'Special Mandapam & Marriage Guide',
      'uri': 'tnt://marketing/promo-marriage-guide',
      'category': 'MARKETING',
    },
  ];

  /// Handles incoming deep link navigation safely
  Future<bool> handleDeepLink(BuildContext context, String? deepLinkUri, {ITNTApiService? apiService}) async {
    if (deepLinkUri == null || deepLinkUri.trim().isEmpty) {
      return false;
    }

    final api = apiService ?? SupabaseApiService();
    final parsed = NotificationDeepLinkPayload.parse(deepLinkUri);
    final path = parsed.path.toLowerCase();

    try {
      if (path.contains('panchangam')) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PanchangamScreen(apiService: api)),
        );
        return true;
      }

      if (path.contains('muhurtham')) {
        final id = parsed.queryParameters['id'] ?? (path.contains('/') ? path.split('/').last : '');
        final dates = await api.getMarriageMuhurthams(DateTime.now().year, DateTime.now().month);
        final selected = dates.isNotEmpty ? dates.first : null;
        if (selected != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MuhurthamDetailScreen(muhurtham: selected, apiService: api),
            ),
          );
          return true;
        }
      }

      if (path.contains('festival')) {
        final festivals = await api.getFestivals(DateTime.now().year, DateTime.now().month);
        final selected = festivals.isNotEmpty ? festivals.first : null;
        if (selected != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FestivalDetailScreen(festival: selected, apiService: api),
            ),
          );
          return true;
        }
      }

      if (path.contains('special_day')) {
        final specialDays = await api.getSpecialDays(DateTime.now().year, DateTime.now().month);
        final selected = specialDays.isNotEmpty ? specialDays.first : null;
        if (selected != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SpecialDayDetailScreen(specialDay: selected, apiService: api),
            ),
          );
          return true;
        }
      }

      if (path.contains('reminders')) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RemindersScreen(apiService: api)),
        );
        return true;
      }

      // Default fallback: open Date Details for today
      final todayDay = await api.getCalendarDay(DateTime.now());
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DateDetailsScreen(date: DateTime.now(), apiService: api)),
        );
        return true;
      }
    } catch (_) {
      return false;
    }

    return false;
  }
}
