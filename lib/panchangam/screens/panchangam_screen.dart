import 'package:flutter/material.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/state_widgets.dart';
import '../../services/supabase_service.dart';
import '../../services/navamsha_panchang_service.dart';
import '../../repositories/panchang_repository.dart';
import '../../models/tnt_models.dart';
import '../models/panchangam_bundle.dart';
import '../repositories/panchangam_repository.dart';
import '../widgets/city_selector_sheet.dart';
import '../widgets/muhurtham_status_card.dart';
import '../widgets/panchangam_date_bar.dart';
import '../widgets/panchangam_header.dart';
import '../widgets/panchangam_overview_card.dart';
import '../widgets/special_observance_card.dart';
import '../widgets/sun_moon_card.dart';
import '../widgets/timing_card.dart';

class PanchangamScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final DateTime? initialDate;

  const PanchangamScreen({
    super.key,
    required this.apiService,
    this.initialDate,
  });

  @override
  _PanchangamScreenState createState() => _PanchangamScreenState();
}

class _PanchangamScreenState extends State<PanchangamScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  String _currentCity = 'Chennai';
  late PanchangamRepository _panchangamRepo;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  PanchangamDailyBundle? _bundle;

  // Filter mode: 0: All, 1: Timings Only, 2: Gowri & Horai
  int _selectedFilterIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _panchangamRepo = PanchangamRepository(
      dataProvider: SupabasePanchangamProvider(apiService: widget.apiService),
    );
    _loadPanchangamData();
  }

  Future<void> _loadPanchangamData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (forceRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final bundle = await _panchangamRepo.getPanchangamBundle(
        _selectedDate,
        location: _currentCity,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        if (bundle != null) {
          _bundle = bundle;
        } else {
          final loc = UserLocationItem(
            id: 'loc-$_currentCity',
            userId: 'active-user',
            name: _currentCity,
            city: _currentCity,
            timezone: 'Asia/Kolkata',
            createdAt: DateTime.now(),
          );
          final mathData = NavamshaPanchangService().computeLocalAstronomicalFallback(
            year: _selectedDate.year,
            month: _selectedDate.month,
            date: _selectedDate.day,
            latitude: 11.0168,
            longitude: 76.9558,
            timezone: 5.5,
            cityName: _currentCity,
          );
          _bundle = PanchangRepository().mapToPanchangamBundle(_selectedDate, loc, mathData, isOffline: true);
        }
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = UserLocationItem(
        id: 'loc-$_currentCity',
        userId: 'active-user',
        name: _currentCity,
        city: _currentCity,
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      );
      final mathData = NavamshaPanchangService().computeLocalAstronomicalFallback(
        year: _selectedDate.year,
        month: _selectedDate.month,
        date: _selectedDate.day,
        latitude: 11.0168,
        longitude: 76.9558,
        timezone: 5.5,
        cityName: _currentCity,
      );
      final fallbackBundle = PanchangRepository().mapToPanchangamBundle(_selectedDate, loc, mathData, isOffline: true);
      setState(() {
        _bundle = fallbackBundle;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    }
  }

  void _onPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadPanchangamData();
  }

  void _onNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadPanchangamData();
  }

  void _onToday() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return;
    }
    setState(() {
      _selectedDate = now;
    });
    _loadPanchangamData();
  }

  void _onDatePicked(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadPanchangamData();
  }

  void _openCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CitySelectorSheet(
        selectedCity: _currentCity,
        onCitySelected: (city) {
          setState(() {
            _currentCity = city;
          });
          _loadPanchangamData(forceRefresh: true);
        },
      ),
    );
  }

  void _handleShare(TNTLocalizations? localizations) {
    String translate(String k) => localizations?.translate(k) ?? k;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translate('share_panchangam')),
        backgroundColor: TNTColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleSave(TNTLocalizations? localizations) {
    String translate(String k) => localizations?.translate(k) ?? k;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translate('save_panchangam')),
        backgroundColor: TNTColors.auspicious,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleReminder(TNTLocalizations? localizations) {
    String translate(String k) => localizations?.translate(k) ?? k;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translate('reminder_set')),
        backgroundColor: TNTColors.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header with city selector & refresh
            PanchangamHeader(
              location: _currentCity,
              onLocationTap: _openCitySelector,
              onRefreshTap: () => _loadPanchangamData(forceRefresh: true),
              isRefreshing: _isRefreshing,
            ),

            // Offline Cache Notice Bar (Active when operating without internet)
            if (_bundle?.isFromOfflineCache == true)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded,
                        size: 15, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTamil
                            ? 'உள்ளூர் நினைவகம்: இணையமின்றி முக்கிய நேரங்கள் கிடைக்கின்றன.'
                            : 'Offline Cache: Essential timings available without internet.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Date Navigation Bar (Prev / Today / Next / Picker)
            PanchangamDateBar(
              selectedDate: _selectedDate,
              calendarDay: _bundle?.calendarDay,
              onPreviousDate: _onPreviousDay,
              onToday: _onToday,
              onNextDate: _onNextDay,
              onDateSelected: _onDatePicked,
            ),

            // Content Tabs / Quick Filters
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TNTColors.border),
              ),
              child: Row(
                children: [
                  _buildFilterTab(0, isTamil ? 'அனைத்தும்' : 'Overview',
                      Icons.dashboard_rounded),
                  _buildFilterTab(
                      1,
                      isTamil ? 'சுப & அசுப நேரங்கள்' : 'Timings',
                      Icons.timer_outlined),
                  _buildFilterTab(2, isTamil ? 'கௌரி & ஹோரை' : 'Gowri & Horai',
                      Icons.auto_graph_rounded),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Main Body Content
            Expanded(
              child: _buildBody(localizations, isTamil, translate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String title, IconData icon) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TNTColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : TNTColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : TNTColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    TNTLocalizations? localizations,
    bool isTamil,
    String Function(String) translate,
  ) {
    if (_isLoading) {
      return const TNTLoadingWidget();
    }

    if (_errorMessage != null && _bundle == null) {
      return TNTErrorWidget(
        message: _errorMessage!,
        onRetry: () => _loadPanchangamData(forceRefresh: true),
      );
    }

    final bundle = _bundle;
    if (bundle == null) {
      return const TNTEmptyWidget();
    }

    return RefreshIndicator(
      color: TNTColors.primary,
      onRefresh: () => _loadPanchangamData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter 0: Complete Overview
            if (_selectedFilterIndex == 0) ...[
              // 1. Core Panchangam Overview Card (Tithi, Nakshatra, Yoga, Karana, Paksha)
              PanchangamOverviewCard(
                panchangam: bundle.panchangam,
                calendarDay: bundle.calendarDay,
                date: _selectedDate,
              ),

              // 2. Subha Muhurtham Alert
              MuhurthamStatusCard(muhurthams: bundle.muhurthams),

              // 3. Special Virathams / Festivals
              SpecialObservanceCard(
                specialDays: bundle.specialDays,
                festivals: bundle.festivals,
              ),

              // 4. Sun & Moon Timings
              SunMoonCard(panchangam: bundle.panchangam),

              // 5. Important Daily Timings Preview
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      translate('daily_timings'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedFilterIndex = 1),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isTamil ? 'அனைத்தும் பார்க்க' : 'View All',
                        style: const TextStyle(
                            fontSize: 12,
                            color: TNTColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // List core timings (Nalla Neram, Rahu, Yama, Kuligai)
              ...bundle.timings.take(4).map((t) => TimingCard(timing: t)),
            ],

            // Filter 1: Auspicious & Inauspicious Timings
            if (_selectedFilterIndex == 1) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  isTamil
                      ? 'சுப & அசுப நேரங்கள்'
                      : 'Auspicious & Inauspicious Timings',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TNTColors.textPrimary),
                ),
              ),
              ...bundle.timings.map((t) => TimingCard(timing: t)),
            ],

            // Filter 2: Gowri & Horai Timings
            if (_selectedFilterIndex == 2) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  isTamil
                      ? 'கௌரி பஞ்சாங்கம் மற்றும் சுப ஹோரை'
                      : 'Gowri Panchangam & Subha Horai Schedule',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TNTColors.textPrimary),
                ),
              ),
              ...bundle.timings
                  .where((t) =>
                      t.name.contains('Gowri') ||
                      t.name.contains('Horai') ||
                      t.isAuspicious)
                  .map((t) => TimingCard(timing: t)),
            ],

            // Non-Admin Quick Sharing & Save Actions
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TNTColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.bookmark_border_rounded,
                    label: translate('save_btn'),
                    onTap: () => _handleSave(localizations),
                  ),
                  Container(width: 1, height: 24, color: TNTColors.border),
                  _buildActionButton(
                    icon: Icons.notifications_active_outlined,
                    label: translate('reminder_btn'),
                    onTap: () => _handleReminder(localizations),
                  ),
                  Container(width: 1, height: 24, color: TNTColors.border),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: translate('share_btn'),
                    onTap: () => _handleShare(localizations),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: TNTColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: TNTColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
