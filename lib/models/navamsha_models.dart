/// Strongly-typed models for Navamsha Panchang API responses & astronomical computations
library;

class NavamshaTithi {
  final String nameEn;
  final String nameTa;
  final int number; // 1 to 30
  final String paksha; // 'Shukla' | 'Krishna'
  final String pakshaTa; // 'வளர்பிறை' | 'தேய்பிறை'
  final String endTime;

  const NavamshaTithi({
    required this.nameEn,
    required this.nameTa,
    required this.number,
    required this.paksha,
    required this.pakshaTa,
    required this.endTime,
  });

  factory NavamshaTithi.fromJson(Map<String, dynamic> json) {
    return NavamshaTithi(
      nameEn: json['nameEn'] as String? ?? 'Ekadashi',
      nameTa: json['nameTa'] as String? ?? 'ஏகாதசி',
      number: json['number'] as int? ?? 11,
      paksha: json['paksha'] as String? ?? 'Shukla',
      pakshaTa: json['pakshaTa'] as String? ?? 'வளர்பிறை',
      endTime: json['endTime'] as String? ?? '04:30 PM',
    );
  }

  Map<String, dynamic> toJson() => {
    'nameEn': nameEn,
    'nameTa': nameTa,
    'number': number,
    'paksha': paksha,
    'pakshaTa': pakshaTa,
    'endTime': endTime,
  };
}

class NavamshaNakshatra {
  final String nameEn;
  final String nameTa;
  final int number; // 1 to 27
  final int pada; // 1 to 4
  final String endTime;

  const NavamshaNakshatra({
    required this.nameEn,
    required this.nameTa,
    required this.number,
    required this.pada,
    required this.endTime,
  });

  factory NavamshaNakshatra.fromJson(Map<String, dynamic> json) {
    return NavamshaNakshatra(
      nameEn: json['nameEn'] as String? ?? 'Shravana',
      nameTa: json['nameTa'] as String? ?? 'திருவோணம்',
      number: json['number'] as int? ?? 22,
      pada: json['pada'] as int? ?? 2,
      endTime: json['endTime'] as String? ?? '07:15 PM',
    );
  }

  Map<String, dynamic> toJson() => {
    'nameEn': nameEn,
    'nameTa': nameTa,
    'number': number,
    'pada': pada,
    'endTime': endTime,
  };
}

class NavamshaSunTimes {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;

  const NavamshaSunTimes({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
  });

  factory NavamshaSunTimes.fromJson(Map<String, dynamic> json) {
    return NavamshaSunTimes(
      sunrise: json['sunrise'] as String? ?? '06:08 AM',
      sunset: json['sunset'] as String? ?? '06:12 PM',
      moonrise: json['moonrise'] as String? ?? '03:45 PM',
      moonset: json['moonset'] as String? ?? '04:10 AM',
    );
  }

  Map<String, dynamic> toJson() => {
    'sunrise': sunrise,
    'sunset': sunset,
    'moonrise': moonrise,
    'moonset': moonset,
  };
}

class NavamshaInauspicious {
  final String rahuKaal;
  final String gulikaKaal;
  final String yamagandam;

  const NavamshaInauspicious({
    required this.rahuKaal,
    required this.gulikaKaal,
    required this.yamagandam,
  });

  factory NavamshaInauspicious.fromJson(Map<String, dynamic> json) {
    return NavamshaInauspicious(
      rahuKaal: json['rahuKaal'] as String? ?? '01:30 PM - 03:00 PM',
      gulikaKaal: json['gulikaKaal'] as String? ?? '09:00 AM - 10:30 AM',
      yamagandam: json['yamagandam'] as String? ?? '06:00 AM - 07:30 AM',
    );
  }

  Map<String, dynamic> toJson() => {
    'rahuKaal': rahuKaal,
    'gulikaKaal': gulikaKaal,
    'yamagandam': yamagandam,
  };
}

class NavamshaAuspicious {
  final String abhijitMuhurat;
  final String brahmaMuhurta;
  final String amritKaal;
  final String nallaNeramMorning;
  final String nallaNeramEvening;

  const NavamshaAuspicious({
    required this.abhijitMuhurat,
    required this.brahmaMuhurta,
    required this.amritKaal,
    required this.nallaNeramMorning,
    required this.nallaNeramEvening,
  });

  factory NavamshaAuspicious.fromJson(Map<String, dynamic> json) {
    return NavamshaAuspicious(
      abhijitMuhurat: json['abhijitMuhurat'] as String? ?? '11:48 AM - 12:36 PM',
      brahmaMuhurta: json['brahmaMuhurta'] as String? ?? '04:32 AM - 05:20 AM',
      amritKaal: json['amritKaal'] as String? ?? '08:15 AM - 09:45 AM',
      nallaNeramMorning: json['nallaNeramMorning'] as String? ?? '09:15 AM - 10:15 AM',
      nallaNeramEvening: json['nallaNeramEvening'] as String? ?? '04:45 PM - 05:45 PM',
    );
  }

