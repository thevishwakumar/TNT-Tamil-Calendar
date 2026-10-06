import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class TimingCard extends StatelessWidget {
  final TimingEntry timing;

  const TimingCard({
    super.key,
    required this.timing,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    final displayName = isTamil ? timing.nameTa : timing.name;
    final secondaryName = isTamil ? timing.name : timing.nameTa;
    final desc = isTamil ? timing.descriptionTa : timing.description;

    final isAuspicious = timing.isAuspicious;
    final badgeColor = isAuspicious ? TNTColors.auspicious : TNTColors.inauspicious;
    final badgeBg = isAuspicious
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAuspicious
              ? TNTColors.auspicious.withValues(alpha: 0.3)
              : TNTColors.inauspicious.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timing Name & Auspicious Indicator — Expanded so it never overflows
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isAuspicious ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          size: 16,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.textPrimary,
                              ),
                            ),
                            if (secondaryName.isNotEmpty) ...[
                              Text(
                                secondaryName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TNTColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                // Timing Period Badge — stays compact on the right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${timing.startTime} - ${timing.endTime}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAuspicious ? translate('auspicious_time') : translate('inauspicious_time'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TNTColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TNTColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



