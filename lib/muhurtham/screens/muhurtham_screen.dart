import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/state_widgets.dart';
import '../../core/widgets/tnt_loading_overlay.dart';
import '../../core/widgets/tnt_error_overlay.dart';
import '../../models/tnt_models.dart';
import '../../panchangam/widgets/city_selector_sheet.dart';
import '../../services/supabase_service.dart';
import '../widgets/muhurtham_date_card.dart';
import '../widgets/muhurtham_reminder_dialog.dart';
import '../widgets/muhurtham_share_sheet.dart';
import 'muhurtham_detail_screen.dart';

class MuhurthamScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final Function(int)? onTabChanged;

  const MuhurthamScreen({
    super.key,
    required this.apiService,
    this.onTabChanged,
  });

  @override
  _MuhurthamScreenState createState() => _MuhurthamScreenState();
}

class _MuhurthamScreenState extends State<MuhurthamScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();
  String _selectedLocation = 'Chennai';
  String _selectedCategory = 'All';
  String _selectedPhase = 'All'; // 'All', 'valarpirai', 'theipirai'

  List<String> _categories = ['All', 'Marriage', 'Housewarming', 'Engagement', 'Business'];
  List<MuhurthamDate> _muhurthams = [];
  final Map<String, List<MuhurthamDate>> _cache = {};

  final _dbService = SupabaseService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initCategoriesAndData();
    _triggerAnalytics('muhurtham_view');
  }

  void _triggerAnalytics(String eventName, [Map<String, dynamic>? meta]) async {
    final analyticsRepo = AnalyticsRepository();
    await analyticsRepo.logEvent(eventName: eventName, metadata: meta);
  }

  Future<void> _initCategoriesAndData() async {
    try {
      final approvedCats = await widget.apiService.getApprovedMuhurthamCategories();
      if (mounted) {
        setState(() {
          _categories = ['All', ...approvedCats];
        });
      }
    } catch (_) {}
    _loadMuhurthams();
  }

  Future<void> _loadMuhurthams({bool isRefresh = false}) async {
    final cacheKey = '${_selectedDate.year}-${_selectedDate.month}-$_selectedCategory-$_selectedPhase-$_selectedLocation';
    if (!(isRefresh) && _cache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _muhurthams = _cache[cacheKey]!;
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final list = await widget.apiService.getMuhurthamDates(
        year: _selectedDate.year,
        month: _selectedDate.month,
        category: _selectedCategory,
        phase: _selectedPhase,
        location: _selectedLocation,
      );

      if (!mounted) return;
      setState(() {
        _muhurthams = list;
        _cache[cacheKey] = list;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        print(e.toString());
        _errorMessage = e.toString();
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _loadMuhurthams();
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _loadMuhurthams();
  }

  void _jumpToCurrentMonth() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadMuhurthams();
  }

  void _toggleSaveMuhurtham(MuhurthamDate m) async {
    final nextSaved = !m.isSaved;
    setState(() {
      final idx = _muhurthams.indexWhere((x) => x.id == m.id);
      if (idx != -1) {
        _muhurthams[idx] = _muhurthams[idx].copyWith(isSaved: nextSaved);
      }
    });

    try {
      await widget.apiService.toggleSaveItem('muhurtham', m.id);
      _triggerAnalytics('muhurtham_saved', {'id': m.id, 'category': m.category});
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

  void _openReminderDialog(MuhurthamDate m) {
    showDialog(
      context: context,
      builder: (ctx) => MuhurthamReminderDialog(
        muhurtham: m,
        onConfirm: (label, scheduled) async {
          setState(() {
            final idx = _muhurthams.indexWhere((x) => x.id == m.id);
            if (idx != -1) {
              _muhurthams[idx] = _muhurthams[idx].copyWith(hasReminder: true);
            }
          });
          try {
            await widget.apiService.setReminder(
              '${m.category} - ${m.tamilDateStr}',
              m.date,
              m.startTime,
            );
            _triggerAnalytics('muhurtham_reminder_set', {'id': m.id, 'offset': label});
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

  void _openShareSheet(MuhurthamDate m) {
    _triggerAnalytics('muhurtham_shared', {'id': m.id, 'category': m.category});
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MuhurthamShareSheet(muhurtham: m),
    );
  }

  void _openDetailScreen(MuhurthamDate m) {
    _triggerAnalytics('muhurtham_detail_view', {'id': m.id, 'category': m.category});
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MuhurthamDetailScreen(
          muhurtham: m,
          apiService: widget.apiService,
          onNavigateTab: widget.onTabChanged,
        ),
      ),
    ).then((_) {
      // Refresh list to sync bookmarks & reminders
      _loadMuhurthams();
    });
  }

  void _openCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CitySelectorSheet(
        selectedCity: _selectedLocation,
        onCitySelected: (city) {
          setState(() => _selectedLocation = city);
          _loadMuhurthams();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        backgroundColor: TNTColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: TNTColors.primary, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              localizations?.translate('muhurtham') ?? 'Muhurtham',
              style: const TextStyle(fontWeight: FontWeight.w900, color: TNTColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        actions: [ const TNTBrandHeader(), 
          // City selector button
          InkWell(
            onTap: _openCitySelector,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: TNTColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TNTColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: TNTColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.textSecondary, size: 20),
            onPressed: () => _loadMuhurthams(isRefresh: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: TNTColors.primary,
        onRefresh: () => _loadMuhurthams(isRefresh: true),
        child: Column(
          children: [
            // Month Navigation Bar
            _buildMonthNavBar(isTamil, localizations),

            // Category & Phase Filters
            _buildFilterSection(isTamil, localizations),

            // Active count indicator strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: TNTColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_muhurthams.length} ${localizations?.translate('muhurtham_dates') ?? 'Muhurtham Dates'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                  ),
                  if (_selectedCategory != 'All' || _selectedPhase != 'All')
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedPhase = 'All';
                        });
                        _loadMuhurthams();
                      },
                      child: Text(
                        isTamil ? 'அனைத்தையும் காட்டு' : 'Clear Filters',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: TNTColors.border),

            // Main Muhurtham List
            Expanded(
              child: Stack(
                children: [
                  _muhurthams.isEmpty && !_isLoading && _errorMessage == null
                      ? _buildEmptyState(isTamil, localizations)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.all(16),
                          itemCount: _muhurthams.length,
                          itemBuilder: (context, index) {
                            final item = _muhurthams[index];
                            return MuhurthamDateCard(
                              item: item,
                              onTap: () => _openDetailScreen(item),
                              onToggleSave: () => _toggleSaveMuhurtham(item),
                              onSetReminder: () => _openReminderDialog(item),
                              onShare: () => _openShareSheet(item),
                            );
                          },
                        ),
                  if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
                  if (_errorMessage != null && !_isLoading)
                    Positioned.fill(
                      child: TNTErrorOverlay(
                        onRetry: _loadMuhurthams,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavBar(bool isTamil, TNTLocalizations? localizations) {
    final monthName = _getMonthName(_selectedDate.month, isTamil);
    final isCurrentMonth = _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month;

    return Container(
      color: TNTColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: TNTColors.primary),
            onPressed: _previousMonth,
          ),
          Row(
            children: [
              Text(
                '$monthName ${_selectedDate.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: TNTColors.textPrimary),
              ),
              if (!isCurrentMonth) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _jumpToCurrentMonth,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      localizations?.translate('today') ?? 'Today',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TNTColors.primaryDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: TNTColors.primary),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isTamil, TNTLocalizations? localizations) {
    return Container(
      color: TNTColors.surface,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Column(
        children: [
          // Categories Chip Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final label = _getCategoryLabel(cat, isTamil, localizations);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: TNTColors.primary,
                    backgroundColor: TNTColors.background,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : TNTColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: isSelected ? TNTColors.primary : TNTColors.border,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _loadMuhurthams();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Phase Filter Row (All, Valarpirai, Theipirai)
          Row(
            children: [
              _buildPhaseFilterButton('All', localizations?.translate('all_phases') ?? 'All Phases'),
              const SizedBox(width: 8),
              _buildPhaseFilterButton('valarpirai', localizations?.translate('valarpirai') ?? 'Valarpirai'),
              const SizedBox(width: 8),
              _buildPhaseFilterButton('theipirai', localizations?.translate('theipirai') ?? 'Theipirai'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseFilterButton(String phaseKey, String label) {
    final isSelected = _selectedPhase == phaseKey;
    return InkWell(
      onTap: () {
        setState(() => _selectedPhase = phaseKey);
        _loadMuhurthams();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? TNTColors.textPrimary : TNTColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? TNTColors.textPrimary : TNTColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : TNTColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTamil, TNTLocalizations? localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 36, color: TNTColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.translate('no_muhurtham_found') ?? 'No approved Muhurtham dates for this month',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              localizations?.translate('no_muhurtham_filter_desc') ?? 'Try selecting a different filter or month',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _selectedPhase = 'All';
                });
                _loadMuhurthams();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isTamil ? 'அனைத்து முகூர்த்தங்களையும் காட்டு' : 'Reset Filters',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String cat, bool isTamil, TNTLocalizations? localizations) {
    if (cat == 'All') return localizations?.translate('all_categories') ?? 'All';
    if (!isTamil) return cat;
    switch (cat.toLowerCase()) {
      case 'marriage':
        return 'திருமணம்';
      case 'housewarming':
        return 'கிரகப்பிரவேசம்';
      case 'engagement':
        return 'நிச்சயதார்த்தம்';
      case 'business':
        return 'தொழில்';
      default:
        return cat;
    }
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
