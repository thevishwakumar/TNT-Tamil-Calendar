import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/tnt_reminder_dialog.dart';
import '../../core/widgets/tnt_share_sheet.dart';
import '../../models/tnt_models.dart';
import '../../services/saved_items_service.dart';
import '../../services/reminder_service.dart';
import '../../services/share_service.dart';
import '../../services/supabase_service.dart';
import 'special_day_detail_screen.dart';

class SpecialDaysScreen extends StatefulWidget {
  final ITNTApiService apiService;

  const SpecialDaysScreen({super.key, required this.apiService});

  @override
  _SpecialDaysScreenState createState() => _SpecialDaysScreenState();
}

class _SpecialDaysScreenState extends State<SpecialDaysScreen> with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  List<SpecialDay> _specialDays = [];
  final Map<String, List<SpecialDay>> _cache = {};
  bool _isLoading = true;
  String? _errorMessage;

  final SavedItemsService _savedService = SavedItemsService();
  final ReminderService _reminderService = ReminderService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndDays();
  }

  Future<void> _loadCategoriesAndDays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cats = await widget.apiService.getApprovedSpecialDayCategories();
      final days = await widget.apiService.getSpecialDays(
        _selectedDate.year, 
        _selectedDate.month,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );

      setState(() {
        _categories = cats;
        _specialDays = days;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
    });
    _loadCategoriesAndDays();
  }

  void _prevMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _loadCategoriesAndDays();
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _loadCategoriesAndDays();
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now;
      _selectedCategory = 'All';
    });
    _loadCategoriesAndDays();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return ListenableBuilder(
      listenable: Listenable.merge([_savedService, _reminderService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: TNTColors.background,
          appBar: AppBar(
            backgroundColor: TNTColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: TNTColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isTamil ? 'சிறப்பு நாட்கள்' : 'Special Days',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: TNTColors.border, height: 1),
            ),
            actions: [ const TNTBrandHeader(), 
              TextButton(
                onPressed: _jumpToToday,
                child: Text(
                  isTamil ? 'இன்று' : 'Today',
                  style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Month Navigation Bar
              Container(
                color: TNTColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28, color: TNTColors.primary),
                      onPressed: _prevMonth,
                      tooltip: isTamil ? 'முந்தைய மாதம்' : 'Previous Month',
                    ),
                    Column(
                      children: [
                        Text(
                          '${_getMonthName(_selectedDate.month, isTamil)} ${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.textPrimary,
                          ),
                        ),
                        Text(
                          _getTamilMonthSeason(_selectedDate.month, isTamil),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TNTColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28, color: TNTColors.primary),
                      onPressed: _nextMonth,
                      tooltip: isTamil ? 'அடுத்த மாதம்' : 'Next Month',
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              Container(
                color: TNTColors.surface,
                padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      final label = _localizeCategory(cat, isTamil);

                      return InkWell(
                        onTap: () => _onCategorySelected(cat),
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? TNTColors.primary : TNTColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? TNTColors.primary : TNTColors.border,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : TNTColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const Divider(color: TNTColors.border, height: 1),

              // List of Special Days
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 36, color: Colors.redAccent),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadCategoriesAndDays,
                                  style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary),
                                  child: Text(isTamil ? 'மீண்டும் முயற்சி செய்' : 'Retry'),
                                ),
                              ],
                            ),
                          )
                        : _specialDays.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: TNTColors.primary.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.star_border_rounded, size: 40, color: TNTColors.primary),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        isTamil ? 'சிறப்பு நாட்கள் ஏதுமில்லை' : 'No Special Days Found',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isTamil 
                                            ? 'தேர்ந்தெடுக்கப்பட்ட மாதத்தில் இந்த பிரிவில் சிறப்பு நாட்கள் இல்லை.' 
                                            : 'No special days match this category for the selected month.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _specialDays.length,
                                itemBuilder: (context, index) {
                                  final day = _specialDays[index];
                                  return _buildSpecialDayCard(context, day, isTamil);
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialDayCard(BuildContext context, SpecialDay day, bool isTamil) {
    final displayTitle = isTamil ? day.titleTa : day.title;
    final displayCategory = isTamil ? day.categoryTa : day.category;
    final displayDesc = isTamil ? day.descriptionTa : day.description;
    final isSaved = _savedService.isItemSaved('special_day', day.id);
    final hasReminder = _reminderService.hasReminder('special_day', day.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Date Banner
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpecialDayDetailScreen(
                    specialDay: day,
                    apiService: widget.apiService,
                  ),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date box
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.date.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: TNTColors.primaryDark,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTamil ? day.dayOfWeekTa : (day.dayOfWeekEn.length >= 3 ? day.dayOfWeekEn.substring(0, 3) : day.dayOfWeekEn).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                displayCategory.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: TNTColors.textMuted),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.textPrimary,
                          ),
                        ),
                        if (day.tamilDateStr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            day.tamilDateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: TNTColors.primaryDark,
                            ),
                          ),
                        ],
                        if (displayDesc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            displayDesc,
                            style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary, height: 1.3),
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
          ),

          // Bottom Action Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TNTColors.border, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _savedService.toggleSave(SavedItem(
                      id: 'saved-${day.id}',
                      userId: 'dev-user-id-001',
                      itemType: 'special_day',
                      itemId: day.id,
                      savedAt: DateTime.now(),
                      title: day.title,
                      titleTa: day.titleTa,
                      subtitle: day.description,
                      subtitleTa: day.descriptionTa,
                      date: day.date,
                      tamilDateStr: day.tamilDateStr,
                      category: day.category,
                      categoryTa: day.categoryTa,
                    ));
                  },
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    size: 16,
                    color: isSaved ? TNTColors.primary : TNTColors.textSecondary,
                  ),
                  label: Text(
                    isSaved ? (isTamil ? 'சேமிக்கப்பட்டது' : 'Saved') : (isTamil ? 'சேமி' : 'Save'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSaved ? TNTColors.primary : TNTColors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    TNTReminderDialog.show(
                      context,
                      itemType: 'special_day',
                      itemId: day.id,
                      title: day.title,
                      titleTa: day.titleTa,
                      subtitle: day.description,
                      subtitleTa: day.descriptionTa,
                      eventDate: day.date,
                    );
                  },
                  icon: Icon(
                    hasReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    size: 16,
                    color: hasReminder ? TNTColors.primary : TNTColors.textSecondary,
                  ),
                  label: Text(
                    isTamil ? 'நினைவூட்டல்' : 'Reminder',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasReminder ? TNTColors.primary : TNTColors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final text = ShareService.formatSpecialDay(specialDay: day, isTamil: isTamil);
                    TNTShareSheet.show(
                      context,
                      title: isTamil ? 'சிறப்பு நாள் தகவல் பகிர்வு' : 'Share Special Day',
                      content: text,
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 16, color: TNTColors.textSecondary),
                  label: Text(
                    isTamil ? 'பகிர்' : 'Share',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month, bool isTamil) {
    const en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    const ta = ['ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'];
    return isTamil ? ta[month - 1] : en[month - 1];
  }

  String _getTamilMonthSeason(int month, bool isTamil) {
    const ta = ['தை - மாசி', 'மாசி - பங்குனி', 'பங்குனி - சித்திரை', 'சித்திரை - வைகாசி', 'வைகாசி - ஆனி', 'ஆனி - ஆடி', 'ஆடி - ஆவணி', 'ஆவணி - புரட்டாசி', 'புரட்டாசி - ஐப்பசி', 'ஐப்பசி - கார்த்திகை', 'கார்த்திகை - மார்கழி', 'மார்கழி - தை'];
    const en = ['Thai - Masi', 'Masi - Panguni', 'Panguni - Chithirai', 'Chithirai - Vaikasi', 'Vaikasi - Aani', 'Aani - Aadi', 'Aadi - Aavani', 'Aavani - Purattasi', 'Purattasi - Aippasi', 'Aippasi - Karthigai', 'Karthigai - Margazhi', 'Margazhi - Thai'];
    return isTamil ? ta[(month - 1) % 12] : en[(month - 1) % 12];
  }

  String _localizeCategory(String cat, bool isTamil) {
    if (!isTamil) return cat;
    switch (cat.toLowerCase()) {
      case 'all':
        return 'அனைத்தும்';
      case 'amavasai':
        return 'அமாவாசை';
      case 'pournami':
        return 'பௌர்ணமி';
      case 'pradosham':
        return 'பிரதோஷம்';
      case 'sashti':
        return 'சஷ்டி';
      case 'ekadashi':
        return 'ஏகாதசி';
      case 'krithigai':
        return 'கிருத்திகை';
      case 'chaturthi':
        return 'சதுர்த்தி';
      case 'sankatahara chaturthi':
      case 'sankatahara_chaturthi':
        return 'சங்கடஹர சதுர்த்தி';
      case 'ashtami':
        return 'அஷ்டமி';
      case 'navami':
        return 'நவமி';
      case 'special day':
      case 'special_day':
        return 'சிறப்பு நாள்';
      default:
        return cat;
    }
  }
}
