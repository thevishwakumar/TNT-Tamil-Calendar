import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/state_widgets.dart';
import '../../core/widgets/tnt_loading_overlay.dart';
import '../../core/widgets/tnt_error_overlay.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../../special_days/screens/special_day_detail_screen.dart';
import '../../festivals/screens/festival_detail_screen.dart';
import '../../muhurtham/screens/muhurtham_detail_screen.dart';
import 'package:tnt_tamil_calendar/repositories/tnt_repositories.dart';

class DateDetailsScreen extends StatefulWidget {
  final DateTime date;
  final ITNTApiService apiService;

  const DateDetailsScreen({
    super.key,
    required this.date,
    required this.apiService,
  });

  @override
  _DateDetailsScreenState createState() => _DateDetailsScreenState();
}

class _DateDetailsScreenState extends State<DateDetailsScreen> {
  bool _isLoading = true;
  String? _errorMsg;

  CalendarDay? _calendarDay;
  PanchangamEntry? _panchangam;
  List<TimingEntry> _timings = [];
  List<SpecialDay> _specialDays = [];
  List<Festival> _festivals = [];
  List<MuhurthamDate> _muhurthams = [];

  @override
  void initState() {
    super.initState();
    _loadAllDayDetails();
  }

  Future<void> _loadAllDayDetails() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final futures = await Future.wait([
        widget.apiService.getCalendarDay(widget.date),
        widget.apiService.getPanchangam(widget.date),
        widget.apiService.getImportantTimings(widget.date),
        widget.apiService.getSpecialDays(widget.date.year, widget.date.month),
        widget.apiService.getFestivals(widget.date.year, widget.date.month),
        widget.apiService.getMarriageMuhurthams(widget.date.year, widget.date.month),
      ]);

      setState(() {
        _calendarDay = futures[0] as CalendarDay;
        _panchangam = futures[1] as PanchangamEntry;
        _timings = futures[2] as List<TimingEntry>;
        
        // Filter special days, festivals and muhurthams specifically for the selected date
        final allSpecials = futures[3] as List<SpecialDay>;
        _specialDays = allSpecials.where((s) => 
          s.date.day == widget.date.day && 
          s.date.month == widget.date.month && 
          s.date.year == widget.date.year
        ).toList();

        final allFestivals = futures[4] as List<Festival>;
        _festivals = allFestivals.where((f) => 
          f.date.day == widget.date.day && 
          f.date.month == widget.date.month && 
          f.date.year == widget.date.year
        ).toList();

        final allMuhurthams = futures[5] as List<MuhurthamDate>;
        _muhurthams = allMuhurthams.where((m) => 
          m.date.day == widget.date.day && 
          m.date.month == widget.date.month && 
          m.date.year == widget.date.year
        ).toList();

        _isLoading = false;
      });
      
