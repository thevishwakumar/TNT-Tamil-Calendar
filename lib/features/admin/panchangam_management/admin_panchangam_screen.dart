import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../../../repositories/panchang_repository.dart';
import '../../../panchangam/models/panchangam_bundle.dart';

/// Admin Panchangam Management Screen
/// Displays fully dynamic mathematical and astronomical panchangam calculations
/// for any selected calendar date and location.
class AdminPanchangamScreen extends StatefulWidget {
  const AdminPanchangamScreen({super.key});

  @override
  State<AdminPanchangamScreen> createState() => _AdminPanchangamScreenState();
}

class _AdminPanchangamScreenState extends State<AdminPanchangamScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedLocation = 'Chennai';
  bool _isLoading = true;
  PanchangamDailyBundle? _bundle;
  String? _errorMessage;

  final PanchangRepository _repo = PanchangRepository();

  static const List<String> _cities = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Tirunelveli',
  ];

  static const Map<String, (double lat, double lng)> _cityCoords = {
    'Chennai': (13.0827, 80.2707),
    'Coimbatore': (11.0168, 76.9558),
    'Madurai': (9.9252, 78.1198),
    'Tiruchirappalli': (10.7905, 78.7047),
    'Salem': (11.6643, 78.1460),
    'Tirunelveli': (8.7139, 77.7567),
  };

  @override
  void initState() {
    super.initState();
    _loadPanchangamData();
  }

  Future<void> _loadPanchangamData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coords = _cityCoords[_selectedLocation] ?? (13.0827, 80.2707);
      final loc = UserLocationItem(
        id: 'loc-$_selectedLocation',
        userId: 'admin',
        name: _selectedLocation,
        city: _selectedLocation,
        timezone: 'Asia/Kolkata',
        latitude: coords.$1,
        longitude: coords.$2,
        createdAt: DateTime.now(),
      );

      final bundle = await _repo.getDailyPanchangam(
        date: _selectedDate,
        location: loc,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _bundle = bundle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _changeDate(DateTime newDate) {
    if (_selectedDate.year == newDate.year &&
        _selectedDate.month == newDate.month &&
        _selectedDate.day == newDate.day) {
      return;
    }
    setState(() {
      _selectedDate = newDate;
    });
    _loadPanchangamData();
  }

  String _getTamilWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'திங்கட்கிழமை (Monday)';
      case DateTime.tuesday:
        return 'செவ்வாய்க்கிழமை (Tuesday)';
      case DateTime.wednesday:
        return 'புதன்கிழமை (Wednesday)';
      case DateTime.thursday:
        return 'வியாழக்கிழமை (Thursday)';
      case DateTime.friday:
        return 'வெள்ளிக்கிழமை (Friday)';
      case DateTime.saturday:
        return 'சனிக்கிழமை (Saturday)';
      case DateTime.sunday:
        return 'ஞாயிற்றுக்கிழமை (Sunday)';
      default:
        return '';
    }
  }

  String _formatNallaNeram() {
    if (_bundle == null) return '—';
    final nallaTimings = _bundle!.timings
        .where((t) =>
            t.name.toLowerCase().contains('nalla') &&
            !t.name.toLowerCase().contains('gowri'))
        .toList();
    if (nallaTimings.isEmpty) return '—';
    return nallaTimings
        .map((t) => '${t.nameTa.isNotEmpty ? t.nameTa : t.name}: ${t.startTime} - ${t.endTime}')
        .join(', ');
  }

  String _formatGowriTimings() {
    if (_bundle == null) return '—';
    final gowriTimings = _bundle!.timings
        .where((t) => t.category == 'gowri' && t.isAuspicious)
        .toList();
    if (gowriTimings.isEmpty) {
      final anyGowri = _bundle!.timings
          .where((t) => t.name.toLowerCase().contains('gowri'))
          .toList();
      if (anyGowri.isEmpty) return '—';
      return anyGowri
          .map((t) => '${t.nameTa.isNotEmpty ? t.nameTa : t.name}: ${t.startTime} - ${t.endTime}')
          .join(', ');
    }
    return gowriTimings
        .map((t) => '${t.nameTa.isNotEmpty ? t.nameTa : t.name}: ${t.startTime} - ${t.endTime}')
        .join(', ');
  }

  String _getTimingWindow(String keyword) {
    if (_bundle == null) return '—';
    final match = _bundle!.timings.cast<TimingEntry?>().firstWhere(
      (t) =>
          t != null &&
          (t.name.toLowerCase().contains(keyword) ||
              t.nameTa.toLowerCase().contains(keyword)),
      orElse: () => null,
    );
    if (match == null || match.startTime.isEmpty) return '—';
    return '${match.startTime} - ${match.endTime}';
  }

  @override
  Widget build(BuildContext context) {
    final calDay = _bundle?.calendarDay;
    final panch = _bundle?.panchangam;

    final gregorianStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final tamilDateDisplay = calDay != null && calDay.tamilMonth.isNotEmpty
        ? '${calDay.tamilMonth} ${calDay.tamilDay}${calDay.tamilYear.isNotEmpty ? " (${calDay.tamilYear} வருடம்)" : ""}'
        : 'கணக்கிடப்படுகிறது...';

    final tithiDisplay = calDay != null && calDay.tithiTa.isNotEmpty
        ? '${calDay.tithiTa}${calDay.tithi.isNotEmpty ? " (${calDay.tithi})" : ""}'
        : (panch?.tithiTa ?? panch?.tithi ?? '—');

    final nakshatraDisplay = calDay != null && calDay.nakshatraTa.isNotEmpty
        ? '${calDay.nakshatraTa}${calDay.nakshatra.isNotEmpty ? " (${calDay.nakshatra})" : ""}'
        : (panch?.nakshatraTa ?? panch?.nakshatra ?? '—');

    final yogaDisplay = panch != null && panch.yogaTa.isNotEmpty
        ? '${panch.yogaTa} (${panch.yoga})'
        : (panch?.yoga ?? '—');

    final karanaDisplay = panch != null && panch.karanaTa.isNotEmpty
        ? '${panch.karanaTa} (${panch.karana})'
        : (panch?.karana ?? '—');

    final pakshaDisplay = panch != null && panch.pakshaTa.isNotEmpty
        ? '${panch.pakshaTa} (${panch.paksha})'
        : (panch?.paksha ?? '—');

    final sunTimingsDisplay = (panch != null && panch.sunrise.isNotEmpty)
        ? '${panch.sunrise} / ${panch.sunset}'
        : '—';

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text(
          'Panchangam Management',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TNTColors.textPrimary,
          ),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [
          // Refresh Button
          IconButton(
            tooltip: 'Recalculate / Refresh',
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: () => _loadPanchangamData(forceRefresh: true),
          ),
          // Date Picker Button
          IconButton(
            tooltip: 'Select Calendar Date',
            icon: const Icon(Icons.calendar_today_rounded, color: TNTColors.primary),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                _changeDate(picked);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Date Navigator Bar (< Today >)
            Card(
              color: TNTColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: TNTColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous Day',
                      icon: const Icon(Icons.chevron_left_rounded, color: TNTColors.primary),
                      onPressed: () => _changeDate(_selectedDate.subtract(const Duration(days: 1))),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) _changeDate(picked);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          children: [
                            Text(
                              gregorianStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.textPrimary,
                              ),
                            ),
                            Text(
                              _getTamilWeekday(_selectedDate.weekday),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TNTColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next Day',
                      icon: const Icon(Icons.chevron_right_rounded, color: TNTColors.primary),
                      onPressed: () => _changeDate(_selectedDate.add(const Duration(days: 1))),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        side: const BorderSide(color: TNTColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        minimumSize: const Size(40, 30),
                      ),
                      onPressed: () => _changeDate(DateTime.now()),
                      child: const Text('Today', style: TextStyle(fontSize: 11, color: TNTColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Selected Date & Location Info Card
            Card(
              color: TNTColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: TNTColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'தமிழ் தேதி & ஆண்டு (Tamil Date):',
                            style: TextStyle(fontSize: 11, color: TNTColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tamilDateDisplay,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: TNTColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location Dropdown Selector
                    PopupMenuButton<String>(
                      initialValue: _selectedLocation,
                      onSelected: (loc) {
                        if (loc != _selectedLocation) {
                          setState(() => _selectedLocation = loc);
                          _loadPanchangamData();
                        }
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      itemBuilder: (context) => _cities
                          .map((city) => PopupMenuItem(
                                value: city,
                                child: Text(city, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TNTColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TNTColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: TNTColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              _selectedLocation,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.primary,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16, color: TNTColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loading / Error Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: TNTColors.primary),
                      SizedBox(height: 12),
                      Text(
                        'பஞ்சாங்கம் கணக்கிடப்படுகிறது...',
                        style: TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'கணிப்பு பிழை: $_errorMessage',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _loadPanchangamData(forceRefresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Panchangam Core Elements Card
              Card(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Core Elements (பஞ்சாங்கம்)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: TNTColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Validated',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPanchRow('திதி (Tithi)', tithiDisplay),
                      _buildPanchRow('நட்சத்திரம் (Nakshatra)', nakshatraDisplay),
                      _buildPanchRow('யோகம் (Yoga)', yogaDisplay),
                      _buildPanchRow('கரணம் (Karana)', karanaDisplay),
                      _buildPanchRow('பக்ஷம் (Paksha)', pakshaDisplay),
                      _buildPanchRow('சூரியோதயம் / மறைவு', sunTimingsDisplay),
                      if (panch != null && panch.dayDuration.isNotEmpty)
                        _buildPanchRow(
                            'பகல் / இரவு அளவு', '${panch.dayDuration} / ${panch.nightDuration}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timings Management Card
              Card(
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
                      const Text(
                        'Approved Timings (சுப & அசுப நேரங்கள்)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPanchRow('நல்ல நேரம் (Nalla Neram)', _formatNallaNeram(), isHighlight: true),
                      _buildPanchRow('கௌரி நல்ல நேரம்', _formatGowriTimings()),
                      _buildPanchRow('இராகு காலம் (Rahu Kalam)', _getTimingWindow('rahu'), isCaution: true),
                      _buildPanchRow('எமகண்டம் (Yamagandam)', _getTimingWindow('yama'), isCaution: true),
                      _buildPanchRow('குளிகை (Kuligai)', _getTimingWindow('kuli')),
                    ],
                  ),
                ),
              ),

              // Special Observances / Festivals Card if any
              if (_bundle != null && (_bundle!.hasSpecialDays || _bundle!.hasFestivals)) ...[
                const SizedBox(height: 16),
                Card(
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
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded, color: TNTColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'விசேஷங்கள் & விரதங்கள் (Observances)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._bundle!.specialDays.map((s) => Chip(
                                  label: Text(
                                    s.titleTa.isNotEmpty ? s.titleTa : s.title,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: TNTColors.primary.withValues(alpha: 0.1),
                                  side: BorderSide(color: TNTColors.primary.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                )),
                            ..._bundle!.festivals.map((f) => Chip(
                                  label: Text(
                                    f.nameTa.isNotEmpty ? f.nameTa : f.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: Colors.amber.withValues(alpha: 0.15),
                                  side: BorderSide(color: Colors.amber[700]!.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // Force Refresh / Recalculate Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Recalculate Panchangam for Selected Date'),
              onPressed: () {
                _loadPanchangamData(forceRefresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Panchangam recalculated dynamically for $gregorianStr ($tamilDateDisplay)'),
                    backgroundColor: TNTColors.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isCaution = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCaution
                    ? Colors.redAccent
                    : (isHighlight ? Colors.green[700] : TNTColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
