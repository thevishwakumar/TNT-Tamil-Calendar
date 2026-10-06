import '../../models/tnt_models.dart';

/// Aggregated data bundle for a single calendar date in the Panchangam Module
/// Supports offline local storage caching with full serialization/deserialization.
class PanchangamDailyBundle {
  final DateTime date;
  final String location;
  final CalendarDay calendarDay;
  final PanchangamEntry panchangam;
  final List<TimingEntry> timings;
  final List<SpecialDay> specialDays;
  final List<Festival> festivals;
  final List<MuhurthamDate> muhurthams;
  final bool isFromOfflineCache;
  final DateTime? cachedAt;

  PanchangamDailyBundle({
    required this.date,
    required this.location,
    required this.calendarDay,
    required this.panchangam,
    required this.timings,
    required this.specialDays,
    required this.festivals,
    required this.muhurthams,
    this.isFromOfflineCache = false,
    this.cachedAt,
  });

  bool get hasSpecialDays => specialDays.isNotEmpty;
  bool get hasFestivals => festivals.isNotEmpty;
  bool get hasMuhurtham => muhurthams.isNotEmpty;

  PanchangamDailyBundle copyWith({
    DateTime? date,
    String? location,
    CalendarDay? calendarDay,
    PanchangamEntry? panchangam,
    List<TimingEntry>? timings,
    List<SpecialDay>? specialDays,
    List<Festival>? festivals,
    List<MuhurthamDate>? muhurthams,
    bool? isFromOfflineCache,
    DateTime? cachedAt,
  }) {
    return PanchangamDailyBundle(
      date: date ?? this.date,
      location: location ?? this.location,
      calendarDay: calendarDay ?? this.calendarDay,
      panchangam: panchangam ?? this.panchangam,
      timings: timings ?? this.timings,
      specialDays: specialDays ?? this.specialDays,
      festivals: festivals ?? this.festivals,
      muhurthams: muhurthams ?? this.muhurthams,
      isFromOfflineCache: isFromOfflineCache ?? this.isFromOfflineCache,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  /// Serialize to JSON map for local storage cache persistence
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'location': location,
      'isFromOfflineCache': isFromOfflineCache,
      'cachedAt': cachedAt?.toIso8601String(),
      'calendarDay': {
        'gregorian_date': calendarDay.gregorianDate.toIso8601String(),
        'tamil_month': calendarDay.tamilMonth,
        'tamil_year': calendarDay.tamilYear,
        'tamil_day': calendarDay.tamilDay,
        'tamil_date_str': calendarDay.tamilDateStr,
        'tithi': calendarDay.tithi,
        'tithi_ta': calendarDay.tithiTa,
        'nakshatra': calendarDay.nakshatra,
        'nakshatra_ta': calendarDay.nakshatraTa,
        'is_auspicious': calendarDay.isAuspicious,
      },
      'panchangam': {
        'date': panchangam.date.toIso8601String(),
        'tithi': panchangam.tithi,
        'tithi_ta': panchangam.tithiTa,
        'nakshatra': panchangam.nakshatra,
        'nakshatra_ta': panchangam.nakshatraTa,
        'yoga': panchangam.yoga,
        'yoga_ta': panchangam.yogaTa,
        'karana': panchangam.karana,
        'karana_ta': panchangam.karanaTa,
        'sunrise': panchangam.sunrise,
        'sunset': panchangam.sunset,
        'moonrise': panchangam.moonrise,
        'moonset': panchangam.moonset,
        'paksha': panchangam.paksha,
        'paksha_ta': panchangam.pakshaTa,
        'day_duration': panchangam.dayDuration,
        'night_duration': panchangam.nightDuration,
      },
      'timings': timings.map((t) => {
        'name': t.name,
        'name_ta': t.nameTa,
        'start_time': t.startTime,
        'end_time': t.endTime,
        'is_auspicious': t.isAuspicious,
        'category': t.category,
        'description': t.description,
        'description_ta': t.descriptionTa,
      }).toList(),
      'specialDays': specialDays.map((s) => {
        'id': s.id,
        'date': s.date.toIso8601String(),
        'tamil_date_str': s.tamilDateStr,
        'title': s.title,
        'title_ta': s.titleTa,
        'category': s.category,
        'category_ta': s.categoryTa,
        'is_holiday': s.isHoliday,
        'description': s.description,
        'description_ta': s.descriptionTa,
        'timing_window': s.timingWindow,
        'location': s.location,
      }).toList(),
      'festivals': festivals.map((f) => {
        'id': f.id,
        'name': f.name,
        'name_ta': f.nameTa,
        'date': f.date.toIso8601String(),
        'tamil_date_str': f.tamilDateStr,
        'description': f.description,
        'description_ta': f.descriptionTa,
        'is_gazetted_holiday': f.isHoliday,
        'is_government_holiday': f.isHoliday,
        'significance': f.significance,
        'significance_ta': f.significanceTa,
        'category': f.category,
      }).toList(),
      'muhurthams': muhurthams.map((m) => {
        'id': m.id,
        'date': m.date.toIso8601String(),
        'tamil_date_str': m.tamilDateStr,
        'tamil_month': m.tamilMonth,
        'tamil_year': m.tamilYear,
        'day_of_week_en': m.dayOfWeekEn,
        'day_of_week_ta': m.dayOfWeekTa,
        'start_time': m.startTime,
        'end_time': m.endTime,
        'duration': m.duration,
        'is_valarthirai': m.isValarthirai,
        'description': m.description,
        'description_ta': m.descriptionTa,
        'category': m.category,
        'category_ta': m.categoryTa,
        'suitable_purpose': m.suitablePurpose,
        'suitable_purpose_ta': m.suitablePurposeTa,
        'nakshatra': m.nakshatra,
        'nakshatra_ta': m.nakshatraTa,
        'tithi': m.tithi,
        'tithi_ta': m.tithiTa,
        'yoga': m.yoga,
        'yoga_ta': m.yogaTa,
        'karana': m.karana,
        'karana_ta': m.karanaTa,
        'lagnam': m.lagnam,
        'lagnam_ta': m.lagnamTa,
        'subha_horai': m.subhaHorai,
        'subha_horai_ta': m.subhaHoraiTa,
        'rahu_kalam': m.rahuKalam,
        'yamagandam': m.yamagandam,
        'kuligai': m.kuligai,
        'approved_status': m.approvedStatus,
        'notes': m.notes,
        'notes_ta': m.notesTa,
        'location': m.location,
      }).toList(),
    };
  }

