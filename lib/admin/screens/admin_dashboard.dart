import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/authorization/admin_authorization_service.dart';
import '../../models/tnt_models.dart';
import '../../services/auth_state_manager.dart';
import '../../services/supabase_service.dart';
import '../../services/production_api_service.dart';
import '../../features/admin/content/admin_content_screen.dart';
import '../../features/admin/festivals_management/admin_festivals_screen.dart';
import '../../features/admin/special_days_management/admin_special_days_screen.dart';
import '../../features/admin/muhurtham_management/admin_muhurtham_screen.dart';
import '../../features/admin/panchangam_management/admin_panchangam_screen.dart';
import '../../features/admin/calendar_management/admin_calendar_screen.dart';
import '../../features/admin/notifications/screens/admin_campaigns_screen.dart';
import '../../features/admin/analytics/screens/admin_analytics_screen.dart';
import '../../features/admin/users/screens/admin_users_screen.dart';
import '../../features/admin/catering/admin_catering_leads_screen.dart';
import '../../features/catering/repositories/catering_repository.dart';

import '../../features/admin/settings/screens/admin_settings_screen.dart';

/// Available Admin Navigation Sections
enum AdminSection {
  dashboard,
  calendar,
  panchangam,
  muhurtham,
  specialDays,
  festivals,
  content,
  notifications,
  users,
  analytics,
  internalSchedules,
  cateringLeads,
  settings,
}

class AdminDashboard extends StatefulWidget {
  final AuthStateManager authStateManager;
  final ITNTApiService? apiService;

  const AdminDashboard({
    super.key,
    required this.authStateManager,
    this.apiService,
  });

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final ITNTApiService _api;
  final AdminAuthorizationService _authService = AdminAuthorizationService();

