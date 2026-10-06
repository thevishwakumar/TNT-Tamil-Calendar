import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../localization/tnt_localizations.dart';

class TNTErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final String? overrideMessage;
  final String? overrideMessageTa;

  const TNTErrorOverlay({
    Key? key,
    required this.onRetry,
    this.overrideMessage,
    this.overrideMessageTa,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    
    final defaultMsg = isTamil 
        ? 'தகவலை ஏற்றுவதில் சிக்கல் ஏற்பட்டது.' 
        : 'Unable to load the information.';
    
    final message = isTamil 
        ? (overrideMessageTa ?? defaultMsg) 
        : (overrideMessage ?? defaultMsg);
        
    final retryText = isTamil ? 'மீண்டும் முயற்சி' : 'Retry';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TNTColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: TNTColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(retryText),
            ),
          ],
        ),
      ),
    );
  }
}
