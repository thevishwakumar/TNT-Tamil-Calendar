import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../core/widgets/saved_item_card.dart';
import '../../models/tnt_models.dart';
import '../../services/saved_items_service.dart';
import '../../services/supabase_service.dart';
import '../../muhurtham/screens/muhurtham_detail_screen.dart';
import '../../special_days/screens/special_day_detail_screen.dart';
import '../../festivals/screens/festival_detail_screen.dart';
import '../../calendar/screens/date_details_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  final ITNTApiService apiService;

  const SavedItemsScreen({super.key, required this.apiService});

  @override
  _SavedItemsScreenState createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  SavedItemType _selectedFilter = SavedItemType.all;
  final SavedItemsService _savedService = SavedItemsService();

  @override
  void initState() {
    super.initState();
    _savedService.refresh();
  }

  void _openDetail(SavedItem item) async {
    final date = item.date ?? DateTime.now();

    switch (item.typeEnum) {
      case SavedItemType.muhurtham:
        // Load full Muhurtham date or construct from metadata
        final muhurthams = await widget.apiService.getMuhurthamDates(
          year: date.year, 
          month: date.month,
        );
        final found = muhurthams.firstWhere(
          (m) => m.id == item.itemId,
          orElse: () => MuhurthamDate(
            id: item.itemId,
            date: date,
            tamilDateStr: item.tamilDateStr,
            startTime: '06:00 AM',
            endTime: '07:30 AM',
            isValarthirai: true,
            description: item.subtitle,
            descriptionTa: item.subtitleTa,
            category: item.category.isNotEmpty ? item.category : 'Marriage',
            categoryTa: item.categoryTa.isNotEmpty ? item.categoryTa : 'திருமணம்',
          ),
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MuhurthamDetailScreen(
                muhurtham: found,
                apiService: widget.apiService,
              ),
            ),
          );
        }
        break;

      case SavedItemType.specialDay:
        final specialDays = await widget.apiService.getSpecialDays(date.year, date.month);
        final found = specialDays.firstWhere(
          (s) => s.id == item.itemId,
          orElse: () => SpecialDay(
            id: item.itemId,
            date: date,
            tamilDateStr: item.tamilDateStr,
            title: item.title,
            titleTa: item.titleTa,
            category: item.category.isNotEmpty ? item.category : 'special_day',
            categoryTa: item.categoryTa.isNotEmpty ? item.categoryTa : 'சிறப்பு நாள்',
            isHoliday: false,
            description: item.subtitle,
            descriptionTa: item.subtitleTa,
          ),
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpecialDayDetailScreen(
                specialDay: found,
                apiService: widget.apiService,
              ),
            ),
          );
        }
        break;

      case SavedItemType.festival:
        final festivals = await widget.apiService.getFestivals(date.year, date.month);
        final found = festivals.firstWhere(
          (f) => f.id == item.itemId,
          orElse: () => Festival(
            id: item.itemId,
            date: date,
            tamilDateStr: item.tamilDateStr,
            name: item.title,
            nameTa: item.titleTa,
            type: item.category.toLowerCase().contains('gov') ? 'government' : 'hindu',
            category: item.category.isNotEmpty ? item.category : 'Festivals',
            categoryTa: item.categoryTa.isNotEmpty ? item.categoryTa : 'பண்டிகைகள்',
            description: item.subtitle,
            descriptionTa: item.subtitleTa,
          ),
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FestivalDetailScreen(
                festival: found,
                apiService: widget.apiService,
              ),
            ),
          );
        }
        break;

      case SavedItemType.panchangam:
      case SavedItemType.all:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DateDetailsScreen(
              date: date,
              apiService: widget.apiService,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

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
          isTamil ? 'சேமிக்கப்பட்டவை' : 'Saved Items',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
        actions: [ const TNTBrandHeader(), 
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: () => _savedService.refresh(),
            tooltip: isTamil ? 'புதுப்பி' : 'Refresh',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _savedService,
        builder: (context, _) {
          final allItems = _savedService.items;
          final filteredItems = _savedService.getSavedItemsByType(_selectedFilter);

          return Column(
            children: [
              // Filter Chips Row
              Container(
                color: TNTColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(SavedItemType.all, isTamil, allItems.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        SavedItemType.panchangam, 
                        isTamil, 
                        allItems.where((i) => i.typeEnum == SavedItemType.panchangam).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        SavedItemType.muhurtham, 
                        isTamil, 
                        allItems.where((i) => i.typeEnum == SavedItemType.muhurtham).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        SavedItemType.specialDay, 
                        isTamil, 
                        allItems.where((i) => i.typeEnum == SavedItemType.specialDay).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        SavedItemType.festival, 
                        isTamil, 
                        allItems.where((i) => i.typeEnum == SavedItemType.festival).length,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: TNTColors.border, height: 1),

              // Content Area
              Expanded(
                child: RefreshIndicator(
                  color: TNTColors.primary,
                  onRefresh: () => _savedService.refresh(),
                  child: _savedService.isLoading
                      ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
                      : filteredItems.isEmpty
                          ? _buildEmptyState(isTamil)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return SavedItemCard(
                                  item: item,
                                  onOpen: () => _openDetail(item),
                                  onRemove: () async {
                                    await _savedService.unsaveItem(item.itemType, item.itemId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: TNTColors.primaryDark,
                                          duration: const Duration(seconds: 2),
                                          content: Text(
                                            isTamil ? 'சேமிப்பிலிருந்து நீக்கப்பட்டது' : 'Item removed from saved',
                                          ),
                                          action: SnackBarAction(
                                            label: isTamil ? 'மீட்டெடு' : 'Undo',
                                            textColor: Colors.amberAccent,
                                            onPressed: () => _savedService.saveItem(item),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(SavedItemType type, bool isTamil, int count) {
    final isSelected = _selectedFilter == type;
    final label = type.label(isTamil);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = type;
        });
      },
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : TNTColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : TNTColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : TNTColors.primaryDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTamil) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded, size: 48, color: TNTColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              isTamil ? 'சேமிக்கப்பட்டவை ஏதுமில்லை' : 'No Saved Items Found',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'பஞ்சாங்கம், முகூர்த்தம், சிறப்பு நாட்கள் மற்றும் பண்டிகைகளை நீங்கள் புக்மார்க் செய்யும்போது இங்கே தோன்றும்.'
                  : 'Bookmark auspicious muhurthams, festivals, special days, or panchangam days to access them anytime.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(
                isTamil ? 'நாள்காட்டியைப் பார்க்கவும்' : 'Browse Calendar',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
