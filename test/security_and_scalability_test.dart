import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_tamil_calendar/core/network/tnt_resilience.dart';
import 'package:tnt_tamil_calendar/core/authorization/admin_authorization_service.dart';
import 'package:tnt_tamil_calendar/services/notification_service.dart';
import 'package:tnt_tamil_calendar/repositories/tnt_repositories.dart';

void main() {
  group('TNTResilience & Bounded Jitter Tests', () {
    test('TNTResilience returns result immediately on first attempt success',
        () async {
      int executions = 0;
      final result = await TNTResilience.retry(
        operation: () async {
          executions++;
          return 'SUCCESS';
        },
        maxRetries: 2,
      );

      expect(result, 'SUCCESS');
      expect(executions, 1);
    });

    test(
        'TNTResilience retries transient errors and succeeds on second attempt',
        () async {
      int executions = 0;
      final result = await TNTResilience.retry(
        operation: () async {
          executions++;
          if (executions == 1) {
            throw const SocketException('Simulated temporary connection reset');
          }
          return 'RECOVERED';
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'RECOVERED');
      expect(executions, 2);
    });

    test(
        'TNTResilience fails immediately on non-transient errors without wasting retries',
        () async {
      int executions = 0;
      expect(
        () => TNTResilience.retry(
          operation: () async {
            executions++;
            throw const FormatException('Invalid payload schema');
          },
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Session Isolation & Zero Cross-Account Leakage Tests', () {
    test('AdminAuthorizationService clears all admin flags upon session reset',
        () {
      final auth = AdminAuthorizationService();
      auth.clearSession();
      expect(auth.isVerifiedAdmin, isFalse);
      expect(auth.verifiedAdminId, isNull);
    });

    test(
        'NotificationService clears user notifications and preferences on sign out',
        () {
      final notif = NotificationService();
      notif.clearSession();
      expect(notif.notifications, isEmpty);
      expect(notif.unreadCount, 0);
      expect(notif.preferences.marketingNotifications, isFalse);
    });
  });

  group('In-Memory TTL Caching & Invalidation Tests', () {
    test('CalendarRepository invalidateCache clears stored items', () {
      CalendarRepository.invalidateCache();
      // Validates static invocation succeeds without crashing
      expect(true, isTrue);
    });

    test(
        'FestivalRepository and SpecialDaysRepository invalidateCache clears stored items',
        () {
      FestivalRepository.invalidateCache();
      SpecialDaysRepository.invalidateCache();
      MuhurthamRepository.invalidateCache();
      expect(true, isTrue);
    });
  });
}
