import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../repositories/admin_campaign_repository.dart';

/// Admin Delivery Logs Screen
/// Displays delivery events, statuses (PENDING, QUEUED, SENT, DELIVERED, OPENED, FAILED, SKIPPED, CANCELLED)
class AdminDeliveryLogsScreen extends StatefulWidget {
  const AdminDeliveryLogsScreen({super.key});

  @override
  _AdminDeliveryLogsScreenState createState() => _AdminDeliveryLogsScreenState();
}

class _AdminDeliveryLogsScreenState extends State<AdminDeliveryLogsScreen> {
  final AdminCampaignRepository _repository = AdminCampaignRepository();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';

  final List<String> _statuses = [
    'ALL',
    'SENT',
    'DELIVERED',
    'OPENED',
    'FAILED',
    'SKIPPED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final data = await _repository.getDeliveryLogs(status: _selectedStatus);
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: TNTColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((st) {
                final isSelected = _selectedStatus == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(st, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: TNTColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? TNTColors.primary : TNTColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: TNTColors.background,
                    side: const BorderSide(color: TNTColors.border),
                    onSelected: (val) {
                      setState(() => _selectedStatus = st);
                      _loadLogs();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, color: TNTColors.border),

        // Logs List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 48, color: TNTColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No notification logs found',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Delivery events will appear here when campaigns are sent.',
                            style: TextStyle(fontSize: 11, color: TNTColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final log = _logs[idx];
                        final st = (log['status'] as String? ?? 'SENT').toUpperCase();

                        return Card(
                          color: TNTColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: TNTColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatusIcon(st),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              log['title'] ?? 'Notification',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildBadge(st),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log['body'] ?? '',
                                        style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Type: ${log['notification_type'] ?? 'GENERAL'}',
                                            style: const TextStyle(fontSize: 10, color: TNTColors.textMuted, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            log['sent_at'] != null ? log['sent_at'].toString().split('T').first : '',
                                            style: const TextStyle(fontSize: 10, color: TNTColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'OPENED':
        icon = Icons.drafts_rounded;
        color = Colors.teal;
        break;
      case 'DELIVERED':
        icon = Icons.done_all_rounded;
        color = Colors.green;
        break;
      case 'SENT':
        icon = Icons.send_rounded;
        color = Colors.indigo;
        break;
      case 'FAILED':
        icon = Icons.error_outline_rounded;
        color = Colors.red;
        break;
      case 'SKIPPED':
        icon = Icons.skip_next_rounded;
        color = Colors.grey;
        break;
      default:
        icon = Icons.circle_notifications_rounded;
        color = TNTColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'OPENED':
        bg = Colors.teal[50]!;
        fg = Colors.teal[800]!;
        break;
      case 'DELIVERED':
        bg = Colors.green[50]!;
        fg = Colors.green[800]!;
        break;
      case 'SENT':
        bg = Colors.indigo[50]!;
        fg = Colors.indigo[800]!;
        break;
      case 'FAILED':
        bg = Colors.red[50]!;
        fg = Colors.red[800]!;
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
