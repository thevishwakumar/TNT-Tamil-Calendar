import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Content Preview Modal
/// Renders the exact user-facing visual card in Tamil and English preview modes.
class AdminContentPreviewDialog extends StatefulWidget {
  final ContentItem item;

  const AdminContentPreviewDialog({super.key, required this.item});

  @override
  _AdminContentPreviewDialogState createState() => _AdminContentPreviewDialogState();
}

class _AdminContentPreviewDialogState extends State<AdminContentPreviewDialog> {
  String _previewLang = 'ta'; // 'ta' | 'en'

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final title = item.localizedTitle(_previewLang);
    final desc = item.localizedDescription(_previewLang) ?? '';

    return Dialog(
      backgroundColor: TNTColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header with Language Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.remove_red_eye_rounded, size: 20, color: TNTColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Live User Preview',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                    ),
                  ],
                ),
                AdminLanguageTabs(
                  currentLang: _previewLang,
                  onLanguageChanged: (lang) => setState(() => _previewLang = lang),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note indicating this is a preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Simulated view. Status: ${item.status}. Not yet visible to users if DRAFT.',
                      style: TextStyle(fontSize: 11, color: Colors.brown[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mock User-facing Card
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: TNTColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Media Banner if present
                  if (item.mediaList.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        item.mediaList.first.mediaUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: TNTColors.background,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined, size: 40, color: TNTColors.textMuted),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TNTColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: TNTColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              item.publishAt != null
                                  ? '${item.publishAt!.day}/${item.publishAt!.month}/${item.publishAt!.year}'
                                  : 'Draft',
                              style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title.isNotEmpty ? title : 'Untitled Content',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.textPrimary,
                          ),
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dialog Close
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TNTColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close Preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