  /// Construct bundle from local storage JSON map
  factory PanchangamDailyBundle.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final location = json['location'] as String? ?? 'Chennai';
    final isOffline = json['isFromOfflineCache'] as bool? ?? true;
    final cachedAtStr = json['cachedAt'] as String?;
    final cachedAt = cachedAtStr != null ? DateTime.tryParse(cachedAtStr) : null;

    final calDayJson = json['calendarDay'] as Map<String, dynamic>;
    final calendarDay = CalendarDay.fromJson(calDayJson);

    final panchangamJson = json['panchangam'] as Map<String, dynamic>;
    final panchangam = PanchangamEntry.fromJson(panchangamJson);

    final timingsList = (json['timings'] as List<dynamic>? ?? [])
        .map((item) => TimingEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    final specialDaysList = (json['specialDays'] as List<dynamic>? ?? [])
        .map((item) => SpecialDay.fromJson(item as Map<String, dynamic>))
        .toList();

    final festivalsList = (json['festivals'] as List<dynamic>? ?? [])
        .map((item) => Festival.fromJson(item as Map<String, dynamic>))
        .toList();

    final muhurthamsList = (json['muhurthams'] as List<dynamic>? ?? [])
        .map((item) => MuhurthamDate.fromJson(item as Map<String, dynamic>))
        .toList();

    return PanchangamDailyBundle(
      date: date,
      location: location,
      calendarDay: calendarDay,
      panchangam: panchangam,
      timings: timingsList,
      specialDays: specialDaysList,
      festivals: festivalsList,
      muhurthams: muhurthamsList,
      isFromOfflineCache: isOffline,
      cachedAt: cachedAt,
    );
  }
}
