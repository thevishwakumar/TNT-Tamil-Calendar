import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Clean Onboarding / Settings Notification Permission Dialog
/// Explicitly explains why notifications are useful before triggering system permission:
/// Tamil: அறிவிப்புகளை இயக்கினால் முக்கியமான முகூர்த்தம், திருவிழா மற்றும் நினைவூட்டல்களை சரியான நேரத்தில் பெறலாம்.
/// English: Enable notifications to receive timely Muhurtham, festival and reminder alerts.
/// Respects user decisions and never blocks core application functionality.
class NotificationPermissionDialog extends StatelessWidget {
  final bool isTamil;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const NotificationPermissionDialog({
    super.key,
    required this.isTamil,
    required this.onAllow,
    required this.onDeny,
  });

  static Future<bool?> show(BuildContext context, {required bool isTamil}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NotificationPermissionDialog(
        isTamil: isTamil,
        onAllow: () => Navigator.of(ctx).pop(true),
        onDeny: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TNTColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gentle Saffron icon banner
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: TNTColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: TNTColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            isTamil ? 'அறிவிப்புகளை இயக்குங்கள்' : 'Stay Informed with TNT',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TNTColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Core localized explanation copy
          Text(
            isTamil
                ? 'அறிவிப்புகளை இயக்கினால் முக்கியமான முகூர்த்தம், திருவிழா மற்றும் நினைவூட்டல்களை சரியான நேரத்தில் பெறலாம்.'
                : 'Enable notifications to receive timely Muhurtham, festival and reminder alerts.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: TNTColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Value highlights
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TNTColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TNTColors.border),
            ),
            child: Column(
              children: [
                _buildBenefitRow(
                  Icons.favorite_rounded,
                  TNTColors.primary,
                  isTamil ? 'சுப முகூர்த்த எச்சரிக்கைகள்' : 'Muhurtham Timing Alerts',
                ),
                const SizedBox(height: 8),
                _buildBenefitRow(
                  Icons.festival_rounded,
                  TNTColors.accent,
                  isTamil ? 'முக்கிய பண்டிகை நினைவூட்டல்' : 'Important Festival Reminders',
                ),
                const SizedBox(height: 8),
                _buildBenefitRow(
                  Icons.auto_awesome_rounded,
                  TNTColors.auspicious,
                  isTamil ? 'அமாவாசை, பௌர்ணமி மற்றும் விரத நாட்கள்' : 'Amavasai, Pournami & Vrat Days',
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            // "Not Now" button
            Expanded(
              child: TextButton(
                onPressed: onDeny,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isTamil ? 'இப்போது வேண்டாம்' : 'Not Now',
                  style: const TextStyle(
                    color: TNTColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // "Allow" button
            Expanded(
              child: ElevatedButton(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TNTColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isTamil ? 'அனுமதி' : 'Allow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TNTColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
