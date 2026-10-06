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
import '../../services/production_api_service.dart';
import '../../calendar/screens/date_details_screen.dart';

class SpecialDayDetailScreen extends StatefulWidget {
  final SpecialDay specialDay;
  final ITNTApiService? apiService;

  const SpecialDayDetailScreen({
    super.key,
    required this.specialDay,
    this.apiService,
  });

  @override
  _SpecialDayDetailScreenState createState() => _SpecialDayDetailScreenState();
}

class _SpecialDayDetailScreenState extends State<SpecialDayDetailScreen> {
  final SavedItemsService _savedService = SavedItemsService();
  final ReminderService _reminderService = ReminderService();

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    final s = widget.specialDay;

    final displayTitle = isTamil ? s.titleTa : s.title;
    final displayCategory = isTamil ? s.categoryTa : s.category;
    final displayDesc = isTamil ? s.descriptionTa : s.description;
    final displayRituals = isTamil ? s.ritualsTa : s.rituals;
    final displayDeity = isTamil ? s.deityTa : s.deity;
    final displaySignificance = isTamil ? s.significanceTa : s.significance;

    return ListenableBuilder(
      listenable: Listenable.merge([_savedService, _reminderService]),
      builder: (context, _) {
        final isSaved = _savedService.isItemSaved('special_day', s.id);
        final hasReminder = _reminderService.hasReminder('special_day', s.id);

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
              isTamil ? 'சிறப்பு நாள் விவரம்' : 'Special Day Details',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: TNTColors.border, height: 1),
            ),
            actions: [ const TNTBrandHeader(), 
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isSaved ? TNTColors.primary : TNTColors.textSecondary,
                ),
                onPressed: () {
                  _savedService.toggleSave(SavedItem(
                    id: 'saved-${s.id}',
                    userId: 'dev-user-id-001',
                    itemType: 'special_day',
                    itemId: s.id,
                    savedAt: DateTime.now(),
                    title: s.title,
                    titleTa: s.titleTa,
                    subtitle: s.description,
                    subtitleTa: s.descriptionTa,
                    date: s.date,
                    tamilDateStr: s.tamilDateStr,
                    category: s.category,
                    categoryTa: s.categoryTa,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: TNTColors.primary,
                      duration: const Duration(seconds: 2),
                      content: Text(
                        isSaved 
                            ? (isTamil ? 'சேமிப்பிலிருந்து நீக்கப்பட்டது' : 'Removed from Saved') 
                            : (isTamil ? 'சிறப்பு நாள் சேமிக்கப்பட்டது' : 'Special Day Saved'),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  hasReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: hasReminder ? TNTColors.primary : TNTColors.textSecondary,
                ),
                onPressed: () => _openReminderDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: TNTColors.textSecondary),
                onPressed: () => _openShareSheet(context, isTamil),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: TNTColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TNTColors.border),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calendar Badge
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: TNTColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: TNTColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${s.date.day}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: TNTColors.primaryDark,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isTamil ? s.dayOfWeekTa : s.dayOfWeekEn.substring(0, 3).toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFFE0B2)),
                                  ),
                                  child: Text(
                                    displayCategory.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE65100),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: TNTColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${s.tamilMonth} · ${s.tamilDateStr}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: TNTColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(color: TNTColors.border, height: 1),
                      const SizedBox(height: 14),

                      // Quick Info Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.person_rounded,
                              label: isTamil ? 'தெய்வம்' : 'Deity',
                              value: displayDeity,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.schedule_rounded,
                              label: isTamil ? 'விரத நேரம்' : 'Timing Window',
                              value: s.timingWindow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description Card
                _buildSectionCard(
                  title: isTamil ? 'சிறப்பு விவரம்' : 'Significance & Details',
                  icon: Icons.info_outline_rounded,
                  content: Text(
                    displayDesc,
                    style: const TextStyle(fontSize: 13, color: TNTColors.textPrimary, height: 1.5),
                  ),
                ),

                if (displayRituals.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: isTamil ? 'வழிபாட்டு முறைகள் & விரத நியதிகள்' : 'Rituals & Vrat Rules',
                    icon: Icons.self_improvement_rounded,
                    content: Text(
                      displayRituals,
                      style: const TextStyle(fontSize: 13, color: TNTColors.textPrimary, height: 1.5),
                    ),
                  ),
                ],

                if (displaySignificance.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: isTamil ? 'ஆன்மீகப் பலன்கள்' : 'Spiritual Benefits',
                    icon: Icons.auto_awesome_rounded,
                    content: Text(
                      displaySignificance,
                      style: const TextStyle(fontSize: 13, color: TNTColors.textPrimary, height: 1.5),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Action to view full day's panchangam
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DateDetailsScreen(
                            date: s.date,
                            apiService: widget.apiService ?? SupabaseApiService(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shield_moon_outlined, size: 18),
                    label: Text(
                      isTamil ? 'இன்றைய முழு பஞ்சாங்கம் காண்க' : "View Day's Full Panchangam",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TNTColors.primaryDark,
                      side: const BorderSide(color: TNTColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: TNTColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: TNTColors.textMuted, fontWeight: FontWeight.bold)),
              Text(
                value, 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TNTColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: TNTColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  void _openReminderDialog(BuildContext context) {
    TNTReminderDialog.show(
      context,
      itemType: 'special_day',
      itemId: widget.specialDay.id,
      title: widget.specialDay.title,
      titleTa: widget.specialDay.titleTa,
      subtitle: widget.specialDay.description,
      subtitleTa: widget.specialDay.descriptionTa,
      eventDate: widget.specialDay.date,
    );
  }

  void _openShareSheet(BuildContext context, bool isTamil) {
    final text = ShareService.formatSpecialDay(
      specialDay: widget.specialDay,
      isTamil: isTamil,
    );
    TNTShareSheet.show(
      context,
      title: isTamil ? 'சிறப்பு நாள் தகவல் பகிர்வு' : 'Share Special Day',
      content: text,
    );
  }
}
