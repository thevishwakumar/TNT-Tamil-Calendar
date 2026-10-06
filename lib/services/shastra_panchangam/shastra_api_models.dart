class ShastraFestival {
  final String id;
  final String nameEn;
  final String? rule;
  final List<String> dates;
  final Map<String, List<String>> localDates;

  ShastraFestival({
    required this.id,
    required this.nameEn,
    this.rule,
    required this.dates,
    required this.localDates,
  });

  factory ShastraFestival.fromJson(String id, Map<String, dynamic> json) {
    return ShastraFestival(
      id: id,
      nameEn: json['en'] as String? ?? id,
      rule: json['rule'] as String?,
      dates: (json['dates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      localDates: (json['local_dates'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e.toString()).toList()),
      ) ?? {},
    );
  }
}

class ShastraDayData {
  final String date;
  final int? sunrise;
  final int? sunset;
  final int? tithi;
  final int? tithiEnds;
  final int? nakshatra;
  final int? nakshatraEnds;
  final int? yoga;
  final int? yogaEnds;
  final int? karana;
  final int? karanaEnds;
  final int? rahuKalam;
  final int? yamagandam;
  final int? gulikai;
  final int? moonrise;
  final int? moonset;
  final String? tithiName;
  final String? paksha;
  final String? nakshatraName;
  final String? yogaName;
  final String? karanaName;

  ShastraDayData({
    required this.date,
    this.sunrise,
    this.sunset,
    this.tithi,
    this.tithiEnds,
    this.nakshatra,
    this.nakshatraEnds,
    this.yoga,
    this.yogaEnds,
    this.karana,
    this.karanaEnds,
    this.rahuKalam,
    this.yamagandam,
    this.gulikai,
    this.moonrise,
    this.moonset,
    this.tithiName,
    this.paksha,
    this.nakshatraName,
    this.yogaName,
    this.karanaName,
  });

  factory ShastraDayData.fromJson(Map<String, dynamic> json) {
    return ShastraDayData(
      date: json['date'] as String,
      sunrise: json['sunrise'] as int?,
      sunset: json['sunset'] as int?,
      tithi: json['tithi'] as int?,
      tithiEnds: json['tithi_ends'] as int?,
      nakshatra: json['nakshatra'] as int?,
      nakshatraEnds: json['nakshatra_ends'] as int?,
      yoga: json['yoga'] as int?,
      yogaEnds: json['yoga_ends'] as int?,
      karana: json['karana'] as int?,
      karanaEnds: json['karana_ends'] as int?,
      rahuKalam: json['rahu_kalam'] as int?,
      yamagandam: json['yamagandam'] as int?,
      gulikai: json['gulikai'] as int?,
      moonrise: json['moonrise'] as int?,
      moonset: json['moonset'] as int?,
      tithiName: json['tithi_name'] as String?,
      paksha: json['paksha'] as String?,
      nakshatraName: json['nakshatra_name'] as String?,
      yogaName: json['yoga_name'] as String?,
      karanaName: json['karana_name'] as String?,
    );
  }
}
