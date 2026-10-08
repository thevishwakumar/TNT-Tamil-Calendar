import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../models/admin_analytics_models.dart';

class AdminAnalyticsRepository {
  final SupabaseClient? _client;

  AdminAnalyticsRepository({SupabaseClient? client})
      : _client = client;

  /// Fetches comprehensive analytics summary for a given date range
  Future<AnalyticsSummary> getSummary(AnalyticsDateRange range) async {
    final client = _client ?? SupabaseService().client;

    try {
      final startIso = range.startDate.toIso8601String();
      final endIso = range.endDate.toIso8601String();

      // 1. Total & New users from profiles
      final totalUsersRes = await client.from('profiles').select('id, created_at'); // DEPRECATED for total count
      final totalUsersList = (totalUsersRes as List?) ?? [];
      final totalUsers = totalUsersList.length;

      int newUsers = 0;
      for (final u in totalUsersList) {
        final createdAtStr = u['created_at']?.toString();
        if (createdAtStr != null) {
          final cDate = DateTime.tryParse(createdAtStr);
          if (cDate != null &&
              cDate.isAfter(range.startDate) &&
              cDate.isBefore(range.endDate)) {
            newUsers++;
          }
        }
      }

      // 2. Events & views from analytics_events
      final eventsRes = await client
          .from('analytics_events')
          .select('id, event_name, created_at, user_id')
          .gte('created_at', startIso)
          .lte('created_at', endIso);

      final eventsList = (eventsRes as List?) ?? [];
      int calendarViews = 0;
      int panchangamViews = 0;
      int muhurthamViews = 0;
      int festivalViews = 0;
      int specialDayViews = 0;
      int posterViews = 0;
      int shares = 0;
      final Set<String> activeUserIds = {};

      for (final event in eventsList) {
        final name = event['event_name']?.toString() ?? '';
        final uid = event['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          activeUserIds.add(uid);
        }

        if (name.contains('calendar')) {
          calendarViews++;
        } else if (name.contains('panchangam')) panchangamViews++;
        else if (name.contains('muhurtham')) muhurthamViews++;
        else if (name.contains('festival')) festivalViews++;
        else if (name.contains('special_day')) specialDayViews++;
        else if (name.contains('poster') || name.contains('content')) posterViews++;
        else if (name.contains('share')) shares++;
      }

      final activeUsers = activeUserIds.length;
      final returningUsers = (activeUsers - newUsers) > 0 ? (activeUsers - newUsers) : 0;
      final totalScreenViews = calendarViews + panchangamViews + muhurthamViews + festivalViews + specialDayViews + posterViews;

      // 3. Notification metrics from notification_campaigns and notification_logs
      final campaignsRes = await client
          .from('notification_campaigns')
          .select('id, total_delivered, total_opened, created_at')
          .gte('created_at', startIso)
          .lte('created_at', endIso);

      final campaignsList = (campaignsRes as List?) ?? [];
      int totalDelivered = 0;
      int totalOpened = 0;
      for (final c in campaignsList) {
        totalDelivered += (c['total_delivered'] as num?)?.toInt() ?? 0;
        totalOpened += (c['total_opened'] as num?)?.toInt() ?? 0;
      }

      final double openRate = totalDelivered > 0 ? (totalOpened / totalDelivered) * 100 : 0.0;

      // 4. Saved items & Reminders counts
      final savedRes = await client.from('user_saved_items').select('id').count(CountOption.exact);
      final remindersRes = await client.from('user_reminders').select('id').eq('is_enabled', true).count(CountOption.exact);

      return AnalyticsSummary(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        newUsers: newUsers,
        returningUsers: returningUsers,
        totalScreenViews: totalScreenViews,
        calendarViews: calendarViews,
        panchangamViews: panchangamViews,
        muhurthamViews: muhurthamViews,
        festivalViews: festivalViews,
        specialDayViews: specialDayViews,
        posterViews: posterViews,
        notificationCampaigns: campaignsList.length,
        notificationDelivered: totalDelivered,
        notificationOpened: totalOpened,
        totalShares: shares,
        totalSavedItems: savedRes.count ?? 0,
        totalActiveReminders: remindersRes.count ?? 0,
        notificationOpenRate: openRate,
      );
    } catch (e) {
      throw StateError('Failed to load analytics: $e');
    }
  }