  AdminSection _currentSection = AdminSection.dashboard;
  AdminDashboardMetrics? _metrics;
  Map<String, dynamic>? _cateringCounts;
  bool _isLoadingMetrics = true;
  String? _metricsError;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? SupabaseApiService();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoadingMetrics = true;
      _metricsError = null;
    });

    try {
      final data = await _api.getAdminDashboardMetrics();
      final cCounts = await CateringRepository().getLeadCounts();
      if (mounted) {
        setState(() {
          _metrics = data;
          _cateringCounts = cCounts;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _metrics = AdminDashboardMetrics.empty();
          _isLoadingMetrics = false;
          _metricsError = 'Data unavailable';
        });
      }
    }
  }

  String _getSectionTitle(AdminSection section, String Function(String) translate) {
    switch (section) {
      case AdminSection.dashboard:
        return 'TNT Admin Dashboard';
      case AdminSection.calendar:
        return 'Calendar Management';
      case AdminSection.panchangam:
        return 'Panchangam Management';
      case AdminSection.muhurtham:
        return 'Muhurtham Management';
      case AdminSection.specialDays:
        return 'Special Days Management';
      case AdminSection.festivals:
        return 'Festivals Management';
      case AdminSection.content:
        return 'Content & Posters';
      case AdminSection.notifications:
        return 'Notification Campaigns';
      case AdminSection.users:
        return 'User Management';
      case AdminSection.analytics:
        return 'Admin Analytics';
      case AdminSection.internalSchedules:
        return 'Internal Schedules';
      case AdminSection.cateringLeads:
        return 'Catering Leads';
      case AdminSection.settings:
        return 'System Settings';
    }
  }

  IconData _getSectionIcon(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
        return Icons.dashboard_rounded;
      case AdminSection.calendar:
        return Icons.calendar_month_rounded;
      case AdminSection.panchangam:
        return Icons.wb_sunny_rounded;
      case AdminSection.muhurtham:
        return Icons.favorite_rounded;
      case AdminSection.specialDays:
        return Icons.star_rounded;
      case AdminSection.festivals:
        return Icons.celebration_rounded;
      case AdminSection.content:
        return Icons.image_rounded;
      case AdminSection.notifications:
        return Icons.campaign_rounded;
      case AdminSection.users:
        return Icons.people_alt_rounded;
      case AdminSection.analytics:
        return Icons.insights_rounded;
      case AdminSection.internalSchedules:
        return Icons.event_seat_rounded;
      case AdminSection.cateringLeads:
        return Icons.room_service_rounded;
      case AdminSection.settings:
        return Icons.settings_applications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;
    final profile = widget.authStateManager.currentProfile;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TNT Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            Text(
              profile?.fullName ?? 'Administrator',
              style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: 'Admin Profile',
            icon: const Icon(Icons.account_circle_outlined, color: TNTColors.textPrimary),
            onPressed: () => _showProfileDialog(context, translate, profile),
          ),
          IconButton(
            tooltip: 'Refresh Metrics',
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: _loadMetrics,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context, translate),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      drawer: _buildAdminDrawer(translate, profile),
      body: _buildCurrentSectionBody(translate, profile),
    );
  }

  Widget _buildAdminDrawer(String Function(String) translate, UserProfile? profile) {
    return Drawer(
      backgroundColor: TNTColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Admin Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              color: TNTColors.primary,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TNT Admin Portal',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.fullName ?? 'Administrator',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ROLE: ADMIN',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: AdminSection.values.map((section) {
                  final isSelected = _currentSection == section;
                  return ListTile(
                    leading: Icon(
                      _getSectionIcon(section),
                      color: isSelected ? TNTColors.primary : TNTColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      _getSectionTitle(section, translate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? TNTColors.primary : TNTColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: TNTColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      setState(() {
                        _currentSection = section;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const Divider(color: TNTColors.border),

            // Logout Option
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              title: const Text(
                'Logout Admin Session',
                style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showLogoutDialog(context, translate);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSectionBody(String Function(String) translate, UserProfile? profile) {
    switch (_currentSection) {
      case AdminSection.dashboard:
        return _buildDashboardOverview(translate, profile);
      case AdminSection.content:
        return const AdminContentScreen();
      case AdminSection.festivals:
        return const AdminFestivalsScreen();
      case AdminSection.specialDays:
        return const AdminSpecialDaysScreen();
      case AdminSection.muhurtham:
        return const AdminMuhurthamScreen();
      case AdminSection.panchangam:
        return const AdminPanchangamScreen();
      case AdminSection.calendar:
        return const AdminCalendarScreen();
      case AdminSection.analytics:
        return const AdminAnalyticsScreen();
      case AdminSection.internalSchedules:
        return const AdminSchedulesScreen();
      case AdminSection.users:
        return const AdminUsersScreen();
      case AdminSection.notifications:
        return const AdminCampaignsScreen();
      case AdminSection.cateringLeads:
        return const AdminCateringLeadsScreen();
      case AdminSection.settings:
        return const AdminSettingsScreen();
      default:
        return _buildSectionDetail(translate);
    }
  }

  Widget _buildDashboardOverview(String Function(String) translate, UserProfile? profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Welcome Banner
          _buildAdminBanner(translate, profile),
          const SizedBox(height: 20),

          // Real-time Summary Cards Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Summary Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              if (_isLoadingMetrics)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: TNTColors.primary),
                )
              else
                Text(
                  _metricsError != null ? 'Data unavailable' : 'Real-time database sync',
                  style: TextStyle(
                    fontSize: 11,
                    color: _metricsError != null ? Colors.redAccent : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 6 Required Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Catering Leads',
                  _isLoadingMetrics ? '...' : (_cateringCounts != null ? '${_cateringCounts!['new']}' : '0'),
                  Icons.room_service_rounded,
                  Colors.teal,
                  () => setState(() => _currentSection = AdminSection.cateringLeads),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Total Users',
                  _isLoadingMetrics ? '...' : (_metrics != null ? '${_metrics!.totalUsers}' : '0'),
                  Icons.people_alt_rounded,
                  Colors.blue,
                  () => setState(() => _currentSection = AdminSection.users),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Active Users',
                  _isLoadingMetrics ? '...' : (_metrics != null ? '${_metrics!.activeUsers}' : '0'),
                  Icons.insights_rounded,
                  Colors.green,
                  () => setState(() => _currentSection = AdminSection.users),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Upcoming Muhurtham',
                  _isLoadingMetrics ? '...' : (_metrics != null ? '${_metrics!.upcomingMuhurtham}' : '0'),
                  Icons.favorite_rounded,
                  TNTColors.primary,
                  () => setState(() => _currentSection = AdminSection.muhurtham),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Upcoming Festivals',
                  _isLoadingMetrics ? '...' : (_metrics != null ? '${_metrics!.upcomingFestivals}' : '0'),
                  Icons.celebration_rounded,
                  Colors.orange,
                  () => setState(() => _currentSection = AdminSection.festivals),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Pending Content',
                  _isLoadingMetrics ? '...' : (_metrics != null ? '${_metrics!.pendingContent}' : '0'),
                  Icons.pending_actions_rounded,
                  Colors.purple,
                  () => setState(() => _currentSection = AdminSection.content),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Scheduled Notifications',
                  _isLoadingMetrics ? '...' : (_metrics != null ? '${_metrics!.scheduledNotifications}' : '0'),
                  Icons.campaign_rounded,
                  Colors.teal,
                  () => setState(() => _currentSection = AdminSection.notifications),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Admin Management Sections Grid
          const Text(
            'Admin Management Hub',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _buildHubCard(
                'Calendar',
                'Dates, Tithi & Nakshatra',
                Icons.calendar_month_rounded,
                Colors.blue,
                () => setState(() => _currentSection = AdminSection.calendar),
              ),
              _buildHubCard(
                'Panchangam',
                'Horai, Rahu & Timings',
                Icons.wb_sunny_rounded,
                Colors.amber[800]!,
                () => setState(() => _currentSection = AdminSection.panchangam),
              ),
              _buildHubCard(
                'Muhurtham',
                'Marriage & Auspicious',
                Icons.favorite_rounded,
                TNTColors.primary,
                () => setState(() => _currentSection = AdminSection.muhurtham),
              ),
              _buildHubCard(
                'Special Days',
                'Pradosham, Amavasai, Ekadasi',
                Icons.star_rounded,
                Colors.purple,
                () => setState(() => _currentSection = AdminSection.specialDays),
              ),
              _buildHubCard(
                'Festivals',
                'Major Tamil & Temple Events',
                Icons.celebration_rounded,
                Colors.deepOrange,
                () => setState(() => _currentSection = AdminSection.festivals),
              ),
              _buildHubCard(
                'Content / Posters',
                'Daily Posters & Banners',
                Icons.image_rounded,
                Colors.teal,
                () => setState(() => _currentSection = AdminSection.content),
              ),
              _buildHubCard(
                'Notifications',
                'FCM Push Campaigns',
                Icons.campaign_rounded,
                Colors.indigo,
                () => setState(() => _currentSection = AdminSection.notifications),
              ),
              _buildHubCard(
                'Users Management',
                'Profiles & Device Tokens',
                Icons.people_alt_rounded,
                Colors.cyan[800]!,
                () => setState(() => _currentSection = AdminSection.users),
              ),
              _buildHubCard(
                'Private Analytics',
                'Engagement & App Metrics',
                Icons.insights_rounded,
                Colors.green[700]!,
                () => setState(() => _currentSection = AdminSection.analytics),
              ),
              _buildHubCard(
                'Internal Schedules',
                'Mandapam & Staff Notes',
                Icons.event_seat_rounded,
                Colors.brown,
                () => setState(() => _currentSection = AdminSection.internalSchedules),
              ),
              _buildHubCard(
                'Catering Leads',
                'Enquiries from Users',
                Icons.room_service_rounded,
                Colors.pink,
                () => setState(() => _currentSection = AdminSection.cateringLeads),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAdminBanner(String Function(String) translate, UserProfile? profile) {
    return Container(
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
            child: const Icon(Icons.shield_rounded, size: 26, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${profile?.fullName ?? "Admin"}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TNT Admin Security Guard active. RLS enabled.',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        color: TNTColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TNTColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: TNTColors.textMuted),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        color: TNTColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TNTColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDetail(String Function(String) translate) {
    final title = _getSectionTitle(_currentSection, translate);
    final icon = _getSectionIcon(_currentSection);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _currentSection = AdminSection.dashboard;
                  });
                },
              ),
              const SizedBox(width: 4),
              Icon(icon, color: TNTColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Management Container
          Card(
            color: TNTColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: TNTColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(icon, size: 48, color: TNTColors.primary.withValues(alpha: 0.8)),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Administrative management interface for $title is initialized with full RLS policy protection and role verification.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, size: 18, color: TNTColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Secured with public.is_admin() database enforcement.',
                            style: TextStyle(fontSize: 11, color: TNTColors.primary.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TNTColors.primary,
                      side: const BorderSide(color: TNTColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back to Admin Dashboard'),
                    onPressed: () {
                      setState(() {
                        _currentSection = AdminSection.dashboard;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, String Function(String) translate, UserProfile? profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Administrator Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${profile?.fullName ?? "Admin"}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Email: ${profile?.email ?? "admin@tnt.app"}'),
            const SizedBox(height: 6),
            Text('Role: ${profile?.role ?? "ADMIN"}', style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Verified At: ${DateTime.now().toLocal().toString().split('.').first}', style: const TextStyle(fontSize: 11, color: TNTColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String Function(String) translate) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: TNTColors.surface,
          title: Text(translate('logout')),
          content: const Text('Are you sure you want to log out of the Admin portal? All admin caches and session privileges will be securely cleared.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(translate('cancel'), style: const TextStyle(color: TNTColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // 1. Wipe all admin session tokens and caches
                _authService.clearSession();
                // 2. Perform authentication logout
                widget.authStateManager.signOut();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
