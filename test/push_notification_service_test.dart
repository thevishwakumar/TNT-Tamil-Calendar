import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_tamil_calendar/services/push_notification_service.dart';
import 'package:tnt_tamil_calendar/models/tnt_models.dart';
import 'package:tnt_tamil_calendar/features/admin/notifications/services/notification_deep_link_router.dart';

void main() {
  group('PushNotificationService Unit Tests', () {
    test('PushNotificationService adheres to strict singleton pattern', () {
      final s1 = PushNotificationService();
      final s2 = PushNotificationService();
      expect(identical(s1, s2), isTrue);
    });

    test('Initial push notification state defaults correctly', () {
      final service = PushNotificationService();
      expect(service.fcmToken, isNull);
    });

    test('NotificationDeepLinkPayload parses valid and fallback URIs safely',
        () {
      final payload =
          NotificationDeepLinkPayload.parse('tnt://panchangam?date=2026-10-10');
      expect(payload.scheme, 'tnt');
      expect(payload.path, 'panchangam');
      expect(payload.queryParameters['date'], '2026-10-10');

      final fallback =
          NotificationDeepLinkPayload.parse('invalid uri without scheme');
      expect(fallback.scheme, 'tnt');
      expect(fallback.path, 'invalid%20uri%20without%20scheme');
    });

    test('NotificationDeepLinkRouter contains standard presets', () {
      expect(NotificationDeepLinkRouter.presetDeepLinks.isNotEmpty, isTrue);
      final categories = NotificationDeepLinkRouter.presetDeepLinks
          .map((p) => p['category'])
          .toSet();
      expect(categories.contains('PANCHANGAM'), isTrue);
      expect(categories.contains('MUHURTHAM'), isTrue);
      expect(categories.contains('FESTIVAL'), isTrue);
    });
  });
}
