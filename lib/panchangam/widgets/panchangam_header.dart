import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../widgets/tnt_brand_header.dart';

class PanchangamHeader extends StatelessWidget {
  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onRefreshTap;
  final bool isRefreshing;

  const PanchangamHeader({
    super.key,
    required this.location,
    required this.onLocationTap,
    required this.onRefreshTap,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;

    return Container(
      color: TNTColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title + Module Name
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: TNTColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translate('panchangam'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'TNT Tamil Almanac',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: TNTColors.textSecondary.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location badge & Refresh button
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: onLocationTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: TNTColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: TNTColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              translate(location.toLowerCase()),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down_rounded, size: 16, color: TNTColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              IconButton(
                icon: isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: TNTColors.primary),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20, color: TNTColors.primary),
                tooltip: translate('refresh'),
                onPressed: isRefreshing ? null : onRefreshTap,
              ),
              const SizedBox(width: 8),
              // removed TNTBrandHeader to fix overflow
            ],
          ),
        ),
        ],
      ),
    );
  }
}
