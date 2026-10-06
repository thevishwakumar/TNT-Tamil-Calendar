import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class PanchangamDateBar extends StatelessWidget {
  final DateTime selectedDate;
  final CalendarDay? calendarDay;
  final VoidCallback onPreviousDate;
  final VoidCallback onToday;
  final VoidCallback onNextDate;
  final Function(DateTime) onDateSelected;

  const PanchangamDateBar({
    super.key,
    required this.selectedDate,
    required this.calendarDay,
    required this.onPreviousDate,
    required this.onToday,
    required this.onNextDate,
    required this.onDateSelected,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  String _getDayName(int weekday, bool isTamil) {
    if (isTamil) {
      const days = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];
      return days[weekday - 1];
    } else {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[weekday - 1];
    }
  }

  String _getMonthName(int month, bool isTamil) {
    if (isTamil) {
      const months = ['ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'];
      return months[month - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[month - 1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    final tamilDateText = calendarDay != null
        ? '${calendarDay!.tamilMonth} ${calendarDay!.tamilDay}'
        : (isTamil ? 'புரட்டாசி ${selectedDate.day}' : 'Purattasi ${selectedDate.day}');

    final dayName = _getDayName(selectedDate.weekday, isTamil);
    final monthName = _getMonthName(selectedDate.month, isTamil);
    final englishDateText = '${selectedDate.day} $monthName ${selectedDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: TNTColors.primary,
                tooltip: translate('previous_day'),
                onPressed: onPreviousDate,
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: TNTColors.primary,
                            onPrimary: Colors.white,
                            onSurface: TNTColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: TNTColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        englishDateText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: TNTColors.textSecondary),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  if (!_isToday)
                    TextButton(
                      onPressed: onToday,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: TNTColors.primary.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        translate('today'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.primary,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: TNTColors.primary,
                    tooltip: translate('next_day'),
                    onPressed: onNextDate,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 12, color: TNTColors.border),
          // Tamil date & weekday details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wb_sunny_rounded, size: 16, color: TNTColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? 'தமிழ் தேதி' : 'Tamil Date',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: TNTColors.textMuted,
                        ),
                      ),
                      Text(
                        tamilDateText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TNTColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TNTColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: TNTColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
