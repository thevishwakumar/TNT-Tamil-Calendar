import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../notifications/repositories/admin_campaign_repository.dart';
import '../repositories/admin_content_repository.dart';
import '../notifications/screens/admin_campaign_create_screen.dart';
import '../festivals_management/admin_festivals_screen.dart';

/// Admin Content & Campaign Master Calendar
class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  _AdminCalendarScreenState createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  final AdminCampaignRepository _campaignRepo = AdminCampaignRepository();
  final AdminContentRepository _contentRepo = AdminContentRepository();

  List<NotificationCampaign> _allCampaigns = [];
  List<Festival> _allFestivals = [];
  List<SpecialDay> _allSpecialDays = [];

  @override
  void initState() {
    super.initState();
    _loadAllCalendarData();
  }

  Future<void> _loadAllCalendarData() async {
    setState(() => _isLoading = true);
    try {
      final campaigns = await _campaignRepo.getCampaigns(limit: 500);
      final festivals = await _contentRepo.getAdminFestivals();
      final specialDays = await _contentRepo.getAdminSpecialDays();

      if (mounted) {
        setState(() {
          _allCampaigns = campaigns;
          _allFestivals = festivals;
          _allSpecialDays = specialDays;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NotificationCampaign> get _selectedDateCampaigns {
    return _allCampaigns.where((c) {
      if (c.scheduledAt == null) return false;
      final d = c.scheduledAt!;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day;
    }).toList();
  }

  List<Festival> get _selectedDateFestivals {
    return _allFestivals.where((f) {
      final d = f.date;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day;
    }).toList();
  }

  List<SpecialDay> get _selectedDateSpecialDays {
    return _allSpecialDays.where((s) {
      final d = s.date;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text('Campaign & Content Calendar',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: _loadAllCalendarData,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: TNTColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAllCalendarData,
              color: TNTColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master Calendar Selector
                    Card(
                      color: TNTColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: TNTColors.border)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Master Schedule',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: TNTColors.textPrimary)),
                                Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: TNTColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CalendarDatePicker(
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              onDateChanged: (d) =>
                                  setState(() => _selectedDate = d),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scheduled Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Scheduled for ${_selectedDate.day}/${_selectedDate.month}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.textPrimary)),
                        // Quick Action Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.add_circle_rounded,
                              color: TNTColors.primary),
                          onSelected: (val) {
                            if (val == 'campaign') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => AdminCampaignCreateScreen(
                                            initialCampaign:
                                                null, // we could prefill the date in the future
                                            onSaved: _loadAllCalendarData,
                                          )));
                            } else if (val == 'festival') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminFestivalsScreen()));
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'campaign',
                                child: Text('Schedule Campaign')),
                            const PopupMenuItem(
                                value: 'festival',
                                child: Text('Manage Festivals')),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Event List View
                    _buildDailyAgenda(),

                    const SizedBox(height: 80), // Padding for scrolling
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailyAgenda() {
    final campaigns = _selectedDateCampaigns;
    final festivals = _selectedDateFestivals;
    final specialDays = _selectedDateSpecialDays;

    if (campaigns.isEmpty && festivals.isEmpty && specialDays.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TNTColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_available_rounded,
                size: 40, color: TNTColors.textMuted),
            SizedBox(height: 10),
            Text('No events or campaigns scheduled.',
                style: TextStyle(
                    color: TNTColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...festivals.map((f) => _buildAgendaItem(
              icon: Icons.celebration_rounded,
              color: Colors.orange,
              title: f.name,
              subtitle: 'Festival r% ${f.nameTa}',
            )),
        ...specialDays.map((s) => _buildAgendaItem(
              icon: Icons.star_rounded,
              color: Colors.purple,
              title: s.title,
              subtitle: 'Special Day r% ${s.titleTa}',
            )),
        ...campaigns.map((c) => _buildAgendaItem(
              icon: Icons.campaign_rounded,
              color: TNTColors.primary,
              title: c.title,
              subtitle: 'Push Campaign r% Status: ${c.status}',
            )),
      ],
    );
  }

  Widget _buildAgendaItem(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: TNTColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: TNTColors.textPrimary)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 16, color: TNTColors.textMuted),
      ),
    );
  }
}
