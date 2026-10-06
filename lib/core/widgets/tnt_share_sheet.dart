import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../localization/tnt_localizations.dart';
import '../../services/share_service.dart';

/// Centralized Reusable TNT Share Sheet
/// Opens across Panchangam, Muhurtham, Festivals, and Special Days.
class TNTShareSheet extends StatelessWidget {
  final String title;
  final String content;

  const TNTShareSheet({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TNTShareSheet(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return Container(
      decoration: const BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TNTColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: TNTColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, size: 18, color: TNTColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: TNTColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TNTColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TNTColors.border),
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 12,
                  color: TNTColors.textPrimary,
                  height: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ShareService.copyToClipboard(context, content, isTamil);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(isTamil ? 'நகலெடு (Copy)' : 'Copy Text'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TNTColors.primaryDark,
                    side: const BorderSide(color: TNTColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ShareService.copyToClipboard(context, content, isTamil);
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(isTamil ? 'பகிர் (Share)' : 'Share Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