      _logAnalyticsEvent('calendar_date_open');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
      });
    }
  }

  void _logAnalyticsEvent(String eventName) async {
    final analyticsRepo = AnalyticsRepository();
    await analyticsRepo.logEvent(
      eventName: eventName,
      metadata: {
        'selected_date': widget.date.toIso8601String(),
      },
    );
  }

  void _handleShare(TNTLocalizations localizations, bool isTamil) {
    _logAnalyticsEvent('share_date');
    final String dateTitle = '${widget.date.day} ${_getMonthName(widget.date.month, isTamil)} ${widget.date.year}';
    final String tamilDateText = _calendarDay != null 
        ? (isTamil ? _calendarDay!.tamilDateStr : '${_calendarDay!.tamilMonth} ${_calendarDay!.tamilDay}')
        : '';
    final String tithiText = _calendarDay != null 
        ? (isTamil ? _calendarDay!.tithiTa : _calendarDay!.tithi)
        : '';
    final String nakshatraText = _calendarDay != null 
        ? (isTamil ? _calendarDay!.nakshatraTa : _calendarDay!.nakshatra)
        : '';

    final shareText = '''
🕉️ TNT - ${isTamil ? 'தமிழ் நாள்காட்டி' : 'Tamil Calendar'}

📅 $dateTitle
📅 ${isTamil ? 'தமிழ் தேதி' : 'Tamil Date'}: $tamilDateText
✨ ${isTamil ? 'திதி' : 'Tithi'}: $tithiText
⭐ ${isTamil ? 'நட்சத்திரம்' : 'Nakshatra'}: $nakshatraText

${_specialDays.isNotEmpty ? '📌 ${isTamil ? 'சிறப்பு நாட்கள்' : 'Special Days'}:\n${_specialDays.map((s) => isTamil ? s.titleTa : s.title).join(', ')}\n' : ''}
${_festivals.isNotEmpty ? '🛕 ${isTamil ? 'பண்டிகைகள்' : 'Festivals'}:\n${_festivals.map((f) => isTamil ? f.nameTa : f.name).join(', ')}\n' : ''}
${_muhurthams.isNotEmpty ? '💍 ${isTamil ? 'சுப முகூர்த்தம்' : 'Auspicious Muhurtham'} ${isTamil ? 'உள்ளது' : 'Available'}!\n' : ''}
📱 ${isTamil ? 'மேலும் அறிய TNT செயலியை பதிவிறக்கவும்.' : 'Download TNT app for more details.'}
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TNTColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isTamil ? 'பகிரவும்' : 'Share Summary',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TNTColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TNTColors.border),
              ),
              child: Text(
                shareText,
                style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTamil ? 'ரத்து' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: TNTColors.primary,
                  content: Text(isTamil ? 'நகலெடுக்கப்பட்டது!' : 'Copied to clipboard!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TNTColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isTamil ? 'நகலெடு' : 'Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    final String dateTitle = '${widget.date.day} ${_getMonthName(widget.date.month, isTamil)} ${widget.date.year}';

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isTamil ? 'முழு நாள் விவரங்கள்' : 'Full Day Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      actions: const [TNTBrandHeader()],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header Card
                      _buildDateHeaderCard(dateTitle, isTamil),
                      const SizedBox(height: 16),

                      // Panchangam Details
                      _buildPanchangamCard(translate, isTamil),
                      const SizedBox(height: 16),

                      // Sunrise / Sunset Row
                      _buildSunMoonRow(translate, isTamil),
                      const SizedBox(height: 16),

                      // Important Timings
                      _buildTimingsCard(translate, isTamil),
                      const SizedBox(height: 16),

                      // Special Days & Festivals
                      _buildEventsList(translate, isTamil),

                      // Actions Block
                      _buildActionsRow(localizations!, isTamil),
                    ],
                  ),
          ),
          if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
          if (_errorMsg != null && !_isLoading)
            Positioned.fill(
              child: TNTErrorOverlay(
                onRetry: _loadAllDayDetails,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateHeaderCard(String dateTitle, bool isTamil) {
    final String tamilDateText = _calendarDay != null ? _calendarDay!.tamilDateStr : '';
    final String tamilMonthText = _calendarDay != null ? _calendarDay!.tamilMonth : '';
    final String tamilYearText = _calendarDay != null ? _calendarDay!.tamilYear : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TNTColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getWeekdayName(widget.date.weekday, isTamil),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil ? 'தமிழ் தேதி' : 'Tamil Date',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tamilDateText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isTamil ? 'தமிழ் மாதம் / வருடம்' : 'Tamil Month/Year',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tamilMonthText / $tamilYearText',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangamCard(String Function(String) translate, bool isTamil) {
    if (_panchangam == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TNTColors.border),
        ),
        child: Text(
          isTamil ? 'தகவல் கிடைக்கவில்லை' : 'Information unavailable',
          style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
        ),
      );
    }

    return Card(
      color: TNTColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: TNTColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('today_panchangam'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.primary),
            ),
            const SizedBox(height: 14),
            _buildPanchangamRow(translate('tithi'), isTamil ? _panchangam!.tithiTa : _panchangam!.tithi, Icons.shield_moon_outlined),
            const Divider(color: TNTColors.border, height: 16),
            _buildPanchangamRow(translate('nakshatra'), isTamil ? _panchangam!.nakshatraTa : _panchangam!.nakshatra, Icons.star_outline_rounded),
            const Divider(color: TNTColors.border, height: 16),
            _buildPanchangamRow(translate('yoga'), isTamil ? _panchangam!.yogaTa : _panchangam!.yoga, Icons.brightness_high_outlined),
            const Divider(color: TNTColors.border, height: 16),
            _buildPanchangamRow(translate('karana'), isTamil ? _panchangam!.karanaTa : _panchangam!.karana, Icons.hourglass_empty_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchangamRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: TNTColors.textMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSunMoonRow(String Function(String) translate, bool isTamil) {
    if (_panchangam == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _buildSunMoonCard(
            isTamil ? 'சூரிய உதயம்' : 'Sunrise',
            _panchangam!.sunrise,
            Icons.wb_sunny_outlined,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSunMoonCard(
            isTamil ? 'சூரிய அஸ்தமனம்' : 'Sunset',
            _panchangam!.sunset,
            Icons.wb_twilight_rounded,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSunMoonCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TNTColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsCard(String Function(String) translate, bool isTamil) {
    if (_timings.isEmpty) return const SizedBox();

    return Card(
      color: TNTColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: TNTColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('important_timings'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.primary),
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timings.length,
              separatorBuilder: (context, idx) => const Divider(color: TNTColors.border, height: 16),
              itemBuilder: (context, idx) {
                final timing = _timings[idx];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTamil ? timing.nameTa : timing.name,
                      style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                        color: timing.isAuspicious ? TNTColors.primary : TNTColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${timing.startTime} - ${timing.endTime}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: TNTColors.textSecondary),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(String Function(String) translate, bool isTamil) {
    final List<Widget> listWidgets = [];

    // 1. Special Days
    for (var s in _specialDays) {
      listWidgets.add(
        _buildItemTile(
          s.title,
          s.description,
          TNTColors.auspicious,
          Icons.star_outline_rounded,
          titleTa: s.titleTa,
          descTa: s.descriptionTa,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpecialDayDetailScreen(
                  specialDay: s,
                  apiService: widget.apiService,
                ),
              ),
            );
          },
        ),
      );
    }

    // 2. Festivals
    for (var f in _festivals) {
      listWidgets.add(
        _buildItemTile(
          f.name,
          f.description,
          TNTColors.accent,
          Icons.festival_outlined,
          titleTa: f.nameTa,
          descTa: f.descriptionTa,
          badge: f.type == 'government' ? (isTamil ? 'அரசு விடுமுறை' : 'Government Holiday') : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FestivalDetailScreen(
                  festival: f,
                  apiService: widget.apiService,
                ),
              ),
            );
          },
        ),
      );
    }

    // 3. Marriage Muhurthams
    for (var m in _muhurthams) {
      listWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: TNTColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TNTColors.primary, width: 1.2),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 16, color: TNTColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    isTamil ? 'திருமண சுபமுககூர்த்தம்' : 'Marriage Muhurtham',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      m.isValarthirai ? (isTamil ? 'வளர்பிறை' : 'Waxing Moon') : (isTamil ? 'தேய்பிறை' : 'Waning Moon'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TNTColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${isTamil ? "நேரம்" : "Timings"}: ${m.startTime} - ${m.endTime}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              if (m.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  isTamil ? m.descriptionTa : m.description,
                  style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, height: 1.4),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  _logAnalyticsEvent('muhurtham_view');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MuhurthamDetailScreen(
                        muhurtham: m,
                        apiService: widget.apiService,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      isTamil ? 'முகூர்த்த விவரங்களை காண்க' : 'View Muhurtham Details',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: TNTColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (listWidgets.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTamil ? 'இன்றைய சிறப்பு' : 'Selected Date Events',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.primary),
        ),
        const SizedBox(height: 12),
        ...listWidgets,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemTile(
    String title, 
    String desc, 
    Color color, 
    IconData icon, {
    String? titleTa,
    String? descTa,
    String? badge,
    VoidCallback? onTap,
  }) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    final displayTitle = isTamil && titleTa != null && titleTa.isNotEmpty ? titleTa : title;
    final displayDesc = isTamil && descTa != null && descTa.isNotEmpty ? descTa : desc;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TNTColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: TNTColors.textMuted),
                    ],
                  ),
                  if (displayDesc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayDesc,
                      style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRow(TNTLocalizations localizations, bool isTamil) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionCircularBtn(
            Icons.save_alt_rounded,
            isTamil ? 'சேமி' : 'Save',
            () {
              _logAnalyticsEvent('save_action_click');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: TNTColors.primary,
                  content: Text(isTamil ? 'நாள் சேமிக்கப்பட்டது!' : 'Date saved successfully!'),
                ),
              );
            },
          ),
          _buildActionCircularBtn(
            Icons.notifications_none_rounded,
            isTamil ? 'நினைவூட்டல்' : 'Reminder',
            () {
              _logAnalyticsEvent('reminder_action_click');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: TNTColors.primary,
                  content: Text(isTamil ? 'நினைவூட்டல் அமைக்கப்பட்டது!' : 'Reminder set successfully!'),
                ),
              );
            },
          ),
          _buildActionCircularBtn(
            Icons.share_rounded,
            isTamil ? 'பகிர்' : 'Share',
            () => _handleShare(localizations, isTamil),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircularBtn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: TNTColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: TNTColors.border),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: TNTColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
        ),
      ],
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

  String _getWeekdayName(int weekday, bool isTamil) {
    if (isTamil) {
      const days = [
        'திங்கட்கிழமை', 'செவ்வாய்க்கிழமை', 'புதன்கிழமை', 'வியாழக்கிழமை',
        'வெள்ளிக்கிழமை', 'சனிக்கிழமை', 'ஞாயிற்றுக்கிழமை'
      ];
      return days[weekday - 1];
    } else {
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ];
      return days[weekday - 1];
    }
  }
}
