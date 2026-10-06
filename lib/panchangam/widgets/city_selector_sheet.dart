import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../repositories/panchangam_repository.dart';

class CitySelectorSheet extends StatelessWidget {
  final String selectedCity;
  final Function(String) onCitySelected;

  const CitySelectorSheet({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    return Container(
      decoration: const BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TNTColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                translate('select_location'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TNTColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: TNTColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isTamil
                ? 'உங்கள் இருப்பிடத்திற்கு ஏற்ப துல்லியமான பஞ்சாங்கக் கணக்கீடு'
                : 'Accurate astronomical calculations calculated for your city coordinates',
            style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: LocationRepository.availableCities.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: TNTColors.border),
              itemBuilder: (context, index) {
                final city = LocationRepository.availableCities[index];
                final isSelected = city.toLowerCase() == selectedCity.toLowerCase();
                final cityLocalKey = city.toLowerCase();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  leading: Icon(
                    Icons.location_city_rounded,
                    color: isSelected ? TNTColors.primary : TNTColors.textSecondary,
                  ),
                  title: Text(
                    translate(cityLocalKey),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? TNTColors.primary : TNTColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    isTamil ? 'தமிழ்நாடு, இந்தியா' : 'Tamil Nadu, India',
                    style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: TNTColors.primary)
                      : null,
                  onTap: () {
                    onCitySelected(city);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
