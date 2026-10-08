import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/tnt_models.dart';
import '../repositories/admin_campaign_repository.dart';
import '../widgets/admin_notification_preview_dialog.dart';
import 'admin_campaign_create_screen.dart';
import 'admin_campaign_detail_screen.dart';
import 'admin_delivery_logs_screen.dart';
import 'admin_campaign_analytics_screen.dart';

/// Admin Notification Campaigns Main Screen
/// Central Management hub for creating, scheduling, previewing, and analyzing campaigns
class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  _AdminCampaignsScreenState createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends State<AdminCampaignsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminCampaignRepository _repository = AdminCampaignRepository();

  List<NotificationCampaign> _campaigns = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'PANCHANGAM',
    'MUHURTHAM',
    'FESTIVAL',
    'SPECIAL_DAY',
    'REMINDER',
    'IMPORTANT_UPDATE',
    'ANNOUNCEMENT',
    'MARKETING',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadCampaigns();
      }
    });
    _loadCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _getStatusForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return 'ALL';
      case 1:
        return 'SCHEDULED';
      case 2:
        return 'SENT';
      case 3:
        return 'DRAFT';
      case 4:
        return 'CANCELLED';
      default:
        return 'ALL';
    }
  }

  Future<void> _loadCampaigns() async {
    if (_tabController.index >= 5) return; // Logs or Analytics

    setState(() => _isLoading = true);
    final status = _getStatusForCurrentTab();
    final list = await _repository.getCampaigns(
      status: status,
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );

    if (mounted) {
      setState(() {
        _campaigns = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text(
          'Notification Campaigns',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [  
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: _loadCampaigns,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: TNTColors.primary,
          unselectedLabelColor: TNTColors.textSecondary,
          indicatorColor: TNTColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'All Campaigns'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Sent'),
            Tab(text: 'Drafts'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Delivery Logs'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCampaignsTabList(),
          _buildCampaignsTabList(),
          _buildCampaignsTabList(),
          _buildCampaignsTabList(),
          _buildCampaignsTabList(),
          const AdminDeliveryLogsScreen(),
          const AdminCampaignAnalyticsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TNTColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Create Campaign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminCampaignCreateScreen(
                onSaved: _loadCampaigns,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignsTabList() {
    return Column(
      children: [
        // Search & Category Filters Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: TNTColors.surface,
          child: Column(
            children: [
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search campaigns...',
                  hintStyle: const TextStyle(fontSize: 12, color: TNTColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: TNTColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _loadCampaigns();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: TNTColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: TNTColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: TNTColors.border),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                  _loadCampaigns();
                },
              ),
              const SizedBox(height: 8),

              // Category horizontal filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat, style: const TextStyle(fontSize: 10)),
                        selected: isSel,
                        selectedColor: TNTColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSel ? TNTColors.primary : TNTColors.textSecondary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: TNTColors.background,
                        side: const BorderSide(color: TNTColors.border),
                        onSelected: (val) {
                          setState(() => _selectedCategory = cat);
                          _loadCampaigns();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: TNTColors.border),

        // Campaign Items List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
              : _campaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined, size: 54, color: TNTColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No notification campaigns found',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Create Campaign" below to prepare a push alert.',
                            style: TextStyle(fontSize: 11, color: TNTColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCampaigns,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _campaigns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final c = _campaigns[idx];
                          return _buildCampaignCard(c);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCampaignCard(NotificationCampaign c) {
    return Card(
      color: TNTColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: TNTColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminCampaignDetailScreen(
                campaignId: c.id,
                onUpdated: _loadCampaigns,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.category.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: TNTColors.primary),
                    ),
                  ),
                  _buildStatusPill(c.status),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                c.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 4),

              // Tamil Title subtitle if different
              if (c.titleTamil.isNotEmpty && c.titleTamil != c.title) ...[
                Text(
                  c.titleTamil,
                  style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
              ],

              // Body preview
              Text(
                c.body,
                style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Timestamps & Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (c.scheduledAt != null)
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Sched: ${c.scheduledAt!.toLocal().toString().split(' ').first}',
                          style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else if (c.sentAt != null)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Sent: ${c.sentAt!.toLocal().toString().split(' ').first}',
                          style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Created: ${c.createdAt.toLocal().toString().split(' ').first}',
                      style: const TextStyle(fontSize: 10, color: TNTColors.textMuted),
                    ),

                  // Actions row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.preview_rounded, size: 18, color: TNTColors.primary),
                        tooltip: 'Preview',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AdminNotificationPreviewDialog(campaign: c),
                          );
                        },
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: TNTColors.textMuted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
