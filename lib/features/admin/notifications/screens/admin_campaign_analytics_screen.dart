import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/tnt_models.dart';
import '../repositories/admin_campaign_repository.dart';

/// Admin Campaign Analytics Screen
/// Shows aggregated campaign performance, open rates, delivery funnel, and category distribution
class AdminCampaignAnalyticsScreen extends StatefulWidget {
  const AdminCampaignAnalyticsScreen({super.key});

  @override
  _AdminCampaignAnalyticsScreenState createState() => _AdminCampaignAnalyticsScreenState();
}

class _AdminCampaignAnalyticsScreenState extends State<AdminCampaignAnalyticsScreen> {
  final AdminCampaignRepository _repository = AdminCampaignRepository();
  CampaignDeliveryAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final data = await _repository.getCampaignAnalytics();
    if (mounted) {
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: TNTColors.primary));
    }

    final a = _analytics ?? CampaignDeliveryAnalytics.empty();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TNTColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.analytics_rounded, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notification Analytics',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Verified delivery and user engagement metrics',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rates Row
          Row(
            children: [
              Expanded(
                child: _buildRateCard(
                  'Delivery Rate',
                  '${a.deliveryRatePercentage.toStringAsFixed(1)}%',
                  Icons.verified_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRateCard(
                  'Open Rate',
                  '${a.openRatePercentage.toStringAsFixed(1)}%',
                  Icons.mark_email_read_rounded,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overview Breakdown Grid
          const Text(
            'Campaign Status Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildCountCard('Total Campaigns', '${a.totalCampaigns}', Icons.campaign_rounded, TNTColors.primary),
              _buildCountCard('Sent Campaigns', '${a.sentCampaigns}', Icons.check_circle_rounded, Colors.green),
              _buildCountCard('Scheduled', '${a.scheduledCampaigns}', Icons.schedule_rounded, Colors.orange),
              _buildCountCard('Drafts', '${a.draftCampaigns}', Icons.drafts_rounded, Colors.blue),
            ],
          ),
          const SizedBox(height: 20),

          // Volume Totals
          Card(
            color: TNTColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: TNTColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lifetime Notification Volumes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  _buildProgressRow('Total Dispatched', a.totalNotificationsSent, Colors.indigo),
                  const SizedBox(height: 10),
                  _buildProgressRow('Confirmed Delivered', a.totalNotificationsDelivered, Colors.green),
                  const SizedBox(height: 10),
                  _buildProgressRow('User Opened', a.totalNotificationsOpened, Colors.teal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRateCard(String title, String val, IconData icon, Color color) {
    return Card(
      color: TNTColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: TNTColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(String title, String count, IconData icon, Color color) {
    return Card(
      color: TNTColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: TNTColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: color),
                Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
          ],
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
      ],
    );
  }
}