  Map<String, dynamic> toJson() => {
    'abhijitMuhurat': abhijitMuhurat,
    'brahmaMuhurta': brahmaMuhurta,
    'amritKaal': amritKaal,
    'nallaNeramMorning': nallaNeramMorning,
    'nallaNeramEvening': nallaNeramEvening,
  };
}

class NavamshaObservances {
  final bool isPournami;
  final bool isAmavasai;
  final bool isEkadashi;
  final bool isSashti;
  final bool isKrithigai;
  final bool isChaturthi;
  final bool isPradosham;

  const NavamshaObservances({
    required this.isPournami,
    required this.isAmavasai,
    required this.isEkadashi,
    required this.isSashti,
    required this.isKrithigai,
    required this.isChaturthi,
    required this.isPradosham,
  });

  factory NavamshaObservances.fromJson(Map<String, dynamic> json) {
    return NavamshaObservances(
      isPournami: json['isPournami'] as bool? ?? false,
      isAmavasai: json['isAmavasai'] as bool? ?? false,
      isEkadashi: json['isEkadashi'] as bool? ?? false,
      isSashti: json['isSashti'] as bool? ?? false,
      isKrithigai: json['isKrithigai'] as bool? ?? false,
      isChaturthi: json['isChaturthi'] as bool? ?? false,
      isPradosham: json['isPradosham'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'isPournami': isPournami,
    'isAmavasai': isAmavasai,
    'isEkadashi': isEkadashi,
    'isSashti': isSashti,
    'isKrithigai': isKrithigai,
    'isChaturthi': isChaturthi,
    'isPradosham': isPradosham,
  };
}

class NavamshaPanchangBundle {
  final String date; // YYYY-MM-DD
  final double latitude;
  final double longitude;
  final double timezone;
  final NavamshaTithi tithi;
  final NavamshaNakshatra nakshatra;
  final String yogaEn;
  final String yogaTa;
  final String karanaEn;
  final String karanaTa;
  final String varaEn;
  final String varaTa;
  final NavamshaSunTimes sunTimes;
  final NavamshaInauspicious inauspicious;
  final NavamshaAuspicious auspicious;
  final NavamshaObservances observances;
  final Map<String, dynamic> rawNavamshaData;
  final String sourceProvider;
  final DateTime fetchedAt;

  const NavamshaPanchangBundle({
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.tithi,
    required this.nakshatra,
    required this.yogaEn,
    required this.yogaTa,
    required this.karanaEn,
    required this.karanaTa,
    required this.varaEn,
    required this.varaTa,
    required this.sunTimes,
    required this.inauspicious,
    required this.auspicious,
    required this.observances,
    required this.rawNavamshaData,
    required this.sourceProvider,
    required this.fetchedAt,
  });

  factory NavamshaPanchangBundle.fromJson(Map<String, dynamic> json) {
    final astro = json['astronomical'] as Map<String, dynamic>? ?? json;
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final meta = astro['metadata'] as Map<String, dynamic>? ?? {};

    return NavamshaPanchangBundle(
      date: json['date'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
      latitude: (loc['latitude'] as num?)?.toDouble() ?? 11.0168,
      longitude: (loc['longitude'] as num?)?.toDouble() ?? 76.9558,
      timezone: (loc['timezone'] as num?)?.toDouble() ?? 5.5,
      tithi: NavamshaTithi.fromJson(astro['tithi'] as Map<String, dynamic>? ?? {}),
      nakshatra: NavamshaNakshatra.fromJson(astro['nakshatra'] as Map<String, dynamic>? ?? {}),
      yogaEn: (astro['yoga'] as Map<String, dynamic>?)?['nameEn'] as String? ?? 'Siddha',
      yogaTa: (astro['yoga'] as Map<String, dynamic>?)?['nameTa'] as String? ?? 'சித்தம்',
      karanaEn: (astro['karana'] as Map<String, dynamic>?)?['nameEn'] as String? ?? 'Bava',
      karanaTa: (astro['karana'] as Map<String, dynamic>?)?['nameTa'] as String? ?? 'பவம்',
      varaEn: (astro['vara'] as Map<String, dynamic>?)?['nameEn'] as String? ?? 'Monday',
      varaTa: (astro['vara'] as Map<String, dynamic>?)?['nameTa'] as String? ?? 'திங்கட்கிழமை',
      sunTimes: NavamshaSunTimes.fromJson(astro['sunTimes'] as Map<String, dynamic>? ?? {}),
      inauspicious: NavamshaInauspicious.fromJson(astro['inauspicious'] as Map<String, dynamic>? ?? {}),
      auspicious: NavamshaAuspicious.fromJson(astro['auspiciousTimings'] as Map<String, dynamic>? ?? {}),
      observances: NavamshaObservances.fromJson(astro['observances'] as Map<String, dynamic>? ?? {}),
      rawNavamshaData: astro['rawNavamshaData'] as Map<String, dynamic>? ?? {},
      sourceProvider: meta['sourceProvider'] as String? ?? 'navamsha_api_v1',
      fetchedAt: meta['fetchedAt'] != null ? DateTime.tryParse(meta['fetchedAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
