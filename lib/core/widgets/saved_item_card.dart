import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

/// Reusable SavedItemCard for displaying any bookmarked content
/// Supports Panchangam, Muhurtham, Special Days, and Festivals.
class SavedItemCard extends StatelessWidget {
  final SavedItem item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const SavedItemCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    final typeBadge = _getTypeBadge(item.typeEnum, isTamil);
    final displayTitle = isTamil 
        ? (item.titleTa.isNotEmpty ? item.titleTa : item.title)
        : (item.title.isNotEmpty ? item.title : item.titleTa);
    final displaySubtitle = isTamil 
        ? (item.subtitleTa.isNotEmpty ? item.subtitleTa : item.subtitle)
        : (item.subtitle.isNotEmpty ? item.subtitle : item.subtitleTa);

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
          // Top Header: Type Tag & Saved Timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: typeBadge.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                bottom: BorderSide(color: typeBadge.borderColor, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(typeBadge.icon, size: 14, color: typeBadge.textColor),
                    const SizedBox(width: 6),
                    Text(
                      typeBadge.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: typeBadge.textColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatSavedDate(item.savedAt, isTamil),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: typeBadge.textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Main Content: Tappable to open detail
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Box
                  if (item.date != null) ...[
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
                            '${item.date!.day}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: TNTColors.primaryDark,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getMonthAbbr(item.date!.month, isTamil),
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
                  ],

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.tamilDateStr.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.tamilDateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: TNTColors.primaryDark,
                            ),
                          ),
                        ],
                        if (displaySubtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            displaySubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TNTColors.textSecondary,
                              height: 1.3,
                            ),
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

          // Action Buttons: Open & Remove
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: TNTColors.border, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.bookmark_remove_outlined, size: 16, color: Colors.redAccent),
                  label: Text(
                    isTamil ? 'நீக்கு' : 'Remove',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: Text(
                    isTamil ? 'விவரம் காண்க' : 'Open Details',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TypeBadgeInfo _getTypeBadge(SavedItemType type, bool isTamil) {
    switch (type) {
      case SavedItemType.panchangam:
        return _TypeBadgeInfo(
          label: isTamil ? 'பஞ்சாங்கம்' : 'Panchangam',
          icon: Icons.shield_moon_outlined,
          textColor: const Color(0xFF6A1B9A),
          backgroundColor: const Color(0xFFF3E5F5),
          borderColor: const Color(0xFFE1BEE7),
        );
      case SavedItemType.muhurtham:
        return _TypeBadgeInfo(
          label: isTamil ? 'சுப முகூர்த்தம்' : 'Muhurtham',
          icon: Icons.favorite_rounded,
          textColor: const Color(0xFFC2185B),
          backgroundColor: const Color(0xFFFCE4EC),
          borderColor: const Color(0xFFF8BBD0),
        );
      case SavedItemType.specialDay:
        return _TypeBadgeInfo(
          label: isTamil ? 'சிறப்பு நாள்' : 'Special Day',
          icon: Icons.star_rounded,
          textColor: const Color(0xFFE65100),
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFFFE0B2),
        );
      case SavedItemType.festival:
        return _TypeBadgeInfo(
          label: isTamil ? 'புனிதத் திருவிழா' : 'Festival',
          icon: Icons.festival_rounded,
          textColor: const Color(0xFF1565C0),
          backgroundColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFFBBDEFB),
        );
      case SavedItemType.all:
        return _TypeBadgeInfo(
          label: isTamil ? 'சேமிப்பு' : 'Saved Item',
          icon: Icons.bookmark_rounded,
          textColor: TNTColors.primaryDark,
          backgroundColor: TNTColors.primary.withValues(alpha: 0.08),
          borderColor: TNTColors.primary.withValues(alpha: 0.2),
        );
    }
  }

  String _formatSavedDate(DateTime dt, bool isTamil) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return isTamil ? 'இன்று சேமிக்கப்பட்டது' : 'Saved Today';
    } else if (diff.inDays == 1) {
      return isTamil ? 'நேற்று சேமிக்கப்பட்டது' : 'Saved Yesterday';
    } else {
      return isTamil ? '${dt.day}/${dt.month}/${dt.year}' : '${dt.month}/${dt.day}/${dt.year}';
    }
  }

  String _getMonthAbbr(int month, bool isTamil) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const ta = ['தை', 'மாசி', 'பங்கு', 'சித்', 'வைகா', 'ஆனி', 'ஆடி', 'ஆவ', 'புரட்', 'ஐப்', 'கார்த்தி', 'மார்க'];
    return isTamil ? ta[(month - 1) % 12] : en[(month - 1) % 12];
  }
}

class _TypeBadgeInfo {
  final String label;
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  _TypeBadgeInfo({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
