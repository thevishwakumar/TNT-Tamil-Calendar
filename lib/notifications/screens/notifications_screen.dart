import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../widgets/notification_card.dart';
import 'notification_settings_screen.dart';
import '../../muhurtham/screens/muhurtham_detail_screen.dart';
import '../../festivals/screens/festival_detail_screen.dart';
import '../../special_days/screens/special_day_detail_screen.dart';
import '../../reminders/screens/reminders_screen.dart';
import '../../panchangam/screens/panchangam_screen.dart';

enum NotificationTabFilter { all, unread, muhurthamFestival, reminders }

/// Dedicated Notifications Screen
/// Supports:
/// 1. Notification history loaded from Supabase / local logs
/// 2. Read/unread visual distinction
/// 3. Mark single as read & Mark all as read
/// 4. Actionable deep linking to approved public items
/// 5. Filter tabs (All, Unread, Muhurtham & Festivals, Reminders)
/// 6. Direct shortcut to Notification Settings
class NotificationsScreen extends StatefulWidget {
  final ITNTApiService apiService;

  const NotificationsScreen({super.key, required this.apiService});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  NotificationTabFilter _selectedFilter = NotificationTabFilter.all;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  List<NotificationItem> _getFilteredNotifications(List<NotificationItem> all) {
    switch (_selectedFilter) {
      case NotificationTabFilter.unread:
        return all.where((n) => !n.isRead).toList();
      case NotificationTabFilter.muhurthamFestival:
        return all.where((n) => n.notificationType == 'muhurtham' || n.notificationType == 'festival' || n.notificationType == 'special_day').toList();
      case NotificationTabFilter.reminders:
        return all.where((n) => n.notificationType == 'reminder').toList();
      case NotificationTabFilter.all:
      default:
        return all;
    }
  }

  /// Deep linking dispatcher ensuring ONLY approved public content is opened
  /// Explicitly guards against internal schedules, admin screens, or draft items.
  void _handleNotificationTap(NotificationItem item, bool isTamil) async {
    // 1. Mark as read
    await _notificationService.markAsRead(item.id);

    if (!mounted) return;

    final type = item.relatedItemType ?? item.notificationType;
    final itemId = item.relatedItemId;

    // 2. Actionable deep linking
    if (type == 'muhurtham') {
      final now = DateTime.now();
      final muhurthams = await widget.apiService.getMarriageMuhurthams(now.year, now.month);
      MuhurthamDate? target;
      if (itemId != null && muhurthams.isNotEmpty) {
        try {
          target = muhurthams.firstWhere((m) => m.id == itemId);
        } catch (_) {
          target = muhurthams.first;
        }
      } else if (muhurthams.isNotEmpty) {
        target = muhurthams.first;
      }

      if (target != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MuhurthamDetailScreen(
              muhurtham: target!,
              apiService: widget.apiService,
            ),
          ),
        );
      }
    } else if (type == 'festival') {
      final now = DateTime.now();
      final festivals = await widget.apiService.getFestivals(now.year, now.month);
      Festival? target;
      if (itemId != null && festivals.isNotEmpty) {
        try {
          target = festivals.firstWhere((f) => f.id == itemId);
        } catch (_) {
          target = festivals.first;
        }
      } else if (festivals.isNotEmpty) {
        target = festivals.first;
      }

      if (target != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FestivalDetailScreen(
              festival: target!,
              apiService: widget.apiService,
            ),
          ),
        );
      }
    } else if (type == 'special_day') {
      final now = DateTime.now();
      final specials = await widget.apiService.getSpecialDays(now.year, now.month);
      SpecialDay? target;
      if (itemId != null && specials.isNotEmpty) {
        try {
          target = specials.firstWhere((s) => s.id == itemId);
        } catch (_) {
          target = specials.first;
        }
      } else if (specials.isNotEmpty) {
        target = specials.first;
      }

      if (target != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpecialDayDetailScreen(
              specialDay: target!,
              apiService: widget.apiService,
            ),
          ),
        );
      }
    } else if (type == 'reminder') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RemindersScreen(apiService: widget.apiService),
        ),
      );
    } else if (type == 'panchangam') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PanchangamScreen(apiService: widget.apiService),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    return ListenableBuilder(
      listenable: _notificationService,
      builder: (context, _) {
        final allNotifs = _notificationService.notifications;
        final filteredNotifs = _getFilteredNotifications(allNotifs);
        final unreadCount = _notificationService.unreadCount;

        return Scaffold(
          backgroundColor: TNTColors.background,
          appBar: AppBar(
            backgroundColor: TNTColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Text(
                  translate('notifications'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textPrimary, fontSize: 16),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: TNTColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            actions: [ 
              // Mark all as read button
              if (unreadCount > 0) ...[
                TextButton(
                  onPressed: () => _notificationService.markAllAsRead(),
                  child: Text(
                    isTamil ? 'அனைத்தும் படித்தவை' : 'Mark all read',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TNTColors.primary,
                    ),
                  ),
                ),
              ],

              // Settings icon
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: TNTColors.textPrimary),
                tooltip: translate('notification_settings'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Column(
                children: [
                  // Filter Chips Bar
                  Container(
                    height: 48,
                    color: TNTColors.surface,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        _buildFilterChip(
                          label: isTamil ? 'அனைத்தும்' : 'All',
                          count: allNotifs.length,
                          selected: _selectedFilter == NotificationTabFilter.all,
                          onTap: () => setState(() => _selectedFilter = NotificationTabFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isTamil ? 'படிக்காதவை' : 'Unread',
                          count: unreadCount,
                          selected: _selectedFilter == NotificationTabFilter.unread,
                          onTap: () => setState(() => _selectedFilter = NotificationTabFilter.unread),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isTamil ? 'முகூர்த்தம் & பண்டிகை' : 'Muhurtham & Festivals',
                          selected: _selectedFilter == NotificationTabFilter.muhurthamFestival,
                          onTap: () => setState(() => _selectedFilter = NotificationTabFilter.muhurthamFestival),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isTamil ? 'நினைவூட்டல்கள்' : 'Reminders',
                          selected: _selectedFilter == NotificationTabFilter.reminders,
                          onTap: () => setState(() => _selectedFilter = NotificationTabFilter.reminders),
                        ),
                      ],
                    ),
                  ),
                  Container(color: TNTColors.border, height: 1),
                ],
              ),
            ),
          ),
          body: filteredNotifs.isEmpty
              ? _buildEmptyState(isTamil)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: filteredNotifs.length,
                  itemBuilder: (context, index) {
                    final item = filteredNotifs[index];
                    return NotificationCard(
                      item: item,
                      isTamil: isTamil,
                      onTap: () => _handleNotificationTap(item, isTamil),
                      onMarkRead: () => _notificationService.markAsRead(item.id),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? TNTColors.primary : TNTColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? TNTColors.primary : TNTColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : TNTColors.textSecondary,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.25) : TNTColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : TNTColors.textPrimary,
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: TNTColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTamil ? 'அறிவிப்புகள் ஏதுமில்லை' : 'No Notifications',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'சுப முகூர்த்தம், பண்டிகைகள் மற்றும் நினைவூட்டல் எச்சரிக்கைகள் இங்கு காண்பிக்கப்படும்.'
                  : 'Important Muhurtham, festival, and reminder alerts will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: Text(
                isTamil ? 'அறிவிப்பு அமைப்புகளை சரிபார்' : 'Check Notification Settings',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.surface,
                foregroundColor: TNTColors.primary,
                elevation: 0,
                side: const BorderSide(color: TNTColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
