import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class MuhurthamReminderDialog extends StatefulWidget {
  final MuhurthamDate muhurtham;
  final Function(String offsetLabel, DateTime scheduledTime) onConfirm;

  const MuhurthamReminderDialog({
    super.key,
    required this.muhurtham,
    required this.onConfirm,
  });

  @override
  _MuhurthamReminderDialogState createState() => _MuhurthamReminderDialogState();
}

class _MuhurthamReminderDialogState extends State<MuhurthamReminderDialog> {
  int _selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    final options = [
      {
        'title': localizations?.translate('reminder_1_day_before') ?? '1 Day Before (8:00 PM)',
        'subtitle': isTamil ? 'நிகழ்வுக்கு முந்தைய நாள் மாலை அறிவிப்பு' : 'Alert on evening prior to Muhurtham',
      },
      {
        'title': localizations?.translate('reminder_morning') ?? 'Day of Event at 6:00 AM',
        'subtitle': isTamil ? 'முகூர்த்த நாள் அதிகாலை நினைவூட்டல்' : 'Early morning notification on event day',
      },
      {
        'title': localizations?.translate('reminder_1_hour_before') ?? '1 Hour Before Muhurtham',
        'subtitle': isTamil ? 'சுப முகூர்த்த தொடக்கத்திற்கு 1 மணி நேரம் முன்' : '1 hour before auspicious start time',
      },
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: TNTColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TNTColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_add_rounded, color: TNTColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.translate('reminder_dialog_title') ?? 'Set Muhurtham Reminder',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.muhurtham.tamilDateStr} • ${widget.muhurtham.startTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: TNTColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: TNTColors.border, height: 1),
            const SizedBox(height: 12),

            ...List.generate(options.length, (index) {
              final opt = options[index];
              final isSelected = _selectedOption == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? TNTColors.primary.withValues(alpha: 0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? TNTColors.primary : TNTColors.border.withValues(alpha: 0.6),
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: _selectedOption,
                  activeColor: TNTColors.primary,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  title: Text(
                    opt['title']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? TNTColors.primaryDark : TNTColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    opt['subtitle']!,
                    style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedOption = val);
                    }
                  },
                ),
              );
            }),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TNTColors.textSecondary,
                      side: const BorderSide(color: TNTColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      localizations?.translate('cancel') ?? 'Cancel',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final chosen = options[_selectedOption]['title']!;
                      final mDate = widget.muhurtham.date;
                      DateTime scheduled;
                      if (_selectedOption == 0) {
                        scheduled = DateTime(mDate.year, mDate.month, mDate.day - 1, 20, 0);
                      } else if (_selectedOption == 1) {
                        scheduled = DateTime(mDate.year, mDate.month, mDate.day, 6, 0);
                      } else {
                        scheduled = DateTime(mDate.year, mDate.month, mDate.day, 5, 0);
                      }
                      Navigator.of(context).pop();
                      widget.onConfirm(chosen, scheduled);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TNTColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      localizations?.translate('set_reminder_btn') ?? 'Confirm',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
