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

class FestivalDetailScreen extends StatefulWidget {
  final Festival festival;
  final ITNTApiService? apiService;

  const FestivalDetailScreen({
    super.key,
    required this.festival,
    this.apiService,
  });

  @override
  _FestivalDetailScreenState createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  final SavedItemsService _savedService = SavedItemsService();
  final ReminderService _reminderService = ReminderService();

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    final f = widget.festival;

    final displayName = isTamil ? f.nameTa : f.name;
    final displayType = isTamil ? f.typeTa : f.type;
    final displayDesc = isTamil ? f.descriptionTa : f.description;
    final displayRituals = isTamil ? f.ritualsTa : f.rituals;
    final displayDeity = isTamil ? f.deityTa : f.deity;
    final displaySignificance = isTamil ? f.significanceTa : f.significance;

    return ListenableBuilder(
      listenable: Listenable.merge([_savedService, _reminderService]),
      builder: (context, _) {
        final isSaved = _savedService.isItemSaved('festival', f.id);
        final hasReminder = _reminderService.hasReminder('festival', f.id);

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
              isTamil ? 'திருவிழா விவரம்' : 'Festival Details',
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
                    id: 'saved-${f.id}',
                    userId: 'dev-user-id-001',
                    itemType: 'festival',
                    itemId: f.id,
                    savedAt: DateTime.now(),
                    title: f.name,
                    titleTa: f.nameTa,
                    subtitle: f.description,
                    subtitleTa: f.descriptionTa,
                    date: f.date,
                    tamilDateStr: f.tamilDateStr,
                    category: f.category,
                    categoryTa: f.categoryTa,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: TNTColors.primary,
                      duration: const Duration(seconds: 2),
                      content: Text(
                        isSaved 
                            ? (isTamil ? 'சேமிப்பிலிருந்து நீக்கப்பட்டது' : 'Removed from Saved') 
                            : (isTamil ? 'பண்டிகை சேமிக்கப்பட்டது' : 'Festival Saved'),
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
                // Hero Banner
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
                          // Date box
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
                                  '${f.date.day}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: TNTColors.primaryDark,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isTamil ? f.dayOfWeekTa : (f.dayOfWeekEn.length >= 3 ? f.dayOfWeekEn.substring(0, 3) : f.dayOfWeekEn).toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Titles & badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBBDEFB)),
                                      ),
                                      child: Text(
                                        displayType.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1565C0),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (f.isHoliday) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFC8E6C9)),
                                        ),
                                        child: Text(
                                          isTamil ? 'அரசு விடுமுறை' : 'HOLIDAY',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: TNTColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${f.tamilMonth} · ${f.tamilDateStr}',
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

                      if (displayDeity.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: TNTColors.border, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.temple_hindu_rounded, size: 16, color: TNTColors.textSecondary),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isTamil ? 'வழிபடும் தெய்வம்' : 'Associated Deity', style: const TextStyle(fontSize: 10, color: TNTColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(displayDeity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TNTColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                _buildSectionCard(
                  title: isTamil ? 'பண்டிகைக் குறிப்பு' : 'Festival Description',
                  icon: Icons.info_outline_rounded,
                  content: Text(
                    displayDesc,
                    style: const TextStyle(fontSize: 13, color: TNTColors.textPrimary, height: 1.5),
                  ),
                ),

                if (displayRituals.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: isTamil ? 'கொண்டாட்ட முறைகள் & வழிபாடுகள்' : 'Rituals & Celebrations',
                    icon: Icons.celebration_rounded,
                    content: Text(
                      displayRituals,
                      style: const TextStyle(fontSize: 13, color: TNTColors.textPrimary, height: 1.5),
                    ),
                  ),
                ],

                if (displaySignificance.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: isTamil ? 'ஆன்மீக முக்கியத்துவம்' : 'Spiritual Significance',
                    icon: Icons.auto_awesome_rounded,
                    content: Text(
                      displaySignificance,
                      style: const TextStyle(fontSize: 13, color: TNTColors.textPrimary, height: 1.5),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // View Day's full Panchangam
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DateDetailsScreen(
                            date: f.date,
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
      itemType: 'festival',
      itemId: widget.festival.id,
      title: widget.festival.name,
      titleTa: widget.festival.nameTa,
      subtitle: widget.festival.description,
      subtitleTa: widget.festival.descriptionTa,
      eventDate: widget.festival.date,
    );
  }

  void _openShareSheet(BuildContext context, bool isTamil) {
    final text = ShareService.formatFestival(
      festival: widget.festival,
      isTamil: isTamil,
    );
    TNTShareSheet.show(
      context,
      title: isTamil ? 'திருவிழா தகவல் பகிர்வு' : 'Share Festival',
      content: text,
    );
  }
}
