import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../models/tnt_models.dart';

/// Centralized Reusable Share Service
/// Formats bilingual (Tamil + English) share cards and provides
/// standard copy-to-clipboard and share intent representation.
class ShareService {
  /// Format Panchangam for sharing
  static String formatPanchangam({
    required DateTime date,
    required CalendarDay? calendarDay,
    required PanchangamEntry? panchangam,
    required List<TimingEntry> timings,
    required bool isTamil,
    String? city,
  }) {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final tamilDate = calendarDay?.tamilDateStr ?? '';
    final tithi = isTamil ? (panchangam?.tithiTa ?? '') : (panchangam?.tithi ?? '');
    final nakshatra = isTamil ? (panchangam?.nakshatraTa ?? '') : (panchangam?.nakshatra ?? '');
    final yoga = isTamil ? (panchangam?.yogaTa ?? '') : (panchangam?.yoga ?? '');
    final sunrise = panchangam?.sunrise ?? '06:05 AM';
    final sunset = panchangam?.sunset ?? '06:12 PM';

    final nallaNeram = timings.firstWhere(
      (t) => t.category == 'nalla_neram' || t.name.toLowerCase().contains('nalla'),
      orElse: () => TimingEntry(name: 'Nalla Neram', nameTa: 'நல்ல நேரம்', startTime: '09:15 AM', endTime: '10:15 AM', isAuspicious: true),
    );
    final rahuKalam = timings.firstWhere(
      (t) => t.category == 'rahu_kalam' || t.name.toLowerCase().contains('rahu'),
      orElse: () => TimingEntry(name: 'Rahu Kalam', nameTa: 'இராகு காலம்', startTime: '07:30 AM', endTime: '09:00 AM', isAuspicious: false),
    );

    if (isTamil) {
      return '''
🕉️ TNT - தமிழ் நாள்காட்டி & பஞ்சாங்கம்
📍 ${city ?? 'தமிழ்நாடு'}

📅 தேதி: $dateStr
🗓️ தமிழ் தேதி: $tamilDate

✨ திதி: $tithi
⭐ நட்சத்திரம்: $nakshatra
🧘 யோகம்: $yoga
🌅 சூரியோதயம்: $sunrise | அஸ்தமனம்: $sunset

✅ நல்ல நேரம்: ${nallaNeram.startTime} - ${nallaNeram.endTime}
⚠️ இராகு காலம்: ${rahuKalam.startTime} - ${rahuKalam.endTime}

📱 TNT செயலியை பதிவிறக்கம் செய்து முழு பஞ்சாங்கத்தை அறியுங்கள்.
'''.trim();
    } else {
      return '''
🕉️ TNT Tamil Calendar
📍 ${city ?? 'Tamil Nadu'}

📅 Date: $dateStr
🗓️ Tamil Date: $tamilDate

✨ Tithi: $tithi
⭐ Nakshatra: $nakshatra
🧘 Yoga: $yoga
🌅 Sunrise: $sunrise | Sunset: $sunset

✅ Nalla Neram: ${nallaNeram.startTime} - ${nallaNeram.endTime}
⚠️ Rahu Kalam: ${rahuKalam.startTime} - ${rahuKalam.endTime}

📱 Download TNT app for complete daily Tamil Panchangam.
'''.trim();
    }
  }

  /// Format Muhurtham for sharing
  static String formatMuhurtham({
    required MuhurthamDate muhurtham,
    required bool isTamil,
  }) {
    final title = isTamil ? muhurtham.categoryTa : muhurtham.category;
    final dateStr = '${muhurtham.date.day}-${muhurtham.date.month}-${muhurtham.date.year}';
    final dayOfWeek = isTamil ? muhurtham.dayOfWeekTa : muhurtham.dayOfWeekEn;
    final star = isTamil ? muhurtham.nakshatraTa : muhurtham.nakshatra;
    final lagnam = isTamil ? muhurtham.lagnamTa : muhurtham.lagnam;
    final horai = isTamil ? muhurtham.subhaHoraiTa : muhurtham.subhaHorai;
    final purpose = isTamil ? muhurtham.suitablePurposeTa : muhurtham.suitablePurpose;
    final phase = isTamil 
        ? (muhurtham.isValarthirai ? 'வளர்பிறை' : 'தேய்பிறை') 
        : (muhurtham.isValarthirai ? 'Shukla Paksha (Valarpirai)' : 'Krishna Paksha (Theipirai)');

    if (isTamil) {
      return '''
💍 TNT - சுப முகூர்த்த நாள்
✨ $title

📅 ஆங்கில தேதி: $dateStr ($dayOfWeek)
🗓️ தமிழ் தேதி: ${muhurtham.tamilDateStr} (${muhurtham.tamilMonth})
🌓 பட்சம்: $phase

⏰ முகூர்த்த நேரம்: ${muhurtham.startTime} - ${muhurtham.endTime} (${muhurtham.duration})
⭐ நட்சத்திரம்: $star
🏛️ லக்னம்: $lagnam
🌟 சுப ஹோரை: $horai
🎯 உகந்த காரியம்: $purpose
⚠️ இராகு காலம்: ${muhurtham.rahuKalam}

📱 TNT தமிழ் நாள்காட்டி செயலி மூலம் பகிரப்பட்டது.
'''.trim();
    } else {
      return '''
💍 TNT - Auspicious Muhurtham Date
✨ $title

📅 Date: $dateStr ($dayOfWeek)
🗓️ Tamil Date: ${muhurtham.tamilDateStr} (${muhurtham.tamilMonth})
🌓 Phase: $phase

⏰ Muhurtham Window: ${muhurtham.startTime} - ${muhurtham.endTime} (${muhurtham.duration})
⭐ Nakshatra: $star
🏛️ Lagnam: $lagnam
🌟 Subha Horai: $horai
🎯 Suitable For: $purpose
⚠️ Rahu Kalam: ${muhurtham.rahuKalam}

📱 Shared via TNT Tamil Calendar.
'''.trim();
    }
  }

