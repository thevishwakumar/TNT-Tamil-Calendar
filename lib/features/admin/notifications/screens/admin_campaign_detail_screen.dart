import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/tnt_models.dart';
import '../../widgets/admin_form_widgets.dart';
import '../repositories/admin_campaign_repository.dart';
import '../widgets/admin_notification_preview_dialog.dart';
import 'admin_campaign_create_screen.dart';

/// Admin Campaign Detail Screen
/// Shows full campaign information, delivery breakdown, action controls, and audit status
class AdminCampaignDetailScreen extends StatefulWidget {
  final String campaignId;
  final VoidCallback onUpdated;

  const AdminCampaignDetailScreen({
    super.key,
    required this.campaignId,
    required this.onUpdated,
  });

  @override
  _AdminCampaignDetailScreenState createState() => _AdminCampaignDetailScreenState();
}

class _AdminCampaignDetailScreenState extends State<AdminCampaignDetailScreen> {
  final AdminCampaignRepository _repository = AdminCampaignRepository();
  NotificationCampaign? _campaign;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadCampaign();
  }

  Future<void> _loadCampaign() async {
    setState(() => _isLoading = true);
    final c = await _repository.getCampaignById(widget.campaignId);
    if (mounted) {
      setState(() {
        _campaign = c;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Cancel Scheduled Campaign?',
      message: 'This campaign will be marked as CANCELLED and will not be dispatched at its scheduled time.',
      confirmLabel: 'Cancel Campaign',
      confirmColor: const Color(0xFFF44336),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      await _repository.cancelCampaign(widget.campaignId);
      widget.onUpdated();
      await _loadCampaign();
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign cancelled successfully.')),
        );
      }
    }
  }

  Future<void> _handleSendNow() async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Send Campaign Now?',
      message: 'This will immediately trigger push notifications to all eligible devices via the secure FCM pipeline.',
      confirmLabel: 'Dispatch Now',
      confirmColor: const Color(0xFF2196F3),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        await _repository.sendCampaignNow(widget.campaignId);
        widget.onUpdated();
        await _loadCampaign();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign sent successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Send error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TNTColors.background,
        body: Center(child: CircularProgressIndicator(color: TNTColors.primary)),
      );
    }

    final c = _campaign;
    if (c == null) {
      return Scaffold(
        backgroundColor: TNTColors.background,
        appBar: AppBar(title: const Text('Campaign Not Found'), backgroundColor: TNTColors.surface, actions: const [TNTBrandHeader()],),
        body: const Center(child: Text('Requested notification campaign does not exist.')),
      );
    }

    final status = c.status.toUpperCase();
    final canEdit = status == 'DRAFT' || status == 'SCHEDULED';
    final canSend = status == 'DRAFT' || status == 'SCHEDULED';
    final canCancel = status == 'SCHEDULED';

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          c.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: 'Live Preview',
            icon: const Icon(Icons.preview_rounded, color: TNTColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AdminNotificationPreviewDialog(campaign: c),
              );
            },
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Edit Campaign',
              icon: const Icon(Icons.edit_rounded, color: TNTColors.textPrimary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminCampaignCreateScreen(
                      initialCampaign: c,
                      onSaved: () {
                        widget.onUpdated();
                        _loadCampaign();
                      },
                    ),
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Category Header Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(c.status),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TNTColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.category.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                    ),
                    if (c.scheduledAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Scheduled for: ${c.scheduledAt!.toLocal().toString().split('.').first}',
                            style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    if (c.sentAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Dispatched at: ${c.sentAt!.toLocal().toString().split('.').first}',
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Real Delivery Performance Metrics
            const Text(
              'Delivery & Performance Metrics',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _buildMetricBox('Targeted', '${c.totalTargeted}', Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricBox('Sent', '${c.totalSent}', Colors.indigo)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricBox('Delivered', '${c.totalDelivered}', Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricBox('Opened', '${c.totalOpened}', Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricBox('Failed', '${c.totalFailed}', Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricBox('Skipped', '${c.totalSkipped}', Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            // Bilingual Notification Content
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
                      'Bilingual Content',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                    ),
                    const Divider(height: 20, color: TNTColors.border),

                    // Tamil
                    const Text('தமிழ் தலைப்பு (Tamil Title):', style: TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
                    Text(c.titleTamil.isNotEmpty ? c.titleTamil : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('தமிழ் செய்தி (Tamil Body):', style: TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
                    Text(c.messageTamil.isNotEmpty ? c.messageTamil : '-', style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary)),

                    const Divider(height: 20, color: TNTColors.border),

                    // English
                    const Text('English Title:', style: TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
                    Text(c.titleEnglish.isNotEmpty ? c.titleEnglish : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('English Body:', style: TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
                    Text(c.messageEnglish.isNotEmpty ? c.messageEnglish : '-', style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deep link & targeting
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
                      'Targeting & Routing Details',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Audience Scope', c.audienceType),
                    _buildDetailRow('Deep Link URI', c.deepLink ?? 'None'),
                    _buildDetailRow('Rich Media Banner', c.mediaReference ?? 'None'),
                    if (c.idempotencyKey != null)
                      _buildDetailRow('Idempotency Key', c.idempotencyKey!),
                    _buildDetailRow('Created At', c.createdAt.toLocal().toString().split('.').first),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons Bar
            if (canSend) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Campaign Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _isProcessing ? null : _handleSendNow,
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (canCancel) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Scheduled Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _isProcessing ? null : _handleCancel,
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: TNTColors.textPrimary,
                  side: const BorderSide(color: TNTColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AdminNotificationPreviewDialog(campaign: c),
                  );
                },
                child: const Text('Preview Push Notification'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TNTColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'SENT':
        bg = Colors.green[50]!;
        fg = Colors.green[800]!;
        break;
      case 'SCHEDULED':
        bg = Colors.orange[50]!;
        fg = Colors.orange[800]!;
        break;
      case 'DRAFT':
        bg = Colors.blue[50]!;
        fg = Colors.blue[800]!;
        break;
      case 'CANCELLED':
        bg = Colors.grey[100]!;
        fg = Colors.grey[800]!;
        break;
      case 'FAILED':
        bg = Colors.red[50]!;
        fg = Colors.red[800]!;
        break;
      default:
        bg = TNTColors.background;
        fg = TNTColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
