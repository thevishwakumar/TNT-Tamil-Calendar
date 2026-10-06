import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/tnt_models.dart';

/// Admin Notification Preview Dialog
/// Displays a realistic mobile push banner in Tamil and English before sending
class AdminNotificationPreviewDialog extends StatefulWidget {
  final NotificationCampaign campaign;

  const AdminNotificationPreviewDialog({super.key, required this.campaign});

  @override
  _AdminNotificationPreviewDialogState createState() => _AdminNotificationPreviewDialogState();
}

class _AdminNotificationPreviewDialogState extends State<AdminNotificationPreviewDialog> {
  int _selectedLangIndex = 0; // 0: Tamil, 1: English

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final isTamil = _selectedLangIndex == 0;
    final title = isTamil
        ? (c.titleTamil.isNotEmpty ? c.titleTamil : c.title)
        : (c.titleEnglish.isNotEmpty ? c.titleEnglish : c.title);
    final body = isTamil
        ? (c.messageTamil.isNotEmpty ? c.messageTamil : c.body)
        : (c.messageEnglish.isNotEmpty ? c.messageEnglish : c.body);

    return Dialog(
      backgroundColor: TNTColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.preview_rounded, color: TNTColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Push Notification Preview',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                          ),
                          Text(
                            'Exact user-device appearance simulation',
                            style: TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: TNTColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language Selector Tabs
              Container(
                decoration: BoxDecoration(
                  color: TNTColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TNTColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedLangIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedLangIndex == 0 ? TNTColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'தமிழ் முன்னோட்டம் (Tamil)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedLangIndex == 0 ? Colors.white : TNTColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedLangIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedLangIndex == 1 ? TNTColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'English Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedLangIndex == 1 ? Colors.white : TNTColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Realistic Phone Notification Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E4E8)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: TNTColors.primary,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'TNT',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'TNT Tamil Calendar',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C2D30)),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Colors.black26, fontSize: 10)),
                            const SizedBox(width: 6),
                            const Text(
                              'now',
                              style: TextStyle(fontSize: 11, color: Color(0xFF7A7E85)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TNTColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.category.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: TNTColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Notification Title
                    Text(
                      title.isNotEmpty ? title : 'Untitled Notification',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1711),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Notification Body
                    Text(
                      body.isNotEmpty ? body : 'No message content provided.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A4E57),
                        height: 1.35,
                      ),
                    ),

                    // Rich Media Image Preview if attached
                    if (c.mediaReference != null && c.mediaReference!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.black12,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                c.mediaReference!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported_rounded, color: TNTColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (c.deepLink != null && c.deepLink!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 14, color: TNTColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Action: ${c.deepLink}',
                              style: const TextStyle(fontSize: 11, color: TNTColors.primary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Targeting Details Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TNTColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TNTColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 16, color: TNTColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target Audience: ${_getAudienceLabel(c.audienceType)}',
                        style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (c.category.toUpperCase() == 'MARKETING')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Marketing Consent Required',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAudienceLabel(String audienceType) {
    switch (audienceType) {
      case 'opt_in_marketing':
        return 'Marketing Consent Opt-Ins Only';
      case 'active_users':
        return 'Active Users (Last 30 Days)';
      case 'category_subscribers':
        return 'Subscribers of this Category';
      case 'all_eligible':
      default:
        return 'All Eligible Users';
    }
  }
}
