import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/state_widgets.dart';
import '../../core/widgets/tnt_loading_overlay.dart';
import '../../core/widgets/tnt_error_overlay.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../../special_days/screens/special_days_screen.dart';
import '../../special_days/screens/special_day_detail_screen.dart';
import '../../festivals/screens/festivals_screen.dart';
import '../../festivals/screens/festival_detail_screen.dart';
import '../../services/notification_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../services/panchang_local_cache_service.dart';
import '../../features/personal_calendar/screens/personal_calendar_screen.dart';
import '../../core/widgets/responsive_layout.dart';



class HomeScreen extends StatefulWidget {
  final ITNTApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Location selection settings
  String _selectedCity = 'Chennai';
  String _selectedState = 'Tamil Nadu';
  String _selectedCountry = 'India';
  bool _useGpsLocation = false;

  bool _isLoading = true;
  String? _errorMsg;

  // Loaded database objects
  CalendarDay? _todayCalendar;
  PanchangamEntry? _todayPanchangam;
  List<TimingEntry> _timings = [];
  List<SpecialDay> _specialDays = [];
  List<Festival> _festivals = [];
  List<MuhurthamDate> _muhurthams = [];
  bool _isOfflineCacheActive = false;
  
  // Localized analytics non-blocking logger
  final _dbService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _triggerAnalyticsEvent('app_open');
    _loadAllHomeData();
  }

  /// Triggers non-blocking analytics events
  void _triggerAnalyticsEvent(String eventName) async {
    try {
      final user = _dbService.isInitialized ? _dbService.client.auth.currentUser : null;
      if (_dbService.isInitialized) {
        await _dbService.client.from('analytics_events').insert({
          if (user != null) 'user_id': user.id,
          'event_name': eventName,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      print('TNT ANALYTICS EVENT LOGGED: $eventName');
    } catch (_) {
      // Quietly swallow analytics logs to keep application from crashing
    }
  }

  /// Dynamic asynchronous data loader
  Future<void> _loadAllHomeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    _triggerAnalyticsEvent('home_view');

    try {
      final now = DateTime.now();
      
      // Async fetching from repositories/services
      final calendarFuture = widget.apiService.getCalendarDay(now);
      final panchangamFuture = widget.apiService.getPanchangam(now);
      final timingsFuture = widget.apiService.getImportantTimings(now);
      final specialDaysFuture = widget.apiService.getSpecialDays(now.year, now.month);
      final festivalsFuture = widget.apiService.getFestivals(now.year, now.month);
      final muhurthamsFuture = widget.apiService.getMarriageMuhurthams(now.year, now.month);

      final results = await Future.wait([
        calendarFuture,
        panchangamFuture,
        timingsFuture,
        specialDaysFuture,
        festivalsFuture,
        muhurthamsFuture
      ]);

      final hasCached = await PanchangLocalCacheService().hasCachedPanchangam(
        date: now,
        location: _selectedCity,
      );

      if (mounted) {
        setState(() {
          _todayCalendar = results[0] as CalendarDay;
          _todayPanchangam = results[1] as PanchangamEntry;
          _timings = results[2] as List<TimingEntry>;
          _specialDays = results[3] as List<SpecialDay>;
          _festivals = results[4] as List<Festival>;
          _muhurthams = results[5] as List<MuhurthamDate>;
          _isOfflineCacheActive = hasCached;
          _isLoading = false;
        });
      }
    } catch (e) {
      final now = DateTime.now();
      final cachedBundle = await PanchangLocalCacheService().getCachedDailyPanchangam(
        date: now,
        location: _selectedCity,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (cachedBundle != null) {
            _todayCalendar = cachedBundle.calendarDay;
            _todayPanchangam = cachedBundle.panchangam;
            _timings = cachedBundle.timings;
            _specialDays = cachedBundle.specialDays;
            _festivals = cachedBundle.festivals;
            _muhurthams = cachedBundle.muhurthams;
            _isOfflineCacheActive = true;
            _errorMsg = null;
          } else {
            _errorMsg = e.toString();
          }
        });
      }
    }
  }

  /// Pull-to-refresh reload hook
  Future<void> _handleRefresh() async {
    await _loadAllHomeData();
    _triggerAnalyticsEvent('pull_to_refresh');
  }

  /// Location Settings Picker Dialog
  void _showLocationPicker(BuildContext context, String Function(String) translate) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        String tempCity = _selectedCity;
        bool tempGps = _useGpsLocation;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: TNTColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                translate('location'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use GPS option
                    SwitchListTile(
                      activeThumbColor: TNTColors.primary,
                      title: Text(
                        translate('use_current_location'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      value: tempGps,
                      onChanged: (bool val) {
                        setModalState(() {
                          tempGps = val;
                          if (val) {
                            // Actual location fetching will be handled by LocationRepository
                          }
                        });
                      },
                    ),
                    const Divider(color: TNTColors.border),
                    const SizedBox(height: 8),

                    if (!tempGps) ...[
                      Text(
                        translate('select_location_manually'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: TNTColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: TNTColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tempCity,
                            isExpanded: true,
                            onChanged: (String? newVal) {
                              if (newVal != null) {
                                setModalState(() {
                                  tempCity = newVal;
                                });
                              }
                            },
                            items: <String>['Chennai', 'Madurai', 'Coimbatore', 'Trichy', 'Salem', 'Tirunelveli']
                                .map<DropdownMenuItem<String>>((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(translate(val.toLowerCase()), style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: Colors.green, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                translate('gps_accuracy_active'),
                                style: TextStyle(color: Colors.green.shade800, fontSize: 11),
                              ),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(translate('cancel'), style: const TextStyle(color: TNTColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCity = tempCity;
                      _useGpsLocation = tempGps;
                      if (tempGps) {
                        _selectedCity = 'Coimbatore';
                        _selectedState = 'Tamil Nadu';
                        _selectedCountry = 'India';
                      } else {
                        _selectedState = 'Tamil Nadu';
                        _selectedCountry = 'India';
                      }
                    });
                    Navigator.of(ctx).pop();
                    _loadAllHomeData(); // Reload timings based on location changes
                    _triggerAnalyticsEvent('location_changed');
                  },
                  child: Text(translate('save_btn'), style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = TNTLocalizationsProvider.of(context);
    final localizations = provider?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;
    final isTamil = localizations?.language == AppLanguage.tamil;

    // 1. Loading Skeleton / Spinner
    if (_isLoading) {
      return Scaffold(
        backgroundColor: TNTColors.background,
        appBar: _buildHeaderBar(translate),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: TNTColors.primary),
              SizedBox(height: 12),
              Text(
                'Loading today astro metrics...',
                style: TextStyle(fontSize: 12, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      );
    }

    // 2. Safe localized error layout with retry hook
    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: TNTColors.background,
        body: TNTErrorWidget(
          message: translate('error_loading'),
          onRetry: _loadAllHomeData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: _buildHeaderBar(translate),
      body: Stack(
        children: [
          RefreshIndicator(
            color: TNTColors.primary,
            backgroundColor: TNTColors.surface,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 1. Today's prominent Date Card
                  _buildTodayDateCard(translate, isTamil),
                  const SizedBox(height: 16),

                  // 2. Quick navigation shortcuts
                  _buildQuickActionsGrid(translate),
                  const SizedBox(height: 18),

                  // 3. Today's Panchangam Grid
                  _buildPanchangamAspectsGrid(translate, isTamil),
                  const SizedBox(height: 18),

                  // 4. Important auspicious/inauspicious timing details
                  _buildImportantTimingsBlock(translate, isTamil),
                  const SizedBox(height: 18),

                  // 5. Today's Special & Festival Highlights (Database driven, no hardcoding)
                  _buildTodaysSpecialHighlight(translate, isTamil),
                  const SizedBox(height: 18),

                  // 6. Upcoming Festivals with VIEW ALL
                  _buildUpcomingFestivalsBlock(translate, isTamil),
                  const SizedBox(height: 18),

                  // 7. Upcoming Special Days with VIEW ALL
                  _buildUpcomingSpecialDaysBlock(translate, isTamil),
                  const SizedBox(height: 18),

                  // 8. Upcoming Muhurtham preview (Strictly from database, avoids ai slop)
                  _buildMuhurthamPreviewBlock(translate, isTamil),
                  const SizedBox(height: 18),

                  // 9. Featured promotional media (Guarded from Draft/Pending timeline)
                  _buildFeaturedContentCard(translate, isTamil),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
          if (_errorMsg != null && !_isLoading)
            Positioned.fill(
              child: TNTErrorOverlay(
                onRetry: _loadAllHomeData,
              ),
            ),
        ],
      ),
    );
  }

  /// Header with custom logo/location bar
  PreferredSizeWidget _buildHeaderBar(String Function(String) translate) {
    return AppBar(
      elevation: 0,
      backgroundColor: TNTColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          // Elegant Saffron core name
          const Text(
            'TNT',
            style: TextStyle(
              color: TNTColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          
          // Location Selector Bubble
          GestureDetector(
            onTap: () => _showLocationPicker(context, translate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TNTColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TNTColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: TNTColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    translate(_selectedCity.toLowerCase()),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: TNTColors.textSecondary),
                ],
              ),
            ),
          )
        ],
      ),
      actions: [ const TNTBrandHeader(), 
        // Bell icon shortcut with live unread badge and navigation
        ListenableBuilder(
          listenable: NotificationService(),
          builder: (context, _) {
            final unread = NotificationService().unreadCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    _triggerAnalyticsEvent('bell_clicked');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(apiService: widget.apiService),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded, color: TNTColors.textPrimary),
                  tooltip: translate('notifications'),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: TNTColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        
        // Profile Avatar shortcut
        IconButton(
          onPressed: () {
            _triggerAnalyticsEvent('avatar_clicked');
          },
          icon: const Icon(Icons.account_circle_outlined, color: TNTColors.textPrimary),
          tooltip: translate('profile'),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: TNTColors.border, height: 1),
      ),
    );
  }

  /// Big Date Banner Section
  Widget _buildTodayDateCard(String Function(String) translate, bool isTamil) {
    final cal = _todayCalendar;
    if (cal == null) return const TNTLoadingWidget(message: 'Loading...');
    final now = DateTime.now();

    final monthsEng = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final daysEng = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysTa = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];

    final gregorianMonth = monthsEng[now.month - 1];
    final gregorianDay = isTamil ? daysTa[now.weekday - 1] : daysEng[now.weekday - 1];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border),
        boxShadow: const [BoxShadow(color: TNTColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                translate('today_tamil_date'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cal.isAuspicious ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cal.isAuspicious ? translate('auspicious_day') : translate('inauspicious_day'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cal.isAuspicious ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Large Numeric Tamil Day Bubble
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: TNTColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TNTColors.primary.withValues(alpha: 0.12), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cal.tamilDay}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TNTColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              
              // Tamil Month / Tamil Year detailed block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cal.tamilMonth,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: TNTColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cal.tamilYear,
                      style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              
              // Corresponding Gregorian Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${now.day} $gregorianMonth',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TNTColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gregorianDay,
                    style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  /// Quick Actions links
  Widget _buildQuickActionsGrid(String Function(String) translate) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = ResponsiveLayout.isDesktop(context) ? 8 : ResponsiveLayout.isTablet(context) ? 6 : 4;
        if (constraints.maxWidth < 360) count = 3; // Prevent text clipping on narrow phones

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
        _buildActionTile(translate('calendar'), Icons.calendar_month_rounded, Colors.blue),
        _buildActionTile(translate('panchangam'), Icons.shield_moon_rounded, TNTColors.primary),
        _buildActionTile(translate('muhurtham'), Icons.favorite_rounded, TNTColors.accent),
        _buildActionTile('My Calendar', Icons.event_note, Colors.teal),
        _buildActionTile(translate('special_days'), Icons.star_rounded, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildActionTile(String label, IconData icon, Color col) {
    return Container(
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TNTColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _triggerAnalyticsEvent('quick_action_${label.toLowerCase()}');
            if (label == 'My Calendar') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalCalendarScreen()));
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: col.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: col),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Today's Panchangam Details Row Blocks
  Widget _buildPanchangamAspectsGrid(String Function(String) translate, bool isTamil) {
    final pan = _todayPanchangam;
    if (pan == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: TNTColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TNTColors.border)),
        child: Text(translate('no_data'), style: const TextStyle(fontSize: 12, color: TNTColors.textMuted)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translate('today_panchangam'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            if (_isOfflineCacheActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.offline_pin_rounded, size: 12, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      isTamil ? 'உள்ளூர் சேமிப்பகம்' : 'Offline Cached',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Tithi & Nakshatram Grid
        Row(
          children: [
            Expanded(
              child: _buildAspectCell(translate('tithi'), isTamil ? pan.tithiTa : pan.tithi, Icons.shield_moon_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAspectCell(translate('nakshatra'), isTamil ? pan.nakshatraTa : pan.nakshatra, Icons.star_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAspectCell(translate('yoga'), isTamil ? pan.yogaTa : pan.yoga, Icons.wb_sunny_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAspectCell(translate('karana'), isTamil ? pan.karanaTa : pan.karana, Icons.blur_circular_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sunrise/Sunset indicators
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TNTColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TNTColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSunMoonTimingCell(translate('sunrise'), pan.sunrise, Icons.wb_sunny_rounded, Colors.orange),
              _buildSunMoonTimingCell(translate('sunset'), pan.sunset, Icons.wb_twilight_rounded, Colors.red),
              _buildSunMoonTimingCell(translate('moonrise'), pan.moonrise, Icons.nightlight_outlined, Colors.indigo),
              _buildSunMoonTimingCell(translate('moonset'), pan.moonset, Icons.nightlight_round_sharp, Colors.grey),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAspectCell(String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TNTColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TNTColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: TNTColors.textMuted)),
                const SizedBox(height: 1),
                Text(
                  val, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSunMoonTimingCell(String label, String val, IconData icon, Color col) {
    return Column(
      children: [
        Icon(icon, size: 16, color: col),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: TNTColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: TNTColors.textPrimary)),
      ],
    );
  }

  /// Important timings table with auspicious indicator dots
  Widget _buildImportantTimingsBlock(String Function(String) translate, bool isTamil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('important_timings'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: TNTColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TNTColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _timings.length,
            separatorBuilder: (context, index) => const Divider(color: TNTColors.border, height: 1),
            itemBuilder: (context, index) {
              final t = _timings[index];
              final name = isTamil ? t.nameTa : t.name;
              return ListTile(
                dense: true,
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.isAuspicious ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                trailing: Text(
                  '${t.startTime} – ${t.endTime}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  /// Today's Special & Festival highlight banner
  Widget _buildTodaysSpecialHighlight(String Function(String) translate, bool isTamil) {
    final now = DateTime.now();
    
    // Find special day or festival matching today
    final todaySpecials = _specialDays.where((s) => s.date.day == now.day && s.date.month == now.month).toList();
    final todayFests = _festivals.where((f) => f.date.day == now.day && f.date.month == now.month).toList();

    // If today has no direct match, show nearest upcoming
    final activeSpecial = todaySpecials.isNotEmpty ? todaySpecials.first : (_specialDays.isNotEmpty ? _specialDays.first : null);
    final activeFest = todayFests.isNotEmpty ? todayFests.first : (_festivals.isNotEmpty ? _festivals.first : null);

    if (activeSpecial == null && activeFest == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTamil ? 'இன்றைய சிறப்பு & பண்டிகை' : "Today's Special & Festival",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FestivalsScreen(apiService: widget.apiService),
                  ),
                );
              },
              child: Text(
                translate('view_all').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (activeFest != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TNTColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TNTColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FestivalDetailScreen(
                      festival: activeFest,
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.festival_outlined, color: Color(0xFF1565C0), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (isTamil ? activeFest.typeTa : activeFest.type).toUpperCase(),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                ),
                              ),
                              if (activeFest.isHoliday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isTamil ? 'விடுமுறை' : 'HOLIDAY',
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isTamil ? activeFest.nameTa : activeFest.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                          ),
                          Text(
                            isTamil ? activeFest.descriptionTa : activeFest.description,
                            style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: TNTColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ),

        if (activeSpecial != null && activeSpecial.id != activeFest?.id)
          Container(
            decoration: BoxDecoration(
              color: TNTColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TNTColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialDayDetailScreen(
                      specialDay: activeSpecial,
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.star_rounded, color: Color(0xFFE65100), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (isTamil ? activeSpecial.categoryTa : activeSpecial.category).toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isTamil ? activeSpecial.titleTa : activeSpecial.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                          ),
                          Text(
                            isTamil ? activeSpecial.descriptionTa : activeSpecial.description,
                            style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: TNTColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Upcoming Festivals list with VIEW ALL
  Widget _buildUpcomingFestivalsBlock(String Function(String) translate, bool isTamil) {
    if (_festivals.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translate('upcoming_festivals'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FestivalsScreen(apiService: widget.apiService),
                  ),
                );
              },
              child: Text(
                translate('view_all').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _festivals.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final f = _festivals[index];
            final title = isTamil ? f.nameTa : f.name;
            final desc = isTamil ? f.descriptionTa : f.description;

            return Card(
              color: TNTColors.surface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: TNTColors.border),
              ),
              child: ListTile(
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
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TNTColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${f.date.day}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: TNTColors.primaryDark, fontSize: 16),
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                subtitle: Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: TNTColors.textMuted),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Upcoming Special Days list with VIEW ALL
  Widget _buildUpcomingSpecialDaysBlock(String Function(String) translate, bool isTamil) {
    if (_specialDays.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translate('upcoming_special_days'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialDaysScreen(apiService: widget.apiService),
                  ),
                );
              },
              child: Text(
                translate('view_all').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _specialDays.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = _specialDays[index];
            final title = isTamil ? s.titleTa : s.title;
            final desc = isTamil ? s.descriptionTa : s.description;

            return Card(
              color: TNTColors.surface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: TNTColors.border),
              ),
              child: ListTile(
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
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${s.date.day}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE65100), fontSize: 16),
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                subtitle: Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: TNTColors.textMuted),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Upcoming Muhurtham preview banner
  Widget _buildMuhurthamPreviewBlock(String Function(String) translate, bool isTamil) {
    if (_muhurthams.isEmpty) return const SizedBox();
    final nextM = _muhurthams[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('marriage_muhurtham'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: TNTColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TNTColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nextM.tamilDateStr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TNTColors.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      translate(nextM.isValarthirai ? 'valarpirai' : 'theipirai').toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isTamil ? nextM.descriptionTa : nextM.description,
                style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: TNTColors.background, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: TNTColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${nextM.startTime} – ${nextM.endTime}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  /// Featured Content Card (For promotional campaigns)
  Widget _buildFeaturedContentCard(String Function(String) translate, bool isTamil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('poster_analytics'), // Localized action trigger
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.amber.shade500.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade500.withValues(alpha: 0.2), width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22),
              const SizedBox(height: 10),
              Text(
                isTamil ? "புரட்டாசி மாத பிரதோஷ வழிபாடுகள்" : "Purattasi Pradosham Puja",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isTamil 
                  ? "நமது நற்பயணங்கள் அனைத்தும் வெற்றியடைய பிரதோஷ வழிபாட்டு நேரங்கள் மற்றும் விளக்கப் படங்களை உடனே உங்கள் நண்பர்களுடன் பகிர்ந்து கொள்ளுங்கள்!"
                  : "Review auspicious timings and instantly generate shareable traditional greeting posters with your family members.",
                style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  _triggerAnalyticsEvent('featured_banner_view');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TNTColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(translate('share_btn'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        )
      ],
    );
  }
}

  Widget _buildTasteAndTraditionInfo(String Function(String) translate) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border.withOpacity(0.5)),
        boxShadow: const [BoxShadow(color: TNTColors.shadow, blurRadius: 15, offset: Offset(0, 5))],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TNTColors.primary.withOpacity(0.05),
            TNTColors.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: TNTColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'TNT – Taste & Tradition',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TNTColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: TNTColors.primary, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Experience the authentic essence of Tamil culture. We bring you accurate astrological insights, traditional panchangam, and the most auspicious muhurtham dates, deeply rooted in our heritage.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: TNTColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
