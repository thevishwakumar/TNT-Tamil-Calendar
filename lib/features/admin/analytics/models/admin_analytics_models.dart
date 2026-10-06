
/// Date range options for analytics filtering
enum AnalyticsDateFilterType {
  today,
  yesterday,
  last7Days,
  last30Days,
  currentMonth,
  previousMonth,
  custom,
}

class AnalyticsDateRange {
  final AnalyticsDateFilterType type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const AnalyticsDateRange({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  factory AnalyticsDateRange.today() {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.today,
      startDate: start,
      endDate: end,
      label: 'Today',
    );
  }

  factory AnalyticsDateRange.yesterday() {
    final now = DateTime.now().toUtc().subtract(const Duration(days: 1));
    final start = DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.yesterday,
      startDate: start,
      endDate: end,
      label: 'Yesterday',
    );
  }

  factory AnalyticsDateRange.last7Days() {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(days: 7));
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.last7Days,
      startDate: DateTime.utc(start.year, start.month, start.day, 0, 0, 0),
      endDate: DateTime.utc(now.year, now.month, now.day, 23, 59, 59),
      label: 'Last 7 Days',
    );
  }

  factory AnalyticsDateRange.last30Days() {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(days: 30));
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.last30Days,
      startDate: DateTime.utc(start.year, start.month, start.day, 0, 0, 0),
      endDate: DateTime.utc(now.year, now.month, now.day, 23, 59, 59),
      label: 'Last 30 Days',
    );
  }

  factory AnalyticsDateRange.currentMonth() {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, 1, 0, 0, 0);
    final nextMonth = now.month == 12 ? DateTime.utc(now.year + 1, 1, 1) : DateTime.utc(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(seconds: 1));
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.currentMonth,
      startDate: start,
      endDate: end,
      label: 'Current Month',
    );
  }

  factory AnalyticsDateRange.previousMonth() {
    final now = DateTime.now().toUtc();
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final start = DateTime.utc(prevYear, prevMonth, 1, 0, 0, 0);
    final endMonthStart = now.month == 12 ? DateTime.utc(now.year, now.month, 1) : DateTime.utc(now.year, now.month, 1);
    final end = endMonthStart.subtract(const Duration(seconds: 1));
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.previousMonth,
      startDate: start,
      endDate: end,
      label: 'Previous Month',
    );
  }

  factory AnalyticsDateRange.custom(DateTime start, DateTime end) {
    return AnalyticsDateRange(
      type: AnalyticsDateFilterType.custom,
      startDate: DateTime.utc(start.year, start.month, start.day, 0, 0, 0),
      endDate: DateTime.utc(end.year, end.month, end.day, 23, 59, 59),
      label: '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}',
    );
  }
}

/// Comprehensive summary metrics strictly calculated from database tables
class AnalyticsSummary {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final int returningUsers;
  final int totalScreenViews;
  final int calendarViews;
  final int panchangamViews;
  final int muhurthamViews;
  final int festivalViews;
  final int specialDayViews;
  final int posterViews;
  final int notificationCampaigns;
  final int notificationDelivered;
  final int notificationOpened;
  final int totalShares;
  final int totalSavedItems;
  final int totalActiveReminders;
  final double notificationOpenRate;

  const AnalyticsSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.returningUsers,
    required this.totalScreenViews,
    required this.calendarViews,
    required this.panchangamViews,
    required this.muhurthamViews,
    required this.festivalViews,
    required this.specialDayViews,
    required this.posterViews,
    required this.notificationCampaigns,
    required this.notificationDelivered,
    required this.notificationOpened,
    required this.totalShares,
    required this.totalSavedItems,
    required this.totalActiveReminders,
    required this.notificationOpenRate,
  });

  factory AnalyticsSummary.empty() {
    return const AnalyticsSummary(
      totalUsers: 0,
      activeUsers: 0,
      newUsers: 0,
      returningUsers: 0,
      totalScreenViews: 0,
      calendarViews: 0,
      panchangamViews: 0,
      muhurthamViews: 0,
      festivalViews: 0,
      specialDayViews: 0,
      posterViews: 0,
      notificationCampaigns: 0,
      notificationDelivered: 0,
      notificationOpened: 0,
      totalShares: 0,
      totalSavedItems: 0,
      totalActiveReminders: 0,
      notificationOpenRate: 0.0,
    );
  }
}

/// Daily aggregated trends
class DailyAnalyticsTrend {
  final String date;
  final int activeUsers;
  final int newUsers;
  final int totalViews;
  final int notificationOpens;
  final int shares;

  const DailyAnalyticsTrend({
    required this.date,
    required this.activeUsers,
    required this.newUsers,
    required this.totalViews,
    required this.notificationOpens,
    required this.shares,
  });

  factory DailyAnalyticsTrend.fromJson(Map<String, dynamic> json) {
    return DailyAnalyticsTrend(
      date: json['analytics_date']?.toString() ?? json['date']?.toString() ?? '',
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      newUsers: (json['new_users'] as num?)?.toInt() ?? 0,
      totalViews: ((json['calendar_views'] as num?)?.toInt() ?? 0) +
          ((json['panchangam_views'] as num?)?.toInt() ?? 0) +
          ((json['muhurtham_views'] as num?)?.toInt() ?? 0) +
          ((json['poster_views'] as num?)?.toInt() ?? 0),
      notificationOpens: (json['notification_opens'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Module popularity breakdown
class ModuleUsageMetric {
  final String moduleKey;
  final String moduleName;
  final String moduleNameTamil;
  final int viewCount;
  final double percentage;

  const ModuleUsageMetric({
    required this.moduleKey,
    required this.moduleName,
    required this.moduleNameTamil,
    required this.viewCount,
    required this.percentage,
  });
}

/// Content engagement tracking
class ContentEngagementItem {
  final String id;
  final String title;
  final String category;
  final int viewCount;
  final int shareCount;
  final int saveCount;

  const ContentEngagementItem({
    required this.id,
    required this.title,
    required this.category,
    required this.viewCount,
    required this.shareCount,
    required this.saveCount,
  });
}
