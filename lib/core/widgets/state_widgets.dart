import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';

class TNTLoadingWidget extends StatelessWidget {
  final String? message;

  const TNTLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final loadingText = message ?? localizations?.translate('loading') ?? 'Loading...';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(TNTColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loadingText,
            style: const TextStyle(
              color: TNTColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class TNTErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const TNTErrorWidget({
    super.key,
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final errorText = message ?? localizations?.translate('error_loading') ?? 'An error occurred';
    final retryText = localizations?.translate('retry_btn') ?? 'Retry';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: TNTColors.inauspicious,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TNTColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(retryText),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: TNTColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TNTEmptyWidget extends StatelessWidget {
  final String? message;
  final IconData? icon;

  const TNTEmptyWidget({
    super.key,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final emptyText = message ?? localizations?.translate('no_data') ?? 'No data found';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.calendar_today_outlined,
              color: TNTColors.textMuted,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TNTColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
