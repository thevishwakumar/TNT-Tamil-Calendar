import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class MuhurthamDateCard extends StatelessWidget {
  final MuhurthamDate item;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;
  final VoidCallback onSetReminder;
  final VoidCallback onShare;

  const MuhurthamDateCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleSave,
    required this.onSetReminder,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    final phaseText = item.isValarthirai
        ? (localizations?.translate('valarpirai') ?? 'Valarpirai')
        : (localizations?.translate('theipirai') ?? 'Theipirai');

    final categoryDisplay = isTamil ? item.categoryTa : item.category;
    final categoryIcon = _getCategoryIcon(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isValarthirai ? TNTColors.auspicious.withValues(alpha: 0.25) : TNTColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top strip: Auspicious Status & Phase
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: item.isValarthirai 
                      ? const Color(0xFFF0FDF4) 
                      : const Color(0xFFFFFBEB),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  border: Border(
                    bottom: BorderSide(
                      color: item.isValarthirai ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: item.isValarthirai ? const Color(0xFF16A34A) : TNTColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          localizations?.translate('approved_muhurtham') ?? 'Approved Muhurtham',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isValarthirai ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isValarthirai ? Colors.white : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: item.isValarthirai ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Text(
                        phaseText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.isValarthirai ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Date + Category Header
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gregorian Date Badge
                    Container(
                      width: 56,
                      height: 58,
                      decoration: BoxDecoration(
                        color: TNTColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item.date.day}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: TNTColors.primary,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            isTamil ? item.dayOfWeekTa : (item.dayOfWeekEn.length >= 3 ? item.dayOfWeekEn.substring(0, 3) : item.dayOfWeekEn).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: TNTColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Tamil Date, Category & Purpose
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.tamilDateStr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: TNTColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(categoryIcon, size: 11, color: TNTColors.primaryDark),
                                    const SizedBox(width: 4),
                                    Text(
                                      categoryDisplay,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: TNTColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.tamilMonth} | ${isTamil ? item.nakshatraTa : item.nakshatra}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TNTColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Auspicious Time Range Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TNTColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: TNTColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 12, color: TNTColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  '${item.startTime} - ${item.endTime}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: TNTColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${item.duration})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: TNTColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Purpose & Notes snippet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Text(
                  isTamil ? item.suitablePurposeTa : item.suitablePurpose,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TNTColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Divider
              Container(height: 1, color: TNTColors.border.withValues(alpha: 0.6)),

              // Action Toolbar: Save, Reminder, Share
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      icon: item.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      iconColor: item.isSaved ? TNTColors.primary : TNTColors.textSecondary,
                      label: localizations?.translate('save_btn') ?? 'Save',
                      onPressed: onToggleSave,
                    ),
                  ),
                  Container(width: 1, height: 36, color: TNTColors.border.withValues(alpha: 0.6)),
                  Expanded(
                    child: _buildActionBtn(
                      icon: item.hasReminder ? Icons.notifications_active_rounded : Icons.add_alarm_rounded,
                      iconColor: item.hasReminder ? TNTColors.auspicious : TNTColors.textSecondary,
                      label: localizations?.translate('reminder_btn') ?? 'Reminder',
                      onPressed: onSetReminder,
                    ),
                  ),
                  Container(width: 1, height: 36, color: TNTColors.border.withValues(alpha: 0.6)),
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.share_outlined,
                      iconColor: TNTColors.textSecondary,
                      label: localizations?.translate('share_btn') ?? 'Share',
                      onPressed: onShare,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TNTColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'marriage':
        return Icons.favorite_rounded;
      case 'housewarming':
        return Icons.home_rounded;
      case 'engagement':
        return Icons.diamond_outlined;
      case 'business':
        return Icons.store_rounded;
      case 'naming ceremony':
        return Icons.child_care_rounded;
      case 'vehicle purchase':
        return Icons.directions_car_rounded;
      default:
        return Icons.celebration_rounded;
    }
  }
}
