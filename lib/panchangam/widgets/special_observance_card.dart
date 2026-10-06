import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';
import '../../special_days/screens/special_day_detail_screen.dart';
import '../../festivals/screens/festival_detail_screen.dart';

class SpecialObservanceCard extends StatelessWidget {
  final List<SpecialDay> specialDays;
  final List<Festival> festivals;

  const SpecialObservanceCard({
    super.key,
    required this.specialDays,
    required this.festivals,
  });

  IconData _getIconForObservance(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('amavasai') || lower.contains('அமாவாசை')) {
      return Icons.circle_outlined;
    } else if (lower.contains('pournami') || lower.contains('பௌர்ணமி')) {
      return Icons.circle;
    } else if (lower.contains('pradosham') || lower.contains('பிரதோஷம்')) {
      return Icons.brightness_auto_rounded;
    } else if (lower.contains('sashti') || lower.contains('சஷ்டி')) {
      return Icons.local_fire_department_rounded;
    } else if (lower.contains('ekadashi') || lower.contains('ஏகாதசி')) {
      return Icons.spa_rounded;
    } else if (lower.contains('krithigai') || lower.contains('கிருத்திகை')) {
      return Icons.flare_rounded;
    } else if (lower.contains('chaturthi') || lower.contains('சதுர்த்தி')) {
      return Icons.star_rounded;
    }
    return Icons.event_note_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Only display when approved data exists
    if (specialDays.isEmpty && festivals.isEmpty) {
      return const SizedBox.shrink();
    }

    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E5F5), // Soft purple tint for spiritual observances
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: TNTColors.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.temple_hindu_rounded, size: 18, color: Color(0xFF7B1FA2)),
                    const SizedBox(width: 8),
                    Text(
                      translate('todays_special'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${specialDays.length + festivals.length} ${isTamil ? 'சிறப்புகள்' : 'Events'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Render Special Days
                ...specialDays.map((sd) {
                  final title = isTamil ? sd.titleTa : sd.title;
                  final desc = isTamil ? sd.descriptionTa : sd.description;
                  final icon = _getIconForObservance(sd.title);

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpecialDayDetailScreen(specialDay: sd),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TNTColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TNTColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, size: 18, color: const Color(0xFF7B1FA2)),
                            ),
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
                                          title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: TNTColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (sd.isHoliday)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isTamil ? 'அரசு விடுமுறை' : 'Govt Holiday',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: TNTColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: TNTColors.textSecondary),
                          ],
                        ),
                      ),
                    );
                  }),

                // Render Festivals
                ...festivals.map((fest) {
                  final name = isTamil ? fest.nameTa : fest.name;
                  final desc = isTamil ? fest.descriptionTa : fest.description;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FestivalDetailScreen(festival: fest),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TNTColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TNTColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TNTColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.celebration_rounded, size: 18, color: TNTColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: TNTColors.primary,
                                  ),
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TNTColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: TNTColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );

  }
}
