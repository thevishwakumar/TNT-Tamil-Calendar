import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/tnt_models.dart';

/// Accessible Notification Card
/// Renders notification item with distinct unread state (accessible border, dot indicator, and text tag),
/// category icon, localized copy, timestamp, and interactive tap handler.
class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final bool isTamil;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  const NotificationCard({
    super.key,
    required this.item,
    required this.isTamil,
    required this.onTap,
    this.onMarkRead,
  });

  IconData _getCategoryIcon() {
    switch (item.notificationType) {
      case 'muhurtham':
        return Icons.favorite_rounded;
      case 'festival':
        return Icons.festival_rounded;
      case 'special_day':
        return Icons.auto_awesome_rounded;
      case 'panchangam':
        return Icons.shield_moon_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'important_update':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getCategoryColor() {
    switch (item.notificationType) {
      case 'muhurtham':
        return TNTColors.primary;
      case 'festival':
        return TNTColors.accent;
      case 'special_day':
        return TNTColors.auspicious;
      case 'panchangam':
        return const Color(0xFF1E3A8A);
      case 'reminder':
        return const Color(0xFFD97706);
      case 'marketing':
        return const Color(0xFF7C3AED);
      case 'important_update':
      default:
        return TNTColors.primary;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes.clamp(1, 60);
      return isTamil ? '$mins நிமிடங்களுக்கு முன்' : '${mins}m ago';
    } else if (diff.inHours < 24) {
      final hrs = diff.inHours;
      return isTamil ? '$hrs மணி நேரத்திற்கு முன்' : '${hrs}h ago';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return isTamil ? '$days நாட்களுக்கு முன்' : '${days}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = item.localizedTitle(isTamil);
    final body = item.localizedBody(isTamil);
    final catColor = _getCategoryColor();
    final catIcon = _getCategoryIcon();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: item.isRead ? TNTColors.surface : TNTColors.surface,
        borderRadius: BorderRadius.circular(12),
        // Accessible unread distinction: Thick colored left border + elevated shadow for unread
        border: Border(
          left: BorderSide(
            color: item.isRead ? Colors.transparent : TNTColors.primary,
            width: item.isRead ? 0 : 4,
          ),
          top: BorderSide(color: item.isRead ? TNTColors.border : TNTColors.primary.withValues(alpha: 0.3), width: 1),
          right: BorderSide(color: item.isRead ? TNTColors.border : TNTColors.primary.withValues(alpha: 0.3), width: 1),
          bottom: BorderSide(color: item.isRead ? TNTColors.border : TNTColors.primary.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: item.isRead
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))]
            : [
                BoxShadow(
                  color: TNTColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: item.isRead ? 0.08 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title & Unread indicator
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: TNTColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Unread Accessible Badge (not color-only: uses text tag + dot)
                          if (!item.isRead) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: TNTColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: TNTColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTamil ? 'புதியது' : 'NEW',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: TNTColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Body Message
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: item.isRead ? FontWeight.normal : FontWeight.w500,
                          color: item.isRead ? TNTColors.textSecondary : TNTColors.textPrimary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Footer Row: Timestamp & Deep link action affordance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 11, color: TNTColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimestamp(item.sentAt),
                                style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
                              ),
                            ],
                          ),
                          if (item.relatedItemType != null && item.relatedItemId != null) ...[
                            Row(
                              children: [
                                Text(
                                  isTamil ? 'விவரம் காண்க' : 'View Details',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: TNTColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded, size: 14, color: TNTColors.primary),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
