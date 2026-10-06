
/// Represents a Tamil Rasi (Zodiac Sign)
class RasiItem {
  final String id;
  final String nameEn;
  final String nameTa;
  final String symbol;
  final String lordEn;
  final String lordTa;
  final String elementEn;
  final String elementTa;
  final List<NakshatraItem> nakshatras;

  const RasiItem({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.symbol,
    required this.lordEn,
    required this.lordTa,
    required this.elementEn,
    required this.elementTa,
    required this.nakshatras,
  });
}

/// Represents a Nakshatra (Lunar Mansion / Star)
class NakshatraItem {
  final String id;
  final String nameEn;
  final String nameTa;
  final List<int> padas;
  final String lordEn;
  final String lordTa;

  const NakshatraItem({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.padas,
    required this.lordEn,
    required this.lordTa,
  });
}

/// Represents a Daily Horoscope reading generated for a specific Rasi and Nakshatra
class DailyHoroscopeReading {
  final String rasiId;
  final String rasiNameTa;
  final String rasiNameEn;
  final String nakshatraId;
  final String nakshatraNameTa;
  final String nakshatraNameEn;
  final int pada;
  final DateTime date;
  final String tamilDateText;
  final double score; // 0.0 - 5.0
  final int luckyPercentage; // e.g. 88%
  final String moodTa;
  final String moodEn;
  final String generalPredictionTa;
  final String generalPredictionEn;
  final String careerPredictionTa;
  final String careerPredictionEn;
  final String financePredictionTa;
  final String financePredictionEn;
  final String familyPredictionTa;
  final String familyPredictionEn;
  final String healthPredictionTa;
  final String healthPredictionEn;
  final int luckyNumber;
  final String luckyColorTa;
  final String luckyColorEn;
  final String luckyDirectionTa;
  final String luckyDirectionEn;
  final String luckyTimeTa;
  final String luckyTimeEn;
  final String pariharamDeityTa;
  final String pariharamDeityEn;
  final String pariharamRemedyTa;
  final String pariharamRemedyEn;
  final String mantraTa;
  final String mantraEn;

  const DailyHoroscopeReading({
    required this.rasiId,
    required this.rasiNameTa,
    required this.rasiNameEn,
    required this.nakshatraId,
    required this.nakshatraNameTa,
    required this.nakshatraNameEn,
    required this.pada,
    required this.date,
    required this.tamilDateText,
    required this.score,
    required this.luckyPercentage,
    required this.moodTa,
    required this.moodEn,
    required this.generalPredictionTa,
    required this.generalPredictionEn,
    required this.careerPredictionTa,
    required this.careerPredictionEn,
    required this.financePredictionTa,
    required this.financePredictionEn,
    required this.familyPredictionTa,
    required this.familyPredictionEn,
    required this.healthPredictionTa,
    required this.healthPredictionEn,
    required this.luckyNumber,
    required this.luckyColorTa,
    required this.luckyColorEn,
    required this.luckyDirectionTa,
    required this.luckyDirectionEn,
    required this.luckyTimeTa,
    required this.luckyTimeEn,
    required this.pariharamDeityTa,
    required this.pariharamDeityEn,
    required this.pariharamRemedyTa,
    required this.pariharamRemedyEn,
    required this.mantraTa,
    required this.mantraEn,
  });
}
