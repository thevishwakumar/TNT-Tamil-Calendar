import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/tnt_reminder_dialog.dart';
import '../../models/tnt_models.dart';
import '../../services/reminder_service.dart';
import '../../muhurtham/screens/muhurtham_detail_screen.dart';
import '../../festivals/screens/festival_detail_screen.dart';
import '../../special_days/screens/special_day_detail_screen.dart';

/// Dedicated Reminders Screen
/// Shows:
/// - Upcoming, Past, All
/// - Each card displays: Item type, Title, Date, Reminder time, Status toggle, Open item, Remove
class RemindersScreen extends StatefulWidget {
  final dynamic apiService;

  const RemindersScreen({super.key, this.apiService});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _service = ReminderService();
  ReminderFilter _selectedFilter = ReminderFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _service.refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<Reminder> get _filteredReminders {
    return _service.getRemindersByFilter(_selectedFilter);
  }

  void _openItem(Reminder reminder) {
    if (reminder.itemType == 'muhurtham') {
      final m = MuhurthamDate(
        id: reminder.itemId,
        date: reminder.reminderAt,
        tamilDateStr: '',
        startTime: '09:15 AM',
        endTime: '10:30 AM',
        isValarthirai: true,
        category: reminder.subtitle.isNotEmpty ? reminder.subtitle : 'Marriage',
        categoryTa: 'சுப முகூர்த்தம்',
        description: reminder.title,
        descriptionTa: reminder.titleTa,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MuhurthamDetailScreen(
            muhurtham: m,
            apiService: widget.apiService /* SupabaseApiService() */,
          ),
        ),
      );
    } else if (reminder.itemType == 'festival') {
      final f = Festival(
        id: reminder.itemId,
        name: reminder.title,
        nameTa: reminder.titleTa,
        date: reminder.reminderAt,
        type: 'hindu',
        category: reminder.subtitle.isNotEmpty ? reminder.subtitle : 'Festivals',
        description: reminder.title,
        descriptionTa: reminder.titleTa,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FestivalDetailScreen(
            festival: f,
            apiService: widget.apiService /* SupabaseApiService() */,
          ),
        ),
      );
    } else if (reminder.itemType == 'special_day') {
      final s = SpecialDay(
        id: reminder.itemId,
        date: reminder.reminderAt,
        title: reminder.title,
        titleTa: reminder.titleTa,
        category: reminder.subtitle.isNotEmpty ? reminder.subtitle : 'Special Day',
        isHoliday: false,
        description: reminder.title,
        descriptionTa: reminder.titleTa,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpecialDayDetailScreen(
            specialDay: s,
            apiService: widget.apiService /* SupabaseApiService() */,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${reminder.title}')),
      );
    }
  }

  String _formatDateTime(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} at $hour:$minute $ampm';
  }

  Color _getItemTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'festival':
        return Colors.purple;
      case 'muhurtham':
        return TNTColors.accent;
      case 'special_day':
        return Colors.orange.shade800;
      case 'panchangam':
        return Colors.teal;
      default:
        return TNTColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = TNTLocalizationsProvider.of(context)?.localizations;
    final isTa = Localizations.localeOf(context).languageCode == "ta" ?? false;
    final reminders = _filteredReminders;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isTa ? 'நினைவூட்டல்கள்' : 'Reminders',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: isTa ? 'புதிய நினைவூட்டல்' : 'New Reminder',
            icon: const Icon(Icons.add_alarm, color: Colors.white),
            onPressed: () {
              TNTReminderDialog.show(
                context,
                itemType: 'custom',
                itemId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                title: 'TNT Custom Reminder',
                titleTa: 'விசேஷ நினைவூட்டல்',
                eventDate: DateTime.now().add(const Duration(days: 1)),
              );
            },
          ),
          IconButton(
            tooltip: isTa ? 'புதுப்பி' : 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _service.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Upcoming, Past, All)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterTab(
                  ReminderFilter.upcoming,
                  isTa ? 'வரவிருப்பவை' : 'Upcoming',
                  _service.getRemindersByFilter(ReminderFilter.upcoming).length,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  ReminderFilter.past,
                  isTa ? 'கடந்தவை' : 'Past',
                  _service.getRemindersByFilter(ReminderFilter.past).length,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  ReminderFilter.all,
                  isTa ? 'அனைத்தும்' : 'All',
                  _service.reminders.length,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: TNTColors.border),

          // Reminders list
          Expanded(
            child: _service.isLoading
                ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
                : reminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: TNTColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.alarm_off, size: 48, color: TNTColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isTa ? 'நினைவூட்டல்கள் எதுவும் இல்லை' : 'No reminders found',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                isTa
                                    ? 'பண்டிகைகள், விசேஷ நாட்கள் அல்லது முகூர்த்த தேதிகளுக்கு நினைவூட்டல் அமைக்க அலாரம் ஐகானைத் தட்டவும்.'
                                    : 'Schedule reminders for upcoming festivals, muhurthams, and special observances.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _service.refresh(),
                        color: TNTColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reminders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final r = reminders[index];
                            final isPast = r.reminderAt.isBefore(DateTime.now());
                            final typeColor = _getItemTypeColor(r.itemType);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: r.isSet ? TNTColors.border : TNTColors.border.withValues(alpha: 0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top type badge and active switch
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          r.itemType.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                      if (isPast) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isTa ? 'முடிந்தது' : 'Past',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      // Active Toggle
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: r.isSet,
                                          activeThumbColor: TNTColors.primary,
                                          onChanged: (val) {
                                            _service.toggleReminderStatus(r.id, val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Title
                                  Text(
                                    isTa && r.titleTa.isNotEmpty ? r.titleTa : r.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: r.isSet ? TNTColors.textPrimary : TNTColors.textSecondary,
                                    ),
                                  ),
                                  if (r.titleTa.isNotEmpty && !isTa)
                                    Text(
                                      r.titleTa,
                                      style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                                    ),

                                  const SizedBox(height: 10),

                                  // Time row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: r.isSet ? TNTColors.primary : TNTColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDateTime(r.reminderAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: r.isSet ? TNTColors.primary : TNTColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.tune, size: 13, color: TNTColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        r.reminderType.replaceAll('_', ' '),
                                        style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: TNTColors.border),
                                  const SizedBox(height: 6),

                                  // Action links: Open item, delete
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        icon: const Icon(Icons.open_in_new, size: 14, color: TNTColors.primary),
                                        label: Text(
                                          isTa ? 'விவரம் பார்க்க' : 'Open Item',
                                          style: const TextStyle(fontSize: 12, color: TNTColors.primary),
                                        ),
                                        onPressed: () => _openItem(r),
                                      ),
                                      IconButton(
                                        tooltip: isTa ? 'நீக்க' : 'Delete',
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        onPressed: () async {
                                          await _service.removeReminder(r.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(isTa ? 'நினைவூட்டல் நீக்கப்பட்டது' : 'Reminder removed')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(ReminderFilter filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TNTColors.primary : TNTColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : TNTColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
