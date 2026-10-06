import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class SunMoonCard extends StatelessWidget {
  final PanchangamEntry panchangam;

  const SunMoonCard({
    super.key,
    required this.panchangam,
  });

  String _cleanValue(String? val, String fallback) {
    if (val == null || val.trim().isEmpty || val == '--:--' || val == '--') {
      return fallback;
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;
    final unavailable = translate('data_unavailable');

    final sunrise = _cleanValue(panchangam.sunrise, unavailable);
    final sunset = _cleanValue(panchangam.sunset, unavailable);
    final moonrise = _cleanValue(panchangam.moonrise, unavailable);
    final moonset = _cleanValue(panchangam.moonset, unavailable);
    final dayDuration = _cleanValue(panchangam.dayDuration, unavailable);
    final nightDuration = _cleanValue(panchangam.nightDuration, unavailable);

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
              color: Color(0xFFFFF8E1), // Warm amber tint for celestial section
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: TNTColors.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_twilight_rounded, size: 18, color: Color(0xFFF57C00)),
                    const SizedBox(width: 8),
                    Text(
                      translate('sun_moon_timings'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  isTamil ? 'சூரிய & சந்திர இயக்கம்' : 'Celestial Transit',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFF57C00), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Sunrise / Sunset Row
                Row(
                  children: [
                    Expanded(
                      child: _buildCelestialCell(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFFFFA000),
                        label: translate('sunrise'),
                        value: sunrise,
                        isUnavailable: sunrise == unavailable,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCelestialCell(
                        icon: Icons.nights_stay_rounded,
                        iconColor: const Color(0xFFFF7043),
                        label: translate('sunset'),
                        value: sunset,
                        isUnavailable: sunset == unavailable,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Moonrise / Moonset Row
                Row(
                  children: [
                    Expanded(
                      child: _buildCelestialCell(
                        icon: Icons.nightlight_outlined,
                        iconColor: const Color(0xFF5C6BC0),
                        label: translate('moonrise'),
                        value: moonrise,
                        isUnavailable: moonrise == unavailable,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCelestialCell(
                        icon: Icons.brightness_2_outlined,
                        iconColor: const Color(0xFF7E57C2),
                        label: translate('moonset'),
                        value: moonset,
                        isUnavailable: moonset == unavailable,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Day & Night Duration Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TNTColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TNTColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDurationItem(
                        icon: Icons.light_mode_outlined,
                        label: translate('day_duration'),
                        value: dayDuration,
                        unavailable: unavailable,
                      ),
                      Container(width: 1, height: 26, color: TNTColors.border),
                      _buildDurationItem(
                        icon: Icons.dark_mode_outlined,
                        label: translate('night_duration'),
                        value: nightDuration,
                        unavailable: unavailable,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialCell({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isUnavailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TNTColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TNTColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TNTColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isUnavailable ? TNTColors.textMuted : TNTColors.textPrimary,
                    fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationItem({
    required IconData icon,
    required String label,
    required String value,
    required String unavailable,
  }) {
    final isUnavail = value == unavailable;
    return Row(
      children: [
        Icon(icon, size: 16, color: TNTColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: TNTColors.textMuted, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUnavail ? TNTColors.textMuted : TNTColors.textPrimary,
                fontStyle: isUnavail ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
