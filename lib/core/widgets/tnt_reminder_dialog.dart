import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../localization/tnt_localizations.dart';
import '../../services/reminder_service.dart';

/// Centralized Reusable Reminder Dialog
/// Opens for Panchangam, Muhurtham, Festivals, and Special Days.
class TNTReminderDialog extends StatefulWidget {
  final String itemType;
  final String itemId;
  final String title;
  final String titleTa;
  final String subtitle;
  final String subtitleTa;
  final DateTime eventDate;
  final String? startTime;

  const TNTReminderDialog({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.title,
    this.titleTa = '',
    this.subtitle = '',
    this.subtitleTa = '',
    required this.eventDate,
    this.startTime,
  });

  static Future<void> show(
    BuildContext context, {
    required String itemType,
    required String itemId,
    required String title,
    String titleTa = '',
    String subtitle = '',
    String subtitleTa = '',
    required DateTime eventDate,
    String? startTime,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TNTReminderDialog(
        itemType: itemType,
        itemId: itemId,
        title: title,
        titleTa: titleTa,
        subtitle: subtitle,
        subtitleTa: subtitleTa,
        eventDate: eventDate,
        startTime: startTime,
      ),
    );
  }

  @override
  _TNTReminderDialogState createState() => _TNTReminderDialogState();
}

class _TNTReminderDialogState extends State<TNTReminderDialog> {
  String _selectedPreset = '1_day_before'; // '1_day_before' | 'morning_6am' | '1_hour_before' | 'custom'
  TimeOfDay _customTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    final displayTitle = isTamil 
        ? (widget.titleTa.isNotEmpty ? widget.titleTa : widget.title)
        : (widget.title.isNotEmpty ? widget.title : widget.titleTa);

    return AlertDialog(
      backgroundColor: TNTColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TNTColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, size: 20, color: TNTColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil ? 'நினைவூட்டல் அமைக்கவும்' : 'Set Reminder Alert',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                Text(
                  displayTitle,
                  style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: TNTColors.border, height: 16),
            Text(
              isTamil ? 'நினைவூட்டல் நேரத்தைத் தேர்ந்தெடுக்கவும்:' : 'Choose Notification Timing:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
            ),
            const SizedBox(height: 10),

            // Option 1: 1 Day Before (8:00 PM)
            _buildPresetOption(
              key: '1_day_before',
              title: isTamil ? '1 நாளுக்கு முன் (முந்தைய நாள் இரவு 8:00)' : '1 Day Before (8:00 PM)',
              subtitle: isTamil ? 'முன் தயாரிப்புகளுக்கு உகந்தது' : 'Recommended for planning ahead',
            ),

            // Option 2: Morning of Event (6:00 AM)
            _buildPresetOption(
              key: 'morning_6am',
              title: isTamil ? 'நிகழ்வு அன்று அதிகாலை (காலை 6:00)' : 'Day of Event Morning (6:00 AM)',
              subtitle: isTamil ? 'பூஜை மற்றும் வழிபாட்டிற்கு' : 'For morning puja and rituals',
            ),

            // Option 3: 1 Hour Before
            _buildPresetOption(
              key: '1_hour_before',
              title: isTamil ? '1 மணி நேரம் முன்' : '1 Hour Before Window',
              subtitle: widget.startTime != null 
                  ? (isTamil ? 'நேரம்: ${widget.startTime}' : 'Event starts at ${widget.startTime}')
                  : (isTamil ? 'சுப முகூர்த்த / நிகழ்வு தொடக்கத்திற்கு முன்' : 'Before auspicious window starts'),
            ),

            // Option 4: Custom Time
            _buildPresetOption(
              key: 'custom',
              title: isTamil ? 'விருப்ப நேரம் (Custom Time)' : 'Custom Time',
              subtitle: _customTime.format(context),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _customTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _customTime = picked;
                      _selectedPreset = 'custom';
                    });
                  }
                },
                child: Text(
                  isTamil ? 'மாற்று' : 'Pick Time',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            isTamil ? 'ரத்து' : 'Cancel',
            style: const TextStyle(color: TNTColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final reminderService = ReminderService();
            String reminderTimeString = '08:00 PM';
            DateTime reminderAt = widget.eventDate;

            if (_selectedPreset == '1_day_before') {
              reminderTimeString = '08:00 PM';
              reminderAt = DateTime(widget.eventDate.year, widget.eventDate.month, widget.eventDate.day - 1, 20, 0);
            } else if (_selectedPreset == 'morning_6am') {
              reminderTimeString = '06:00 AM';
              reminderAt = DateTime(widget.eventDate.year, widget.eventDate.month, widget.eventDate.day, 6, 0);
            } else if (_selectedPreset == '1_hour_before') {
              reminderTimeString = widget.startTime ?? '07:00 AM';
              reminderAt = widget.eventDate.subtract(const Duration(hours: 1));
            } else if (_selectedPreset == 'custom') {
              reminderTimeString = _customTime.format(context);
              reminderAt = DateTime(
                widget.eventDate.year,
                widget.eventDate.month,
                widget.eventDate.day,
                _customTime.hour,
                _customTime.minute,
              );
            }

            await reminderService.setReminder(
              itemType: widget.itemType,
              itemId: widget.itemId,
              title: widget.title,
              titleTa: widget.titleTa,
              subtitle: widget.subtitle,
              subtitleTa: widget.subtitleTa,
              eventDate: widget.eventDate,
              reminderTime: reminderTimeString,
              reminderAt: reminderAt,
              reminderType: _selectedPreset,
            );

            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: TNTColors.primary,
                  duration: const Duration(seconds: 3),
                  content: Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTamil 
                              ? 'நினைவூட்டல் $reminderTimeString மணிக்கு அமைக்கப்பட்டது!' 
                              : 'Reminder set for $reminderTimeString!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: TNTColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(
            isTamil ? 'உறுதி செய்' : 'Confirm',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetOption({
    required String key,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final isSelected = _selectedPreset == key;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPreset = key;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? TNTColors.primary.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? TNTColors.primary : TNTColors.border.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? TNTColors.primary : TNTColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: TNTColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
