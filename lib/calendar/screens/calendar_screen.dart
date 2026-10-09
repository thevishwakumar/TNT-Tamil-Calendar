import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import 'date_details_screen.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../repositories/panchang_repository.dart';

class CalendarScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final Function(int)? onTabChanged;

  const CalendarScreen({
    super.key,
    required this.apiService,
    this.onTabChanged,
  });

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with AutomaticKeepAliveClientMixin {
  bool isLoading = false;
  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  List<Festival> festivals = [];
  List<SpecialDay> specialDays = [];
  List<MuhurthamDate> muhurthams = [];

  // Local Memory Cache
  final Map<String, List<Festival>> _festivalsCache = {};
  final Map<String, List<SpecialDay>> _specialDaysCache = {};
  final Map<String, List<MuhurthamDate>> _muhurthamsCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final cacheKey = '${currentMonth.year}-${currentMonth.month}';
    
    if (_festivalsCache.containsKey(cacheKey) && 
        _specialDaysCache.containsKey(cacheKey) && 
        _muhurthamsCache.containsKey(cacheKey)) {
      setState(() {
        festivals = _festivalsCache[cacheKey]!;
        specialDays = _specialDaysCache[cacheKey]!;
        muhurthams = _muhurthamsCache[cacheKey]!;
        isLoading = false;
      });
      _logAnalyticsEvent('calendar_month_change');
      return;
    }

    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        widget.apiService.getFestivals(currentMonth.year, currentMonth.month),
        widget.apiService.getSpecialDays(currentMonth.year, currentMonth.month),
        widget.apiService.getMarriageMuhurthams(currentMonth.year, currentMonth.month),
      ]);

      _festivalsCache[cacheKey] = results[0] as List<Festival>;
      _specialDaysCache[cacheKey] = results[1] as List<SpecialDay>;
      _muhurthamsCache[cacheKey] = results[2] as List<MuhurthamDate>;

      if (!mounted) return;
      setState(() {
        festivals = _festivalsCache[cacheKey]!;
        specialDays = _specialDaysCache[cacheKey]!;
        muhurthams = _muhurthamsCache[cacheKey]!;
        isLoading = false;
      });
      _logAnalyticsEvent('calendar_month_change');
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logAnalyticsEvent(String eventName) async {
    try {
      final db = SupabaseService();
      if (db.isInitialized) {
        final user = db.client.auth.currentUser;
        await db.client.from('analytics_events').insert({
          if (user != null) 'user_id': user.id,
          'event_name': eventName,
          'metadata': {
            'viewed_year': currentMonth.year,
            'viewed_month': currentMonth.month,
          },
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  void _navigateToDetails(DateTime date) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DateDetailsScreen(
          date: date,
          apiService: widget.apiService,
        ),
      ),
    );

    if (result == 'go_to_muhurtham' && widget.onTabChanged != null) {
      widget.onTabChanged!(3); // 3 is the index of the Muhurtham module
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    return TNTResponsiveScaffold(
      maxWidth: 1000.0,
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          translate('calendar'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ 
          TextButton.icon(
            icon: const Icon(Icons.today_rounded,
                size: 16, color: TNTColors.primary),
            label: Text(
              translate('today'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: TNTColors.primary),
            ),
            onPressed: () {
              setState(() {
                currentMonth = DateTime.now();
                selectedDate = DateTime.now();
              });
              _loadEvents();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: isLoading
          ? const TNTLoadingWidget()
          : RefreshIndicator(
              color: TNTColors.primary,
              onRefresh: _loadEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Month navigation bar
                    _buildMonthNavigationHeader(isTamil),

                    // Week Days Header Row
                    _buildWeekDaysHeader(isTamil),

                    // Days Grid
                    _buildCalendarGrid(isTamil),

                    const Divider(color: TNTColors.border, height: 1),

                    // Accessible Event Key Indicators List
                    _buildEventIndicatorsList(localizations, isTamil),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthNavigationHeader(bool isTamil) {
    return Container(
      color: TNTColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: TNTColors.primary),
            onPressed: () {
              setState(() {
                currentMonth =
                    DateTime(currentMonth.year, currentMonth.month - 1);
              });
              _loadEvents();
            },
          ),
          Text(
            '${_getMonthName(currentMonth.month, isTamil)} ${currentMonth.year}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: TNTColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: TNTColors.primary),
            onPressed: () {
              setState(() {
                currentMonth =
                    DateTime(currentMonth.year, currentMonth.month + 1);
              });
              _loadEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader(bool isTamil) {
    final days = isTamil
        ? ['ஞாயிறு', 'திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: TNTColors.border, width: 0.5))), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((day) {
              final isWeekend = day == 'ஞாயிறு' || day == 'Sun' || day == 'சனி' || day == 'Sat';
              final label = day.length > 3 ? day.substring(0, 3) : day;
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isWeekend
                          ? TNTColors.primary
                          : TNTColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            })
            .toList()
            .cast<Widget>(),
      ), );
  }

  Widget _buildCalendarGrid(bool isTamil) {
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayOfWeek =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday %
            7; // Sunday = 0

    final totalCells = daysInMonth + firstDayOfWeek;
    final rowCount = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // On very compact phones ( < 360 px ) give cells slightly more vertical
        // room so the Tamil secondary date number is not clipped.
        final double aspectRatio = ResponsiveLayout.isDesktop(context)
            ? 1.5
            : ResponsiveLayout.isTablet(context)
                ? 1.2
                : constraints.maxWidth < 360
                    ? 0.72
                    : 0.82;
        return Container(
          color: TNTColors.surface,
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: aspectRatio,
            ),
            itemCount: rowCount * 7,
            itemBuilder: (context, index) {
              final dayNum = index - firstDayOfWeek + 1;
              if (dayNum <= 0 || dayNum > daysInMonth) {
                return const SizedBox();
              }

              final cellDate =
                  DateTime(currentMonth.year, currentMonth.month, dayNum);
              final isToday = cellDate.day == DateTime.now().day &&
                  cellDate.month == DateTime.now().month &&
                  cellDate.year == DateTime.now().year;

              final isSelected = cellDate.day == selectedDate.day &&
                  cellDate.month == selectedDate.month &&
                  cellDate.year == selectedDate.year;

              // Authentic Tamil date computed dynamically
              final tDate = PanchangRepository.computeTamilDate(cellDate);
              final tamilDayNum = tDate['tamilDay'] ?? dayNum;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = cellDate;
                  });
                  _navigateToDetails(cellDate);
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TNTColors.primary
                        : (isToday
                            ? TNTColors.primary.withValues(alpha: 0.06)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? TNTColors.primary
                          : (isToday
                              ? TNTColors.primary.withValues(alpha: 0.4)
                              : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // English date text
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? TNTColors.primary
                                  : (cellDate.weekday == 7
                                      ? TNTColors.primary
                                      : TNTColors.textPrimary)),
                        ),
                      ),
                      const SizedBox(height: 1),
                      // Tamil date text
                      Text(
                        '$tamilDayNum',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : (isToday
                                  ? TNTColors.primaryDark
                                  : TNTColors.textSecondary),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Compact Indicators
                      _buildCellEventIndicator(dayNum),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCellEventIndicator(int dayNum) {
    final hasFestival = festivals.any((f) => f.date.day == dayNum);
    final hasSpecial = specialDays.any((s) => s.date.day == dayNum);
    final hasMuhurtham = muhurthams.any((m) => m.date.day == dayNum);

    final List<Widget> dots = [];
    if (hasMuhurtham) {
      dots.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32), // Auspicious green for Muhurtham
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    if (hasFestival) {
      dots.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFE65100), // Saffron / Orange for Festival
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    if (hasSpecial) {
      dots.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFC2185B), // Rose / Pink for Special Day
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    if (dots.isEmpty) return const SizedBox(height: 6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots,
    );
  }

  Widget _buildEventIndicatorsList(
      TNTLocalizations? localizations, bool isTamil) {
    // Collect events occurring in the current viewed month
    if (festivals.isEmpty && specialDays.isEmpty && muhurthams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: TNTEmptyWidget(message: localizations?.translate('no_data')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTamil
                ? 'இந்த மாத சிறப்பு நாட்கள்'
                : 'Special Days of the Month',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: TNTColors.primary),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                festivals.length + specialDays.length + muhurthams.length,
            itemBuilder: (context, index) {
              if (index < festivals.length) {
                final f = festivals[index];
                final fTitle = isTamil
                    ? (f.nameTa.trim().isNotEmpty ? f.nameTa : f.name)
                    : (f.name.trim().isNotEmpty ? f.name : f.nameTa);
                final fDesc = isTamil
                    ? (f.descriptionTa.trim().isNotEmpty ? f.descriptionTa : f.description)
                    : (f.description.trim().isNotEmpty ? f.description : f.descriptionTa);
                return _buildEventTile(
                  f.date.day,
                  fTitle,
                  fDesc,
                  TNTColors.accent,
                  Icons.festival_outlined,
                  '🏮',
                  isTamil ? 'பண்டிகை' : 'Festival',
                );
              } else if (index < festivals.length + specialDays.length) {
                final s = specialDays[index - festivals.length];
                final sTitle = isTamil
                    ? (s.titleTa.trim().isNotEmpty ? s.titleTa : s.title)
                    : (s.title.trim().isNotEmpty ? s.title : s.titleTa);
                final sDesc = isTamil
                    ? (s.descriptionTa.trim().isNotEmpty ? s.descriptionTa : s.description)
                    : (s.description.trim().isNotEmpty ? s.description : s.descriptionTa);
                return _buildEventTile(
                  s.date.day,
                  sTitle,
                  sDesc,
                  TNTColors.auspicious,
                  Icons.star_outline_rounded,
                  '📌',
                  isTamil ? 'சிறப்பு நாள்' : 'Special Day',
                );
              } else {
                final m =
                    muhurthams[index - festivals.length - specialDays.length];
                final mDesc = isTamil
                    ? (m.descriptionTa.trim().isNotEmpty ? m.descriptionTa : m.description)
                    : (m.description.trim().isNotEmpty ? m.description : m.descriptionTa);
                return _buildEventTile(
                  m.date.day,
                  isTamil ? 'சுப முகூர்த்தம்' : 'Auspicious Muhurtham',
                  mDesc,
                  TNTColors.primary,
                  Icons.favorite_rounded,
                  '💍',
                  isTamil ? 'முகூர்த்தம்' : 'Muhurtham',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(int day, String title, String desc, Color color,
      IconData icon, String emoji, String accessibleLabel) {
    final cleanTitle = title.trim();
    final cleanDesc = desc.trim();
    final displayTitle = cleanTitle.isNotEmpty ? cleanTitle : accessibleLabel;
    final displayDesc = cleanDesc.isNotEmpty && cleanDesc != cleanTitle
        ? cleanDesc
        : (cleanTitle.isNotEmpty ? accessibleLabel : '');

    return InkWell(
      onTap: () => _navigateToDetails(
          DateTime(currentMonth.year, currentMonth.month, day)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TNTColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$emoji ',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: TNTColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  if (displayDesc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      displayDesc,
                      style: const TextStyle(
                          fontSize: 11,
                          color: TNTColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: TNTColors.textMuted),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month, bool isTamil) {
    if (isTamil) {
      const months = ['ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'];
      return months[month - 1];
    } else {
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return months[month - 1];
    }
  }
}
