import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../widgets/muhurtham_reminder_dialog.dart';
import '../widgets/muhurtham_share_sheet.dart';

class MuhurthamDetailScreen extends StatefulWidget {
  final MuhurthamDate muhurtham;
  final ITNTApiService apiService;
  final Function(int tabIndex)? onNavigateTab;

  const MuhurthamDetailScreen({
    super.key,
    required this.muhurtham,
    required this.apiService,
    this.onNavigateTab,
  });

  @override
  _MuhurthamDetailScreenState createState() => _MuhurthamDetailScreenState();
}

class _MuhurthamDetailScreenState extends State<MuhurthamDetailScreen> {
  late MuhurthamDate _current;

  @override
  void initState() {
    super.initState();
    _current = widget.muhurtham;
  }

  void _toggleSave() async {
    final nextSaved = !_current.isSaved;
    setState(() {
      _current = _current.copyWith(isSaved: nextSaved);
    });

    try {
      await widget.apiService.toggleSaveItem('muhurtham', _current.id);
      final localizations = TNTLocalizationsProvider.of(context)?.localizations;
      final msg = nextSaved
          ? (localizations?.translate('save_muhurtham') ?? 'Muhurtham Saved')
          : (localizations?.translate('remove_muhurtham') ?? 'Muhurtham Removed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: TNTColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {}
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => MuhurthamReminderDialog(
        muhurtham: _current,
        onConfirm: (label, scheduledTime) async {
          setState(() {
            _current = _current.copyWith(hasReminder: true);
          });
          try {
            await widget.apiService.setReminder(
              '${_current.category} - ${_current.tamilDateStr}',
              _current.date,
              _current.startTime,
            );
          } catch (_) {}
          final localizations = TNTLocalizationsProvider.of(context)?.localizations;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${localizations?.translate('reminder_set') ?? 'Reminder Set'}: $label',
              ),
              backgroundColor: TNTColors.auspicious,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MuhurthamShareSheet(muhurtham: _current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isTamil ? _current.categoryTa : _current.category,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: TNTColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [ const TNTBrandHeader(), 
          IconButton(
            icon: Icon(
              _current.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: _current.isSaved ? TNTColors.primary : TNTColors.textSecondary,
            ),
            onPressed: _toggleSave,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: TNTColors.textSecondary),
            onPressed: _showShareSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Hero Header Banner
            _buildHeroBanner(isTamil, localizations),
            const SizedBox(height: 16),

            // B. Approved Muhurtham Timings Breakdown
            _buildTimingsSection(isTamil, localizations),
            const SizedBox(height: 16),

            // C. Panchangam Astrological Alignment
            _buildPanchangamAlignmentCard(isTamil, localizations),
            const SizedBox(height: 16),

            // D. Inauspicious Timings to Avoid (Rahu Kalam, Yamagandam, Kuligai)
            _buildInauspiciousTimesCard(isTamil, localizations),
            const SizedBox(height: 16),

            // E. Astrological Guidance & Important Notes
            _buildNotesCard(isTamil, localizations),
            const SizedBox(height: 24),

            // Deep link action to Panchangam
            _buildPanchangamLinkButton(isTamil, localizations),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(isTamil, localizations),
    );
  }

  Widget _buildHeroBanner(bool isTamil, TNTLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 5),
                    Text(
                      _current.approvedStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _current.isValarthirai ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _current.isValarthirai ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  _current.isValarthirai
                      ? (localizations?.translate('valarpirai') ?? 'Valarpirai')
                      : (localizations?.translate('theipirai') ?? 'Theipirai'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _current.isValarthirai ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date Headline
          Text(
            '${_current.date.day} ${_getMonthName(_current.date.month, isTamil)} ${_current.date.year}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: TNTColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_current.tamilDateStr} • ${_current.tamilMonth} • ${_current.tamilYear}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TNTColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${isTamil ? _current.dayOfWeekTa : _current.dayOfWeekEn} | ${_current.location}',
            style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: TNTColors.border),
          const SizedBox(height: 12),

          // Purpose
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.stars_rounded, color: TNTColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTamil ? _current.suitablePurposeTa : _current.suitablePurpose,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TNTColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsSection(bool isTamil, TNTLocalizations? localizations) {
    final timings = _current.timings.isNotEmpty
        ? _current.timings
        : [
            MuhurthamTimingItem(
              startTime: _current.startTime,
              endTime: _current.endTime,
              duration: _current.duration,
              lagnam: _current.lagnam,
              lagnamTa: _current.lagnamTa,
              nakshatra: _current.nakshatra,
              nakshatraTa: _current.nakshatraTa,
              subhaHorai: _current.subhaHorai,
              subhaHoraiTa: _current.subhaHoraiTa,
              description: 'Primary auspicious wedding ceremony time',
              descriptionTa: 'மாங்கல்ய தாரணம் செய்வதற்கான முதன்மை நன்னேரம்',
              isPrime: true,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_on_rounded, color: TNTColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                localizations?.translate('available_timings') ?? 'Available Muhurtham Timings',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...timings.map((t) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: TNTColors.primaryDark),
                          const SizedBox(width: 6),
                          Text(
                            '${t.startTime} - ${t.endTime}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: TNTColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TNTColors.border),
                        ),
                        child: Text(
                          t.duration,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip(Icons.temple_hindu_rounded, isTamil ? t.lagnamTa : t.lagnam),
                      _buildChip(Icons.auto_awesome_rounded, isTamil ? t.nakshatraTa : t.nakshatra),
                      _buildChip(Icons.wb_sunny_rounded, isTamil ? t.subhaHoraiTa : t.subhaHorai),
                    ],
                  ),
                  if (t.descriptionTa.isNotEmpty || t.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      isTamil ? t.descriptionTa : t.description,
                      style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, height: 1.3),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: TNTColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TNTColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangamAlignmentCard(bool isTamil, TNTLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon_rounded, color: TNTColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                isTamil ? 'பஞ்சாங்க அம்சங்கள்' : 'Panchangam Astrological Alignment',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _buildDetailItem(localizations?.translate('tithi') ?? 'Tithi', isTamil ? _current.tithiTa : _current.tithi),
              _buildDetailItem(localizations?.translate('nakshatra') ?? 'Nakshatra', isTamil ? _current.nakshatraTa : _current.nakshatra),
              _buildDetailItem(localizations?.translate('yoga') ?? 'Yoga', isTamil ? _current.yogaTa : _current.yoga),
              _buildDetailItem(localizations?.translate('karana') ?? 'Karana', isTamil ? _current.karanaTa : _current.karana),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: TNTColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TNTColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildInauspiciousTimesCard(bool isTamil, TNTLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Text(
                localizations?.translate('inauspicious_windows') ?? 'Inauspicious Windows to Avoid',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTimingRow(localizations?.translate('rahu_kalam') ?? 'Rahu Kalam', _current.rahuKalam),
          const SizedBox(height: 6),
          _buildTimingRow(localizations?.translate('yamagandam') ?? 'Yamagandam', _current.yamagandam),
          const SizedBox(height: 6),
          _buildTimingRow(localizations?.translate('kuligai') ?? 'Kuligai', _current.kuligai),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, String timing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7F1D1D))),
        Text(timing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF991B1B))),
      ],
    );
  }

  Widget _buildNotesCard(bool isTamil, TNTLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: TNTColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                localizations?.translate('muhurtham_notes') ?? 'Important Astrological Notes',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isTamil ? _current.notesTa : _current.notes,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: TNTColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangamLinkButton(bool isTamil, TNTLocalizations? localizations) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(2); // Navigate to Panchangam Tab
        }
      },
      icon: const Icon(Icons.calendar_today_rounded, size: 16, color: TNTColors.primary),
      label: Text(
        localizations?.translate('view_date_panchangam') ?? "View Day's Full Panchangam",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: TNTColors.primaryDark,
        side: const BorderSide(color: TNTColors.primary, width: 1.2),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildBottomActionBar(bool isTamil, TNTLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: TNTColors.surface,
        border: Border(top: BorderSide(color: TNTColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showReminderDialog,
                icon: Icon(
                  _current.hasReminder ? Icons.notifications_active_rounded : Icons.alarm_add_rounded,
                  size: 16,
                  color: _current.hasReminder ? TNTColors.auspicious : TNTColors.textPrimary,
                ),
                label: Text(
                  localizations?.translate('reminder_btn') ?? 'Reminder',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TNTColors.textPrimary,
                  side: const BorderSide(color: TNTColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleSave,
                icon: Icon(
                  _current.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 16,
                ),
                label: Text(
                  _current.isSaved
                      ? (isTamil ? 'சேமிக்கப்பட்டது' : 'Saved')
                      : (localizations?.translate('save_btn') ?? 'Save'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _current.isSaved ? TNTColors.primaryDark : TNTColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month, bool isTamil) {
    if (isTamil) {
      const months = [
        'ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்',
        'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'
      ];
      return months[month - 1];
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return months[month - 1];
    }
  }
}
