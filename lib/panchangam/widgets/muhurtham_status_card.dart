import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class MuhurthamStatusCard extends StatelessWidget {
  final List<MuhurthamDate> muhurthams;
  final VoidCallback? onExploreMuhurthams;

  const MuhurthamStatusCard({
    super.key,
    required this.muhurthams,
    this.onExploreMuhurthams,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    final hasMuhurtham = muhurthams.isNotEmpty;

    if (!hasMuhurtham) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TNTColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TNTColors.textMuted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, size: 16, color: TNTColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                translate('no_muhurtham'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: TNTColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final m = muhurthams.first;
    final isValarpirai = m.isValarthirai;
    final piraiText = isValarpirai ? translate('valarpirai') : translate('theipirai');
    final desc = isTamil ? m.descriptionTa : m.description;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.auspicious.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: TNTColors.auspicious.withValues(alpha: 0.04),
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
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: TNTColors.auspicious.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 18, color: TNTColors.auspicious),
                    const SizedBox(width: 8),
                    Text(
                      translate('muhurtham_available'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.auspicious,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TNTColors.auspicious.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    piraiText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: TNTColors.auspicious,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTamil ? 'முகூர்த்த நேரம்' : 'Muhurtham Time',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TNTColors.textMuted,
                      ),
                    ),
                    Text(
                      '${m.startTime} - ${m.endTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTamil ? 'நோக்கம் / காரியம்' : 'Purpose / Occasion',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TNTColors.textMuted,
                      ),
                    ),
                    Text(
                      m.category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TNTColors.primary,
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
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
        ],
      ),
    );
  }
}