  /// Format Special Day for sharing
  static String formatSpecialDay({
    required SpecialDay specialDay,
    required bool isTamil,
  }) {
    final title = isTamil ? specialDay.titleTa : specialDay.title;
    final dateStr = '${specialDay.date.day}-${specialDay.date.month}-${specialDay.date.year}';
    final desc = isTamil ? specialDay.descriptionTa : specialDay.description;
    final rituals = isTamil ? specialDay.ritualsTa : specialDay.rituals;
    final deity = isTamil ? specialDay.deityTa : specialDay.deity;

    if (isTamil) {
      return '''
📌 TNT - சிறப்பு நாள்
🛕 $title

📅 தேதி: $dateStr
🗓️ தமிழ் தேதி: ${specialDay.tamilDateStr}
🙏 வழிபடும் தெய்வம்: $deity

📖 சிறப்புகள்:
$desc
${rituals.isNotEmpty ? '\n🕊️ விரத வழிபாட்டு முறைகள்:\n$rituals' : ''}

📱 TNT தமிழ் நாள்காட்டி செயலி மூலம் பகிரப்பட்டது.
'''.trim();
    } else {
      return '''
📌 TNT - Special Auspicious Day
🛕 $title

📅 Date: $dateStr
🗓️ Tamil Date: ${specialDay.tamilDateStr}
🙏 Deity: $deity

📖 Significance:
$desc
${rituals.isNotEmpty ? '\n🕊️ Rituals & Observance:\n$rituals' : ''}

📱 Shared via TNT Tamil Calendar.
'''.trim();
    }
  }

  /// Format Festival for sharing
  static String formatFestival({
    required Festival festival,
    required bool isTamil,
  }) {
    final name = isTamil ? festival.nameTa : festival.name;
    final dateStr = '${festival.date.day}-${festival.date.month}-${festival.date.year}';
    final desc = isTamil ? festival.descriptionTa : festival.description;
    final rituals = isTamil ? festival.ritualsTa : festival.rituals;
    final holidayBadge = festival.isHoliday ? (isTamil ? '🎉 அரசு பொது விடுமுறை' : '🎉 Government Public Holiday') : '';

    if (isTamil) {
      return '''
🛕 TNT - புனிதத் திருவிழா
✨ $name $holidayBadge

📅 தேதி: $dateStr
🗓️ தமிழ் தேதி: ${festival.tamilDateStr}

📖 திருவிழா சிறப்பு:
$desc
${rituals.isNotEmpty ? '\n🕊️ பண்டிகை கொண்டாட்டங்கள்:\n$rituals' : ''}

📱 TNT தமிழ் நாள்காட்டி செயலி மூலம் பகிரப்பட்டது.
'''.trim();
    } else {
      return '''
🛕 TNT - Auspicious Festival
✨ $name $holidayBadge

📅 Date: $dateStr
🗓️ Tamil Date: ${festival.tamilDateStr}

📖 Festival Details:
$desc
${rituals.isNotEmpty ? '\n🕊️ Observance & Rituals:\n$rituals' : ''}

📱 Shared via TNT Tamil Calendar.
'''.trim();
    }
  }

  /// Copy text to clipboard and show snackbar
  static Future<void> copyToClipboard(BuildContext context, String text, bool isTamil) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: TNTColors.primary,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                isTamil ? 'விவரங்கள் நகலெடுக்கப்பட்டது!' : 'Details copied to clipboard!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
  }
}
