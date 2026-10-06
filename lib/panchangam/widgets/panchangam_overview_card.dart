import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class PanchangamOverviewCard extends StatelessWidget {
  final PanchangamEntry panchangam;
  final CalendarDay? calendarDay;
  final DateTime date;

  const PanchangamOverviewCard({
    super.key,
    required this.panchangam,
    required this.calendarDay,
    required this.date,
  });

  String _getDayName(int weekday, bool isTamil) {
    if (isTamil) {
      const days = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];
      return days[weekday - 1];
    } else {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[weekday - 1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    final pakshaValue = isTamil ? panchangam.pakshaTa : panchangam.paksha;
    final tithiValue = isTamil ? panchangam.tithiTa : panchangam.tithi;
    final nakshatraValue = isTamil ? panchangam.nakshatraTa : panchangam.nakshatra;
    final yogaValue = isTamil ? panchangam.yogaTa : panchangam.yoga;
    final karanaValue = isTamil ? panchangam.karanaTa : panchangam.karana;

    final tamilMonth = calendarDay?.tamilMonth ?? (isTamil ? 'புரட்டாசி' : 'Purattasi');
    final tamilYear = calendarDay?.tamilYear ?? (isTamil ? 'குரோதி' : 'Krodhi');
    final tamilDayNum = calendarDay?.tamilDay ?? date.day;
    final dayOfWeek = _getDayName(date.weekday, isTamil);

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
          // Section header with Paksha badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TNTColors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: const Border(bottom: BorderSide(color: TNTColors.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 18, color: TNTColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      translate('panchangam_overview'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TNTColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        panchangam.paksha.contains('Shukla')
                            ? Icons.brightness_high_rounded
                            : Icons.brightness_3_rounded,
                        size: 13,
                        color: TNTColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pakshaValue,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Date & Month Quick Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    isTamil ? 'தமிழ் மாதம் & ஆண்டு' : 'Tamil Month & Year',
                    '$tamilMonth, $tamilYear',
                    Icons.calendar_today_rounded,
                  ),
                ),
                Container(width: 1, height: 32, color: TNTColors.border),
                Expanded(
                  child: _buildMiniStat(
                    isTamil ? 'கிழமை / நாள்' : 'Day / Tamil Date',
                    '$dayOfWeek · $tamilDayNum',
                    Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TNTColors.border),

          // 4 Core Panchangam Angas Grid (Tithi, Nakshatra, Yoga, Karana)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAngaRow(
                  label: translate('tithi'),
                  englishLabel: 'Tithi',
                  value: tithiValue,
                  icon: Icons.shield_moon_outlined,
                  isTamil: isTamil,
                ),
                const SizedBox(height: 12),
                _buildAngaRow(
                  label: translate('nakshatra'),
                  englishLabel: 'Nakshatra',
                  value: nakshatraValue,
                  icon: Icons.star_border_rounded,
                  isTamil: isTamil,
                ),
                const SizedBox(height: 12),
                _buildAngaRow(
                  label: translate('yoga'),
                  englishLabel: 'Yoga',
                  value: yogaValue,
                  icon: Icons.grain_rounded,
                  isTamil: isTamil,
                ),
                const SizedBox(height: 12),
                _buildAngaRow(
                  label: translate('karana'),
                  englishLabel: 'Karana',
                  value: karanaValue,
                  icon: Icons.blur_circular_rounded,
                  isTamil: isTamil,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: TNTColors.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAngaRow({
    required String label,
    required String englishLabel,
    required String value,
    required IconData icon,
    required bool isTamil,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TNTColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TNTColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TNTColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: TNTColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TNTColors.textMuted,
                      ),
                    ),
                    if (isTamil)
                      Text(
                        '($englishLabel)',
                        style: TextStyle(
                          fontSize: 10,
                          color: TNTColors.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: TNTColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