  /// Fetches daily trend records from daily_analytics table
  Future<List<DailyAnalyticsTrend>> getDailyTrends(AnalyticsDateRange range) async {
    final client = _client ?? SupabaseService().client;

    try {
      final startStr = '${range.startDate.year}-${range.startDate.month.toString().padLeft(2, '0')}-${range.startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${range.endDate.year}-${range.endDate.month.toString().padLeft(2, '0')}-${range.endDate.day.toString().padLeft(2, '0')}';

      final res = await client
          .from('daily_analytics')
          .select()
          .gte('analytics_date', startStr)
          .lte('analytics_date', endStr)
          .order('analytics_date', ascending: true);

      final list = (res as List?) ?? [];

      return list.map((item) => DailyAnalyticsTrend.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw StateError('Failed to load daily trends: $e');
    }
  }

  /// Calculates module breakdown percentage
  List<ModuleUsageMetric> calculateModuleUsage(AnalyticsSummary summary) {
    final total = summary.totalScreenViews > 0 ? summary.totalScreenViews : 1;

    return [
      ModuleUsageMetric(
        moduleKey: 'calendar',
        moduleName: 'Calendar & Monthly View',
        moduleNameTamil: 'மாத நாள்காட்டி',
        viewCount: summary.calendarViews,
        percentage: (summary.calendarViews / total) * 100,
      ),
      ModuleUsageMetric(
        moduleKey: 'panchangam',
        moduleName: 'Daily Panchangam & Nalla Neram',
        moduleNameTamil: 'பஞ்சாங்கம் & நல்ல நேரம்',
        viewCount: summary.panchangamViews,
        percentage: (summary.panchangamViews / total) * 100,
      ),
      ModuleUsageMetric(
        moduleKey: 'muhurtham',
        moduleName: 'Subha Muhurtham Dates',
        moduleNameTamil: 'சுப முகூர்த்த நாட்கள்',
        viewCount: summary.muhurthamViews,
        percentage: (summary.muhurthamViews / total) * 100,
      ),
      ModuleUsageMetric(
        moduleKey: 'festivals',
        moduleName: 'Tamil Festivals & Vratams',
        moduleNameTamil: 'பண்டிகைகள் & விரதங்கள்',
        viewCount: summary.festivalViews,
        percentage: (summary.festivalViews / total) * 100,
      ),
      ModuleUsageMetric(
        moduleKey: 'special_days',
        moduleName: 'Special Days (Amavasai/Pournami)',
        moduleNameTamil: 'விசேஷ தினங்கள்',
        viewCount: summary.specialDayViews,
        percentage: (summary.specialDayViews / total) * 100,
      ),
      ModuleUsageMetric(
        moduleKey: 'posters',
        moduleName: 'Content & Festival Posters',
        moduleNameTamil: 'சுவரொட்டிகள் & செய்திகள்',
        viewCount: summary.posterViews,
        percentage: (summary.posterViews / total) * 100,
      ),
    ];
  }

  /// Exports metrics data into CSV format
  String exportToCsv(AnalyticsSummary summary, List<DailyAnalyticsTrend> trends, AnalyticsDateRange range) {
    final buffer = StringBuffer();
    buffer.writeln('TNT Tamil Calendar - Admin Analytics Report');
    buffer.writeln('Date Range:,${range.label}');
    buffer.writeln('Generated At:,${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('--- Executive Summary ---');
    buffer.writeln('Metric,Value');
    buffer.writeln('Total Registered Users,${summary.totalUsers}');
    buffer.writeln('Active Users,${summary.activeUsers}');
    buffer.writeln('New Users,${summary.newUsers}');
    buffer.writeln('Returning Users,${summary.returningUsers}');
    buffer.writeln('Total Screen Views,${summary.totalScreenViews}');
    buffer.writeln('Calendar Views,${summary.calendarViews}');
    buffer.writeln('Panchangam Views,${summary.panchangamViews}');
    buffer.writeln('Muhurtham Views,${summary.muhurthamViews}');
    buffer.writeln('Festival Views,${summary.festivalViews}');
    buffer.writeln('Special Day Views,${summary.specialDayViews}');
    buffer.writeln('Poster/Content Views,${summary.posterViews}');
    buffer.writeln('Total Shares,${summary.totalShares}');
    buffer.writeln('Total Saved Items,${summary.totalSavedItems}');
    buffer.writeln('Total Active Reminders,${summary.totalActiveReminders}');
    buffer.writeln('Notification Campaigns,${summary.notificationCampaigns}');
    buffer.writeln('Notifications Delivered,${summary.notificationDelivered}');
    buffer.writeln('Notifications Opened,${summary.notificationOpened}');
    buffer.writeln('Notification Open Rate (%),${summary.notificationOpenRate.toStringAsFixed(2)}%');
    buffer.writeln('');
    buffer.writeln('--- Daily Trends ---');
    buffer.writeln('Date,Active Users,New Users,Total Views,Notification Opens,Shares');
    for (final t in trends) {
      buffer.writeln('${t.date},${t.activeUsers},${t.newUsers},${t.totalViews},${t.notificationOpens},${t.shares}');
    }
    return buffer.toString();
  }

  /// Exports metrics data into JSON format
  String exportToJson(AnalyticsSummary summary, List<DailyAnalyticsTrend> trends, AnalyticsDateRange range) {
    final data = {
      'report': 'TNT Tamil Calendar - Admin Analytics Report',
      'range': range.label,
      'generated_at': DateTime.now().toIso8601String(),
      'summary': {
        'total_users': summary.totalUsers,
        'active_users': summary.activeUsers,
        'new_users': summary.newUsers,
        'returning_users': summary.returningUsers,
        'total_screen_views': summary.totalScreenViews,
        'calendar_views': summary.calendarViews,
        'panchangam_views': summary.panchangamViews,
        'muhurtham_views': summary.muhurthamViews,
        'festival_views': summary.festivalViews,
        'special_day_views': summary.specialDayViews,
        'poster_views': summary.posterViews,
        'total_shares': summary.totalShares,
        'total_saved_items': summary.totalSavedItems,
        'total_active_reminders': summary.totalActiveReminders,
        'notification_campaigns': summary.notificationCampaigns,
        'notification_delivered': summary.notificationDelivered,
        'notification_opened': summary.notificationOpened,
        'notification_open_rate': summary.notificationOpenRate,
      },
      'daily_trends': trends.map((t) => {
        'date': t.date,
        'active_users': t.activeUsers,
        'new_users': t.newUsers,
        'total_views': t.totalViews,
        'notification_opens': t.notificationOpens,
        'shares': t.shares,
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
