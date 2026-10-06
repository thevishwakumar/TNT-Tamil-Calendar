import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class MuhurthamShareSheet extends StatelessWidget {
  final MuhurthamDate muhurtham;

  const MuhurthamShareSheet({super.key, required this.muhurtham});

  String _generateShareText(bool isTamil) {
    final buffer = StringBuffer();
    if (isTamil) {
      buffer.writeln('🌟 *TNT சுப முகூர்த்த தகவல்* 🌟');
      buffer.writeln('------------------------------------');
      buffer.writeln('📅 ஆங்கில தேதி: ${muhurtham.date.day}/${muhurtham.date.month}/${muhurtham.date.year} (${muhurtham.dayOfWeekTa})');
      buffer.writeln('🗓️ தமிழ் தேதி: ${muhurtham.tamilDateStr} (${muhurtham.tamilMonth})');
      buffer.writeln('🏷️ சுப காரியம்: ${muhurtham.categoryTa}');
      buffer.writeln('⏰ சுப முகூர்த்த நேரம்: ${muhurtham.startTime} - ${muhurtham.endTime} (${muhurtham.duration})');
      buffer.writeln('⭐ நட்சத்திரம்: ${muhurtham.nakshatraTa}');
      buffer.writeln('🕉️ லக்னம் / ஹோரை: ${muhurtham.lagnamTa} / ${muhurtham.subhaHoraiTa}');
      buffer.writeln('🌔 பட்சம்: ${muhurtham.isValarthirai ? "வளர்பிறை" : "தேய்பிறை"}');
      buffer.writeln('⚠️ இராகு காலம்: ${muhurtham.rahuKalam}');
      buffer.writeln('📝 குறிப்பு: ${muhurtham.notesTa}');
      buffer.writeln('------------------------------------');
      buffer.writeln('📱 TNT தமிழ்நாடு நாட்காட்டி செயலி மூலம் பகிரப்பட்டது');
    } else {
      buffer.writeln('🌟 *TNT Auspicious Muhurtham* 🌟');
      buffer.writeln('------------------------------------');
      buffer.writeln('📅 Date: ${muhurtham.date.day}/${muhurtham.date.month}/${muhurtham.date.year} (${muhurtham.dayOfWeekEn})');
      buffer.writeln('🗓️ Tamil Date: ${muhurtham.tamilDateStr} (${muhurtham.tamilMonth})');
      buffer.writeln('🏷️ Occasion: ${muhurtham.category}');
      buffer.writeln('⏰ Muhurtham Window: ${muhurtham.startTime} - ${muhurtham.endTime} (${muhurtham.duration})');
      buffer.writeln('⭐ Nakshatra: ${muhurtham.nakshatra}');
      buffer.writeln('🕉️ Lagnam / Horai: ${muhurtham.lagnam} / ${muhurtham.subhaHorai}');
      buffer.writeln('🌔 Phase: ${muhurtham.isValarthirai ? "Valarpirai" : "Theipirai"}');
      buffer.writeln('⚠️ Rahu Kalam: ${muhurtham.rahuKalam}');
      buffer.writeln('📝 Note: ${muhurtham.notes}');
      buffer.writeln('------------------------------------');
      buffer.writeln('📱 Shared via TNT Tamil Calendar');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    final shareContent = _generateShareText(isTamil);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.share_rounded, color: TNTColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    localizations?.translate('share_muhurtham_title') ?? 'Share Auspicious Muhurtham',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TNTColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: TNTColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TNTColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TNTColors.border),
            ),
            child: SingleChildScrollView(
              child: Text(
                shareContent,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: TNTColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareContent));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations?.translate('copied_to_clipboard') ?? 'Copied to clipboard!',
                  ),
                  backgroundColor: TNTColors.primaryDark,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(
              isTamil ? 'அனைத்து விவரங்களையும் நகலெடு' : 'Copy All Details to Clipboard',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TNTColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
