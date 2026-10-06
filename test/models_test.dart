import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_tamil_calendar/models/tnt_models.dart';
import 'package:tnt_tamil_calendar/features/admin/analytics/models/admin_analytics_models.dart';
import 'package:tnt_tamil_calendar/features/admin/schedules/models/admin_schedule_models.dart';

void main() {
  group('TNT Core Models & Entity Validation', () {
    test('UserProfile parses USER and ADMIN roles correctly', () {
      final userJson = {
        'id': 'usr_1',
        'full_name': 'Murugan S',
        'email': 'user@example.com',
        'role': 'USER',
        'created_at': '2026-09-28T00:00:00Z',
      };
      final user = UserProfile.fromJson(userJson);
      expect(user.id, 'usr_1');
      expect(user.role, 'user');
      expect(user.fullName, 'Murugan S');

      final adminJson = {
        'id': 'adm_1',
        'full_name': 'Admin Gurukkal',
        'email': 'admin@tntcalendar.in',
        'role': 'ADMIN',
        'created_at': '2026-09-28T00:00:00Z',
      };
      final admin = UserProfile.fromJson(adminJson);
      expect(admin.role, 'admin');
    });

    test('AnalyticsSummary calculation and empty factory safety', () {
      final empty = AnalyticsSummary.empty();
      expect(empty.totalUsers, 0);
      expect(empty.activeUsers, 0);
      expect(empty.notificationOpenRate, 0.0);
      expect(empty.totalScreenViews, 0);
    });

    test('AnalyticsDateRange creates correct boundary timestamps in UTC', () {
      final today = AnalyticsDateRange.today();
      expect(today.type, AnalyticsDateFilterType.today);
      expect(today.startDate.isUtc, true);
      expect(today.endDate.isUtc, true);

      final last7Days = AnalyticsDateRange.last7Days();
      expect(last7Days.type, AnalyticsDateFilterType.last7Days);
      expect(last7Days.endDate.isAfter(last7Days.startDate), true);
    });

    test('AdminScheduleItem serializes and deserializes accurately', () {
      final item = AdminScheduleItem(
        id: 'sched_1',
        title: 'Marriage Verification Task',
        description: 'Verify muhurtham astrological charts',
        scheduleDate: '2026-10-15',
        startTime: '10:00 AM',
        endTime: '11:30 AM',
        category: 'VERIFICATION',
        priority: 'HIGH',
        status: 'SCHEDULED',
        mandapam: 'Madurai East Zone',
        marriageDetails: 'Vaikasi Valarpirai',
        internalNotes: 'Strictly confidential to admin committee',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['title'], 'Marriage Verification Task');
      expect(json['internal_notes'], 'Strictly confidential to admin committee');
      expect(json['category'], 'VERIFICATION');

      final deserialized = AdminScheduleItem.fromJson(json);
      expect(deserialized.id, 'sched_1');
      expect(deserialized.priority, 'HIGH');
      expect(deserialized.status, 'SCHEDULED');
    });

    test('AutomatedCronJob tracks status and execution metrics', () {
      final job = AutomatedCronJob(
        id: 'job_panchangam',
        name: 'Panchangam Astronomical Precompute',
        frequency: 'Daily @ 00:05 AM IST',
        cronExpression: '5 18 * * *',
        description: 'Precomputes 60 days Sunrise, Sunset, Tithi',
        status: 'IDLE',
      );

      expect(job.status, 'IDLE');
      final updated = job.copyWith(
        status: 'SUCCESS',
        durationMs: 240,
        lastLogMessage: 'Indexed 60 days successfully',
      );

      expect(updated.status, 'SUCCESS');
      expect(updated.durationMs, 240);
      expect(updated.lastLogMessage, 'Indexed 60 days successfully');
    });
  });
}
