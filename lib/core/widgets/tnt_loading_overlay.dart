import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../localization/tnt_localizations.dart';

class TNTLoadingOverlay extends StatelessWidget {
  const TNTLoadingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    
    final loadingText = isTamil 
        ? 'டிஎன்டி தமிழ் காலண்டர் ஏற்றப்படுகிறது...' 
        : 'Loading TNT Tamil Calendar...';

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
            const CircularProgressIndicator(color: TNTColors.primary),
            const SizedBox(height: 16),
            Text(
              loadingText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TNTColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
