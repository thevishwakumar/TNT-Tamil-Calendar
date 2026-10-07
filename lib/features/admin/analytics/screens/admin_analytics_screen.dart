import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/tnt_localizations.dart';
import '../models/admin_analytics_models.dart';
import '../repositories/admin_analytics_repository.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminAnalyticsRepository _repository = AdminAnalyticsRepository();
  AnalyticsDateRange _selectedRange = AnalyticsDateRange.last7Days();
  
  bool _isLoading = true;
  String? _error;
  AnalyticsSummary _summary = AnalyticsSummary.empty();
  List<DailyAnalyticsTrend> _trends = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _repository.getSummary(_selectedRange);
      final trends = await _repository.getDailyTrends(_selectedRange);
      if (mounted) {
        setState(() {
          _summary = summary;
          _trends = trends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load analytics: $e';
        });
      }
    }
  }

  void _onFilterSelected(AnalyticsDateFilterType type) async {
    AnalyticsDateRange newRange;
    if (type == AnalyticsDateFilterType.today) {
      newRange = AnalyticsDateRange.today();
    } else if (type == AnalyticsDateFilterType.yesterday) {
      newRange = AnalyticsDateRange.yesterday();
    } else if (type == AnalyticsDateFilterType.last7Days) {
      newRange = AnalyticsDateRange.last7Days();
    } else if (type == AnalyticsDateFilterType.last30Days) {
      newRange = AnalyticsDateRange.last30Days();
    } else if (type == AnalyticsDateFilterType.currentMonth) {
      newRange = AnalyticsDateRange.currentMonth();
    } else if (type == AnalyticsDateFilterType.previousMonth) {
      newRange = AnalyticsDateRange.previousMonth();
    } else {
      // Custom date picker
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024, 1, 1),
        lastDate: DateTime(now.year, now.month, now.day),
        initialDateRange: DateTimeRange(
          start: _selectedRange.startDate,
          end: _selectedRange.endDate,
        ),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: TNTColors.primary,
                onPrimary: Colors.white,
                surface: TNTColors.surface,
                onSurface: TNTColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        newRange = AnalyticsDateRange.custom(picked.start, picked.end);
      } else {
        return;
      }
    }

    setState(() {
      _selectedRange = newRange;
    });
    _loadAnalytics();
  }

  void _showExportDialog() {
    final csvContent = _repository.exportToCsv(_summary, _trends, _selectedRange);
    final jsonContent = _repository.exportToJson(_summary, _trends, _selectedRange);

    showDialog(
      context: context,
      builder: (ctx) {
        int selectedTab = 0; // 0 for CSV, 1 for JSON
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: TNTColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.download_rounded, color: TNTColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text('Export Analytics Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range: ${_selectedRange.label}',
                      style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('CSV Format'),
                          selected: selectedTab == 0,
                          selectedColor: TNTColors.primary.withValues(alpha: 0.15),
                          onSelected: (val) => setDialogState(() => selectedTab = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('JSON Format'),
                          selected: selectedTab == 1,
                          selectedColor: TNTColors.primary.withValues(alpha: 0.15),
                          onSelected: (val) => setDialogState(() => selectedTab = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: TNTColors.border),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          selectedTab == 0 ? csvContent : jsonContent,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                  label: const Text('Copy to Clipboard', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: selectedTab == 0 ? csvContent : jsonContent));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${selectedTab == 0 ? 'CSV' : 'JSON'} copied to clipboard!'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;

    final moduleUsage = _repository.calculateModuleUsage(_summary);

    return Scaffold(
      backgroundColor: TNTColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: TNTColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Analytics & Intelligence',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      Text(
                        'Active Range: ${_selectedRange.label}',
                        style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showExportDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TNTColors.surface,
                      foregroundColor: TNTColors.primary,
                      elevation: 0,
                      side: const BorderSide(color: TNTColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Filter Chips
              _buildDateFilterBar(),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: TNTColors.primary),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else ...[
                // Key KPI Metrics Grid
                _buildKPIGrid(),
                const SizedBox(height: 20),

                // User Activity Breakdown
                _buildUserActivityCard(),
                const SizedBox(height: 20),

                // Module Usage & Screen Popularity
                _buildModuleUsageCard(moduleUsage),
                const SizedBox(height: 20),

                // Notification Performance Card
                _buildNotificationPerformanceCard(),
                const SizedBox(height: 20),

                // Engagement (Saves, Shares, Reminders)
                _buildEngagementMetricsCard(),
                const SizedBox(height: 20),

                // Daily Aggregation Trends Table
                _buildTrendsList(),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('Today', AnalyticsDateFilterType.today),
          const SizedBox(width: 6),
          _buildFilterChip('Yesterday', AnalyticsDateFilterType.yesterday),
          const SizedBox(width: 6),
          _buildFilterChip('Last 7 Days', AnalyticsDateFilterType.last7Days),
          const SizedBox(width: 6),
          _buildFilterChip('Last 30 Days', AnalyticsDateFilterType.last30Days),
          const SizedBox(width: 6),
          _buildFilterChip('Current Month', AnalyticsDateFilterType.currentMonth),
          const SizedBox(width: 6),
          _buildFilterChip('Previous Month', AnalyticsDateFilterType.previousMonth),
          const SizedBox(width: 6),
          _buildFilterChip('Custom Range', AnalyticsDateFilterType.custom),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AnalyticsDateFilterType type) {
    final isSelected = _selectedRange.type == type;
    return InkWell(
      onTap: () => _onFilterSelected(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? TNTColors.primary : TNTColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? TNTColors.primary : TNTColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : TNTColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Core Executive KPIs',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Screen Views',
                '${_summary.totalScreenViews}',
                Icons.visibility_rounded,
                Colors.indigo,
                'All app features',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Active Users',
                '${_summary.activeUsers}',
                Icons.person_pin_circle_rounded,
                Colors.green,
                'Engaged in period',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Users',
                '${_summary.totalUsers}',
                Icons.people_alt_rounded,
                Colors.blue,
                'Registered profiles',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Notification Open Rate',
                '${_summary.notificationOpenRate.toStringAsFixed(1)}%',
                Icons.campaign_rounded,
                Colors.teal,
                '${_summary.notificationOpened} opened',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TNTColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildUserActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: TNTColors.primary),
              SizedBox(width: 8),
              Text(
                'User Growth & Retention Dynamics',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildGrowthStat('New Users', '${_summary.newUsers}', Colors.green),
              _buildDivider(),
              _buildGrowthStat('Returning', '${_summary.returningUsers}', Colors.blue),
              _buildDivider(),
              _buildGrowthStat('Active %', '${_summary.totalUsers > 0 ? ((_summary.activeUsers / _summary.totalUsers) * 100).toStringAsFixed(1) : '0'}%', TNTColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, decoration: BoxDecoration(
      color: TNTColors.border));
  }

  Widget _buildModuleUsageCard(List<ModuleUsageMetric> metrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 18, color: TNTColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Module Usage Breakdown',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                ],
              ),
              Text(
                'By Screen Views',
                style: TextStyle(fontSize: 11, color: TNTColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...metrics.map((m) => _buildModuleProgressRow(m)),
        ],
      ),
    );
  }

  Widget _buildModuleProgressRow(ModuleUsageMetric metric) {
    final percent = metric.percentage.clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${metric.moduleName} (${metric.moduleNameTamil})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TNTColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${metric.viewCount} views (${metric.percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(TNTColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.send_rounded, size: 18, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                'Push Notification Campaign Performance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildGrowthStat('Campaigns', '${_summary.notificationCampaigns}', Colors.purple),
              _buildDivider(),
              _buildGrowthStat('Delivered', '${_summary.notificationDelivered}', Colors.blue),
              _buildDivider(),
              _buildGrowthStat('Opened', '${_summary.notificationOpened}', Colors.green),
              _buildDivider(),
              _buildGrowthStat('Open Rate', '${_summary.notificationOpenRate.toStringAsFixed(1)}%', Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.share_rounded, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'User Engagement & Virality',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildGrowthStat('Total Shares', '${_summary.totalShares}', Colors.orange),
              _buildDivider(),
              _buildGrowthStat('Saved Items', '${_summary.totalSavedItems}', TNTColors.primary),
              _buildDivider(),
              _buildGrowthStat('Active Reminders', '${_summary.totalActiveReminders}', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Activity Log',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              Text('Sync: Real-Time', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (_trends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text('No daily trend records in this range.', style: TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
              ),
            )
          else
            ..._trends.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TNTColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TNTColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                      Text('${t.newUsers} new users registered', style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildMiniBadge('${t.activeUsers} active', Colors.blue),
                      const SizedBox(width: 6),
                      _buildMiniBadge('${t.totalViews} views', Colors.purple),
                      const SizedBox(width: 6),
                      _buildMiniBadge('${t.shares} shares', Colors.orange),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
