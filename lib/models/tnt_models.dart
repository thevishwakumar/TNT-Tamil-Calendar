/// TNT Data Models
/// Strongly-typed models supporting Tamil and English localization out-of-the-box.
library;

enum UserRole {
  user,
  admin,
}

enum AccountStatus {
  pendingEmailVerification,
  pendingMobileVerification,
  active,
  suspended,
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role; // 'admin' | 'user'
  final String accountStatus; // 'PENDING_EMAIL_VERIFICATION' | 'PENDING_MOBILE_VERIFICATION' | 'ACTIVE' | 'SUSPENDED'
  final String? avatarUrl;
  final bool isGuest;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required dynamic role, // Can be String or UserRole for complete backwards compatibility
    String? accountStatus,
    this.avatarUrl,
    this.isGuest = false,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.createdAt,
    this.updatedAt,
  })  : role = (role is UserRole) ? (role == UserRole.admin ? 'admin' : 'user') : (role?.toString().toLowerCase() ?? 'user'),
        accountStatus = accountStatus ?? 'ACTIVE';

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => !isAdmin;
  bool get isActive => accountStatus == 'ACTIVE';
  bool get isPendingEmail => accountStatus == 'PENDING_EMAIL_VERIFICATION';
  bool get isPendingMobile => accountStatus == 'PENDING_MOBILE_VERIFICATION';
  bool get isSuspended => accountStatus == 'SUSPENDED';

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? role,
    String? accountStatus,
    String? avatarUrl,
    bool? isGuest,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone'] as String? ?? json['phone_number'] as String?,
      role: json['role'] as String? ?? 'user',
      accountStatus: json['account_status'] as String? ?? 'ACTIVE',
      avatarUrl: json['avatar_url'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      emailVerifiedAt: json['email_verified_at'] != null ? DateTime.tryParse(json['email_verified_at']) : null,
      phoneVerifiedAt: json['phone_verified_at'] != null ? DateTime.tryParse(json['phone_verified_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phoneNumber,
      'role': role,
      'account_status': accountStatus,
      'avatar_url': avatarUrl,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class NotificationPreferences {
  final bool allNotifications;
  final bool panchangamNotifications;
  final bool muhurthamNotifications;
  final bool festivalNotifications;
  final bool specialDayNotifications;
  final bool reminderNotifications;
  final bool importantUpdates;
  final bool marketingNotifications; // CRITICAL: Strict OFF by default

  const NotificationPreferences({
    this.allNotifications = true,
    this.panchangamNotifications = true,
    this.muhurthamNotifications = true,
    this.festivalNotifications = true,
    this.specialDayNotifications = true,
    this.reminderNotifications = true,
    this.importantUpdates = true,
    this.marketingNotifications = false,
  });

  NotificationPreferences copyWith({
    bool? allNotifications,
    bool? panchangamNotifications,
    bool? muhurthamNotifications,
    bool? festivalNotifications,
    bool? specialDayNotifications,
    bool? reminderNotifications,
    bool? importantUpdates,
    bool? marketingNotifications,
  }) {
    return NotificationPreferences(
      allNotifications: allNotifications ?? this.allNotifications,
      panchangamNotifications: panchangamNotifications ?? this.panchangamNotifications,
      muhurthamNotifications: muhurthamNotifications ?? this.muhurthamNotifications,
      festivalNotifications: festivalNotifications ?? this.festivalNotifications,
      specialDayNotifications: specialDayNotifications ?? this.specialDayNotifications,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
      importantUpdates: importantUpdates ?? this.importantUpdates,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final all = json['all_notifications'] as bool? ?? json['notification_enabled'] as bool? ?? true;
    return NotificationPreferences(
      allNotifications: all,
      panchangamNotifications: json['panchangam_notifications'] as bool? ?? true,
      muhurthamNotifications: json['muhurtham_notifications'] as bool? ?? true,
      festivalNotifications: json['festival_notifications'] as bool? ?? true,
      specialDayNotifications: json['special_day_notifications'] as bool? ?? true,
      reminderNotifications: json['reminder_notifications'] as bool? ?? true,
      importantUpdates: json['important_updates'] as bool? ?? true,
      marketingNotifications: json['marketing_notifications'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all_notifications': allNotifications,
      'notification_enabled': allNotifications,
      'panchangam_notifications': panchangamNotifications,
      'muhurtham_notifications': muhurthamNotifications,
      'festival_notifications': festivalNotifications,
      'special_day_notifications': specialDayNotifications,
      'reminder_notifications': reminderNotifications,
      'important_updates': importantUpdates,
      'marketing_notifications': marketingNotifications,
    };
  }
}

class UserPreferences {
  final String userId;
  final String language; // 'ta' | 'en'
  final String location;
  final bool notificationsEnabled;
  final NotificationPreferences notificationPreferences;

  UserPreferences({
    required this.userId,
    required this.language,
    required this.location,
    required this.notificationsEnabled,
    NotificationPreferences? notificationPreferences,
  }) : notificationPreferences = notificationPreferences ?? NotificationPreferences(allNotifications: notificationsEnabled);

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final notifEnabled = json['notifications_enabled'] as bool? ?? json['all_notifications'] as bool? ?? true;
    return UserPreferences(
      userId: json['user_id'] as String,
      language: json['language'] as String? ?? 'ta',
      location: json['location'] as String? ?? 'Chennai',
      notificationsEnabled: notifEnabled,
      notificationPreferences: NotificationPreferences.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language': language,
      'location': location,
      'notifications_enabled': notificationsEnabled,
      ...notificationPreferences.toJson(),
    };
  }

  UserPreferences copyWith({
    String? userId,
    String? language,
    String? location,
    bool? notificationsEnabled,
    NotificationPreferences? notificationPreferences,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      location: location ?? this.location,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }
}

class CalendarDay {
  final DateTime gregorianDate;
  final String tamilMonth;
  final String tamilYear;
  final int tamilDay;
  final String tamilDateStr; // e.g., "புரட்டாசி 12"
  final String tithi;
  final String tithiTa;
  final String nakshatra;
  final String nakshatraTa;
  final bool isAuspicious;

  CalendarDay({
    required this.gregorianDate,
    required this.tamilMonth,
    required this.tamilYear,
    required this.tamilDay,
    required this.tamilDateStr,
    required this.tithi,
    required this.tithiTa,
    required this.nakshatra,
    required this.nakshatraTa,
    required this.isAuspicious,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      gregorianDate: DateTime.parse(json['gregorian_date'] as String),
      tamilMonth: json['tamil_month'] as String,
      tamilYear: json['tamil_year'] as String,
      tamilDay: json['tamil_day'] as int,
      tamilDateStr: json['tamil_date_str'] as String,
      tithi: json['tithi'] as String,
      tithiTa: json['tithi_ta'] as String,
      nakshatra: json['nakshatra'] as String,
      nakshatraTa: json['nakshatra_ta'] as String,
      isAuspicious: json['is_auspicious'] as bool? ?? true,
    );
  }
}

class PanchangamEntry {
  final DateTime date;
  final String tithi;
  final String tithiTa;
  final String nakshatra;
  final String nakshatraTa;
  final String yoga;
  final String yogaTa;
  final String karana;
  final String karanaTa;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String paksha;
  final String pakshaTa;
  final String dayDuration;
  final String nightDuration;

  PanchangamEntry({
    required this.date,
    required this.tithi,
    required this.tithiTa,
    required this.nakshatra,
    required this.nakshatraTa,
    required this.yoga,
    required this.yogaTa,
    required this.karana,
    required this.karanaTa,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    this.paksha = 'Shukla Paksha',
    this.pakshaTa = 'வளர்பிறை',
    this.dayDuration = '12h 06m',
    this.nightDuration = '11h 54m',
  });

  factory PanchangamEntry.fromJson(Map<String, dynamic> json) {
    return PanchangamEntry(
      date: DateTime.parse(json['date'] as String),
      tithi: json['tithi'] as String,
      tithiTa: json['tithi_ta'] as String,
      nakshatra: json['nakshatra'] as String,
      nakshatraTa: json['nakshatra_ta'] as String,
      yoga: json['yoga'] as String,
      yogaTa: json['yoga_ta'] as String,
      karana: json['karana'] as String,
      karanaTa: json['karana_ta'] as String,
      sunrise: json['sunrise'] as String,
      sunset: json['sunset'] as String,
      moonrise: json['moonrise'] as String? ?? '--:--',
      moonset: json['moonset'] as String? ?? '--:--',
      paksha: json['paksha'] as String? ?? 'Shukla Paksha',
      pakshaTa: json['paksha_ta'] as String? ?? 'வளர்பிறை',
      dayDuration: json['day_duration'] as String? ?? '12h 06m',
      nightDuration: json['night_duration'] as String? ?? '11h 54m',
    );
  }
}

class TimingEntry {
  final String name;
  final String nameTa;
  final String startTime;
  final String endTime;
  final bool isAuspicious;
  final String category;
  final String description;
  final String descriptionTa;

  TimingEntry({
    required this.name,
    required this.nameTa,
    required this.startTime,
    required this.endTime,
    required this.isAuspicious,
    this.category = 'general',
    this.description = '',
    this.descriptionTa = '',
  });

  factory TimingEntry.fromJson(Map<String, dynamic> json) {
    return TimingEntry(
      name: json['name'] as String,
      nameTa: json['name_ta'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAuspicious: json['is_auspicious'] as bool? ?? false,
      category: json['category'] as String? ?? json['timing_type'] as String? ?? 'general',
      description: json['description'] as String? ?? '',
      descriptionTa: json['description_ta'] as String? ?? '',
    );
  }
}

class MuhurthamTimingItem {
  final String startTime;
  final String endTime;
  final String duration;
  final String lagnam;
  final String lagnamTa;
  final String nakshatra;
  final String nakshatraTa;
  final String subhaHorai;
  final String subhaHoraiTa;
  final String description;
  final String descriptionTa;
  final bool isPrime;

  MuhurthamTimingItem({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.lagnam,
    required this.lagnamTa,
    required this.nakshatra,
    required this.nakshatraTa,
    required this.subhaHorai,
    required this.subhaHoraiTa,
    this.description = '',
    this.descriptionTa = '',
    this.isPrime = true,
  });

  factory MuhurthamTimingItem.fromJson(Map<String, dynamic> json) {
    return MuhurthamTimingItem(
      startTime: json['start_time'] as String? ?? '06:00 AM',
      endTime: json['end_time'] as String? ?? '07:30 AM',
      duration: json['duration'] as String? ?? '1h 30m',
      lagnam: json['lagnam'] as String? ?? 'Mesha',
      lagnamTa: json['lagnam_ta'] as String? ?? 'மேஷம்',
      nakshatra: json['nakshatra'] as String? ?? 'Rohini',
      nakshatraTa: json['nakshatra_ta'] as String? ?? 'ரோகிணி',
      subhaHorai: json['subha_horai'] as String? ?? 'Guru Horai',
      subhaHoraiTa: json['subha_horai_ta'] as String? ?? 'குரு ஹோரை',
      description: json['description'] as String? ?? '',
      descriptionTa: json['description_ta'] as String? ?? '',
      isPrime: json['is_prime'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'lagnam': lagnam,
      'lagnam_ta': lagnamTa,
      'nakshatra': nakshatra,
      'nakshatra_ta': nakshatraTa,
      'subha_horai': subhaHorai,
      'subha_horai_ta': subhaHoraiTa,
      'description': description,
      'description_ta': descriptionTa,
      'is_prime': isPrime,
    };
  }
}




class MuhurthamDate {
  final String id;
  final DateTime date;
  final String tamilDateStr;
  final String tamilMonth;
  final String tamilYear;
  final String dayOfWeekEn;
  final String dayOfWeekTa;
  final String startTime;
  final String endTime;
  final String duration;
  final bool isValarthirai; // வளர்பிறை vs தேய்பிறை
  final String description;
  final String descriptionTa;
  final String category;
  final String categoryTa;
  final String suitablePurpose;
  final String suitablePurposeTa;
  final String nakshatra;
  final String nakshatraTa;
  final String nakshatraTime;
  final String tithi;
  final String tithiTa;
  final String yoga;
  final String yogaTa;
  final String karana;
  final String karanaTa;
  final String lagnam;
  final String lagnamTa;
  final String subhaHorai;
  final String subhaHoraiTa;
  final String rahuKalam;
  final String yamagandam;
  final String kuligai;
  final String approvedStatus;
  final String notes;
  final String notesTa;
  final String location;
  final int timingsCount;
  final List<MuhurthamTimingItem> timings;
  final bool isSaved;
  final bool hasReminder;

  MuhurthamDate({
    String? id,
    required this.date,
    required this.tamilDateStr,
    this.tamilMonth = 'ஐப்பசி',
    this.tamilYear = 'குரோதி வருடம்',
    this.dayOfWeekEn = 'Monday',
    this.dayOfWeekTa = 'திங்கள்',
    required this.startTime,
    required this.endTime,
    this.duration = '1h 30m',
    required this.isValarthirai,
    required this.description,
    required this.descriptionTa,
    this.category = 'Marriage',
    this.categoryTa = 'திருமணம்',
    this.suitablePurpose = 'Wedding & Alliance',
    this.suitablePurposeTa = 'திருமணம் மற்றும் நிச்சயதார்த்தம்',
    this.nakshatra = 'Rohini',
    this.nakshatraTa = 'ரோகிணி',
    this.nakshatraTime = 'முழு நாள் (Full day)',
    this.tithi = 'Shukla Dashami',
    this.tithiTa = 'சுக்கில தசமி',
    this.yoga = 'Amrita Yoga',
    this.yogaTa = 'அமிர்த யோகம்',
    this.karana = 'Balava',
    this.karanaTa = 'பாலவம்',
    this.lagnam = 'Mesha Lagnam',
    this.lagnamTa = 'மேஷ லக்னம்',
    this.subhaHorai = 'Guru Horai',
    this.subhaHoraiTa = 'குரு ஹோரை',
    this.rahuKalam = '07:30 AM - 09:00 AM',
    this.yamagandam = '01:30 PM - 03:00 PM',
    this.kuligai = '10:30 AM - 12:00 PM',
    this.approvedStatus = 'Approved',
    this.notes = 'Avoid Rahu Kalam strictly for Thali knotting ceremony.',
    this.notesTa = 'மாங்கல்ய தாரணத்திற்கு இராகு காலத்தை முழுமையாக தவிர்க்கவும்.',
    this.location = 'Tamil Nadu (IST)',
    this.timingsCount = 1,
    this.timings = const [],
    this.isSaved = false,
    this.hasReminder = false,
  }) : id = id ?? '${date.year}-${date.month}-${date.day}-$category';

  MuhurthamDate copyWith({
    String? id,
    DateTime? date,
    String? tamilDateStr,
    String? tamilMonth,
    String? tamilYear,
    String? dayOfWeekEn,
    String? dayOfWeekTa,
    String? startTime,
    String? endTime,
    String? duration,
    bool? isValarthirai,
    String? description,
    String? descriptionTa,
    String? category,
    String? categoryTa,
    String? suitablePurpose,
    String? suitablePurposeTa,
    String? nakshatra,
    String? nakshatraTa,
    String? nakshatraTime,
    String? tithi,
    String? tithiTa,
    String? yoga,
    String? yogaTa,
    String? karana,
    String? karanaTa,
    String? lagnam,
    String? lagnamTa,
    String? subhaHorai,
    String? subhaHoraiTa,
    String? rahuKalam,
    String? yamagandam,
    String? kuligai,
    String? approvedStatus,
    String? notes,
    String? notesTa,
    String? location,
    int? timingsCount,
    List<MuhurthamTimingItem>? timings,
    bool? isSaved,
    bool? hasReminder,
  }) {
    return MuhurthamDate(
      id: id ?? this.id,
      date: date ?? this.date,
      tamilDateStr: tamilDateStr ?? this.tamilDateStr,
      tamilMonth: tamilMonth ?? this.tamilMonth,
      tamilYear: tamilYear ?? this.tamilYear,
      dayOfWeekEn: dayOfWeekEn ?? this.dayOfWeekEn,
      dayOfWeekTa: dayOfWeekTa ?? this.dayOfWeekTa,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isValarthirai: isValarthirai ?? this.isValarthirai,
      description: description ?? this.description,
      descriptionTa: descriptionTa ?? this.descriptionTa,
      category: category ?? this.category,
      categoryTa: categoryTa ?? this.categoryTa,
      suitablePurpose: suitablePurpose ?? this.suitablePurpose,
      suitablePurposeTa: suitablePurposeTa ?? this.suitablePurposeTa,
      nakshatra: nakshatra ?? this.nakshatra,
      nakshatraTa: nakshatraTa ?? this.nakshatraTa,
      nakshatraTime: nakshatraTime ?? this.nakshatraTime,
      tithi: tithi ?? this.tithi,
      tithiTa: tithiTa ?? this.tithiTa,
      yoga: yoga ?? this.yoga,
      yogaTa: yogaTa ?? this.yogaTa,
      karana: karana ?? this.karana,
      karanaTa: karanaTa ?? this.karanaTa,
      lagnam: lagnam ?? this.lagnam,
      lagnamTa: lagnamTa ?? this.lagnamTa,
      subhaHorai: subhaHorai ?? this.subhaHorai,
      subhaHoraiTa: subhaHoraiTa ?? this.subhaHoraiTa,
      rahuKalam: rahuKalam ?? this.rahuKalam,
      yamagandam: yamagandam ?? this.yamagandam,
      kuligai: kuligai ?? this.kuligai,
      approvedStatus: approvedStatus ?? this.approvedStatus,
      notes: notes ?? this.notes,
      notesTa: notesTa ?? this.notesTa,
      location: location ?? this.location,
      timingsCount: timingsCount ?? this.timingsCount,
      timings: timings ?? this.timings,
      isSaved: isSaved ?? this.isSaved,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  factory MuhurthamDate.fromJson(Map<String, dynamic> json) {
    final rawDate = DateTime.parse(json['date'] as String);
    final rawTimings = json['timings'] as List<dynamic>?;
    final parsedTimings = rawTimings != null
        ? rawTimings.map((t) => MuhurthamTimingItem.fromJson(t as Map<String, dynamic>)).toList()
        : <MuhurthamTimingItem>[];

    return MuhurthamDate(
      id: json['id'] as String? ?? '${rawDate.year}-${rawDate.month}-${rawDate.day}-${json['category'] ?? 'Marriage'}',
      date: rawDate,
      tamilDateStr: json['tamil_date_str'] as String? ?? json['tamil_date'] as String? ?? '',
      tamilMonth: json['tamil_month'] as String? ?? 'ஐப்பசி',
      tamilYear: json['tamil_year'] as String? ?? 'குரோதி வருடம்',
      dayOfWeekEn: json['day_of_week_en'] as String? ?? 'Monday',
      dayOfWeekTa: json['day_of_week_ta'] as String? ?? 'திங்கள்',
      startTime: json['start_time'] as String? ?? '06:00 AM',
      endTime: json['end_time'] as String? ?? '07:30 AM',
      duration: json['duration'] as String? ?? '1h 30m',
      isValarthirai: json['is_valarthirai'] as bool? ?? true,
      description: json['description'] as String? ?? json['description_english'] as String? ?? '',
      descriptionTa: json['description_ta'] as String? ?? json['description_tamil'] as String? ?? '',
      category: json['category'] as String? ?? 'Marriage',
      categoryTa: json['category_ta'] as String? ?? 'திருமணம்',
      suitablePurpose: json['suitable_purpose'] as String? ?? 'Wedding & Alliance',
      suitablePurposeTa: json['suitable_purpose_ta'] as String? ?? 'திருமணம் மற்றும் நிச்சயதார்த்தம்',
      nakshatra: json['nakshatra'] as String? ?? 'Rohini',
      nakshatraTa: json['nakshatra_ta'] as String? ?? 'ரோகிணி',
      nakshatraTime: json['nakshatra_time'] as String? ?? 'முழு நாள் (Full day)',
      tithi: json['tithi'] as String? ?? 'Shukla Dashami',
      tithiTa: json['tithi_ta'] as String? ?? 'சுக்கில தசமி',
      yoga: json['yoga'] as String? ?? 'Amrita Yoga',
      yogaTa: json['yoga_ta'] as String? ?? 'அமிர்த யோகம்',
      karana: json['karana'] as String? ?? 'Balava',
      karanaTa: json['karana_ta'] as String? ?? 'பாலவம்',
      lagnam: json['lagnam'] as String? ?? 'Mesha Lagnam',
      lagnamTa: json['lagnam_ta'] as String? ?? 'மேஷ லக்னம்',
      subhaHorai: json['subha_horai'] as String? ?? 'Guru Horai',
      subhaHoraiTa: json['subha_horai_ta'] as String? ?? 'குரு ஹோரை',
      rahuKalam: json['rahu_kalam'] as String? ?? '07:30 AM - 09:00 AM',
      yamagandam: json['yamagandam'] as String? ?? '01:30 PM - 03:00 PM',
      kuligai: json['kuligai'] as String? ?? '10:30 AM - 12:00 PM',
      approvedStatus: json['approved_status'] as String? ?? 'Approved',
      notes: json['notes'] as String? ?? '',
      notesTa: json['notes_ta'] as String? ?? '',
      location: json['location'] as String? ?? 'Tamil Nadu (IST)',
      timingsCount: parsedTimings.isNotEmpty ? parsedTimings.length : 1,
      timings: parsedTimings,
      isSaved: json['is_saved'] as bool? ?? false,
      hasReminder: json['has_reminder'] as bool? ?? false,
    );
  }
}

class SpecialDay {
  final String id;
  final DateTime date;
  final String tamilDateStr;
  final String tamilMonth;
  final String tamilYear;
  final String dayOfWeekEn;
  final String dayOfWeekTa;
  final String title;
  final String titleTa;
  final String category;
  final String categoryTa;
  final bool isHoliday;
  final String description;
  final String descriptionTa;
  final String rituals;
  final String ritualsTa;
  final String deity;
  final String deityTa;
  final String significance;
  final String significanceTa;
  final String timingWindow;
  final String? imageUrl;
  final String location;
  final bool isPublished;
  final String status;
  final bool isSaved;
  final bool hasReminder;

  SpecialDay({
    String? id,
    required this.date,
    this.tamilDateStr = '',
    this.tamilMonth = 'புரட்டாசி',
    this.tamilYear = 'சுபகிருது வருடம்',
    this.dayOfWeekEn = 'Monday',
    this.dayOfWeekTa = 'திங்கள்',
    required this.title,
    required this.titleTa,
    this.category = 'special_day',
    this.categoryTa = 'சிறப்பு நாள்',
    required this.isHoliday,
    required this.description,
    required this.descriptionTa,
    this.rituals = '',
    this.ritualsTa = '',
    this.deity = 'Lord Shiva',
    this.deityTa = 'சிவபெருமான்',
    this.significance = '',
    this.significanceTa = '',
    this.timingWindow = 'Full Day',
    this.imageUrl,
    this.location = 'Tamil Nadu',
    this.isPublished = true,
    this.status = 'PUBLISHED',
    this.isSaved = false,
    this.hasReminder = false,
  }) : id = id ?? '${date.year}-${date.month}-${date.day}-$category';

  SpecialDay copyWith({
    String? id,
    DateTime? date,
    String? tamilDateStr,
    String? tamilMonth,
    String? tamilYear,
    String? dayOfWeekEn,
    String? dayOfWeekTa,
    String? title,
    String? titleTa,
    String? category,
    String? categoryTa,
    bool? isHoliday,
    String? description,
    String? descriptionTa,
    String? rituals,
    String? ritualsTa,
    String? deity,
    String? deityTa,
    String? significance,
    String? significanceTa,
    String? timingWindow,
    String? imageUrl,
    String location = 'Tamil Nadu',
    bool? isPublished,
    String? status,
    bool? isSaved,
    bool? hasReminder,
  }) {
    return SpecialDay(
      id: id ?? this.id,
      date: date ?? this.date,
      tamilDateStr: tamilDateStr ?? this.tamilDateStr,
      tamilMonth: tamilMonth ?? this.tamilMonth,
      tamilYear: tamilYear ?? this.tamilYear,
      dayOfWeekEn: dayOfWeekEn ?? this.dayOfWeekEn,
      dayOfWeekTa: dayOfWeekTa ?? this.dayOfWeekTa,
      title: title ?? this.title,
      titleTa: titleTa ?? this.titleTa,
      category: category ?? this.category,
      categoryTa: categoryTa ?? this.categoryTa,
      isHoliday: isHoliday ?? this.isHoliday,
      description: description ?? this.description,
      descriptionTa: descriptionTa ?? this.descriptionTa,
      rituals: rituals ?? this.rituals,
      ritualsTa: ritualsTa ?? this.ritualsTa,
      deity: deity ?? this.deity,
      deityTa: deityTa ?? this.deityTa,
      significance: significance ?? this.significance,
      significanceTa: significanceTa ?? this.significanceTa,
      timingWindow: timingWindow ?? this.timingWindow,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location,
      isPublished: isPublished ?? this.isPublished,
      status: status ?? this.status,
      isSaved: isSaved ?? this.isSaved,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    final d = DateTime.parse(json['date'] as String);
    final cat = json['category'] as String? ?? 'special_day';
    return SpecialDay(
      id: json['id'] as String? ?? '${d.year}-${d.month}-${d.day}-$cat',
      date: d,
      tamilDateStr: json['tamil_date_str'] as String? ?? '',
      tamilMonth: json['tamil_month'] as String? ?? 'புரட்டாசி',
      tamilYear: json['tamil_year'] as String? ?? 'சுபகிருது வருடம்',
      dayOfWeekEn: json['day_of_week_en'] as String? ?? 'Monday',
      dayOfWeekTa: json['day_of_week_ta'] as String? ?? 'திங்கள்',
      title: json['title'] as String? ?? json['name'] as String? ?? json['name_english'] as String? ?? '',
      titleTa: json['title_ta'] as String? ?? json['name_ta'] as String? ?? json['name_tamil'] as String? ?? '',
      category: cat,
      categoryTa: json['category_ta'] as String? ?? _getCategoryTa(cat),
      isHoliday: json['is_holiday'] as bool? ?? false,
      description: json['description'] as String? ?? json['description_english'] as String? ?? json['significance'] as String? ?? '',
      descriptionTa: json['description_ta'] as String? ?? json['description_tamil'] as String? ?? json['significance_ta'] as String? ?? '',
      rituals: json['rituals'] as String? ?? '',
      ritualsTa: json['rituals_ta'] as String? ?? '',
      deity: json['deity'] as String? ?? 'Lord Shiva',
      deityTa: json['deity_ta'] as String? ?? 'சிவபெருமான்',
      significance: json['significance'] as String? ?? '',
      significanceTa: json['significance_ta'] as String? ?? '',
      timingWindow: json['timing_window'] as String? ?? 'Full Day',
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String? ?? 'Tamil Nadu',
      isPublished: json['is_published'] as bool? ?? true,
      status: json['status'] as String? ?? 'PUBLISHED',
      isSaved: json['is_saved'] as bool? ?? false,
      hasReminder: json['has_reminder'] as bool? ?? false,
    );
  }

  static String _getCategoryTa(String cat) {
    switch (cat.toLowerCase()) {
      case 'amavasai':
        return 'அமாவாசை';
      case 'pournami':
        return 'பௌர்ணமி';
      case 'pradosham':
        return 'பிரதோஷம்';
      case 'sashti':
        return 'சஷ்டி';
      case 'ekadashi':
        return 'ஏகாதசி';
      case 'krithigai':
        return 'கிருத்திகை';
      case 'chaturthi':
        return 'சதுர்த்தி';
      case 'sankatahara_chaturthi':
        return 'சங்கடஹர சதுர்த்தி';
      default:
        return 'சிறப்பு நாள்';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'tamil_date_str': tamilDateStr,
      'tamil_month': tamilMonth,
      'tamil_year': tamilYear,
      'day_of_week_en': dayOfWeekEn,
      'day_of_week_ta': dayOfWeekTa,
      'title': title,
      'title_ta': titleTa,
      'category': category,
      'category_ta': categoryTa,
      'is_holiday': isHoliday,
      'description': description,
      'description_ta': descriptionTa,
      'rituals': rituals,
      'rituals_ta': ritualsTa,
      'deity': deity,
      'deity_ta': deityTa,
      'significance': significance,
      'significance_ta': significanceTa,
      'timing_window': timingWindow,
      'image_url': imageUrl,
      'location': location,
      'is_published': isPublished,
      'status': status,
      'is_saved': isSaved,
      'has_reminder': hasReminder,
    };
  }
}


class Festival {
  final String id;
  final DateTime date;
  final String tamilDateStr;
  final String tamilMonth;
  final String tamilYear;
  final String dayOfWeekEn;
  final String dayOfWeekTa;
  final String name;
  final String nameTa;
  final String type; // 'hindu' | 'christian' | 'muslim' | 'government'
  final String typeTa;
  final String category;
  final String categoryTa;
  final String description;
  final String descriptionTa;
  final String rituals;
  final String ritualsTa;
  final String deity;
  final String deityTa;
  final String significance;
  final String significanceTa;
  final bool isHoliday;
  final String? imageUrl;
  final String location;
  final bool isPublished;
  final String status;
  final bool isSaved;
  final bool hasReminder;

  Festival({
    String? id,
    required this.date,
    this.tamilDateStr = '',
    this.tamilMonth = 'புரட்டாசி',
    this.tamilYear = 'சுபகிருது வருடம்',
    this.dayOfWeekEn = 'Monday',
    this.dayOfWeekTa = 'திங்கள்',
    required this.name,
    required this.nameTa,
    required this.type,
    this.typeTa = 'ஆன்மீக திருவிழா',
    this.category = 'Festivals',
    this.categoryTa = 'பண்டிகைகள்',
    required this.description,
    required this.descriptionTa,
    this.rituals = '',
    this.ritualsTa = '',
    this.deity = '',
    this.deityTa = '',
    this.significance = '',
    this.significanceTa = '',
    this.isHoliday = false,
    this.imageUrl,
    this.location = 'Tamil Nadu',
    this.isPublished = true,
    this.status = 'PUBLISHED',
    this.isSaved = false,
    this.hasReminder = false,
  }) : id = id ?? '${date.year}-${date.month}-${date.day}-$name';

  Festival copyWith({
    String? id,
    DateTime? date,
    String? tamilDateStr,
    String? tamilMonth,
    String? tamilYear,
    String? dayOfWeekEn,
    String? dayOfWeekTa,
    String? name,
    String? nameTa,
    String? type,
    String? typeTa,
    String? category,
    String? categoryTa,
    String? description,
    String? descriptionTa,
    String? rituals,
    String? ritualsTa,
    String? deity,
    String? deityTa,
    String? significance,
    String? significanceTa,
    bool? isHoliday,
    String? imageUrl,
    String? location,
    bool? isPublished,
    String? status,
    bool? isSaved,
    bool? hasReminder,
  }) {
    return Festival(
      id: id ?? this.id,
      date: date ?? this.date,
      tamilDateStr: tamilDateStr ?? this.tamilDateStr,
      tamilMonth: tamilMonth ?? this.tamilMonth,
      tamilYear: tamilYear ?? this.tamilYear,
      dayOfWeekEn: dayOfWeekEn ?? this.dayOfWeekEn,
      dayOfWeekTa: dayOfWeekTa ?? this.dayOfWeekTa,
      name: name ?? this.name,
      nameTa: nameTa ?? this.nameTa,
      type: type ?? this.type,
      typeTa: typeTa ?? this.typeTa,
      category: category ?? this.category,
      categoryTa: categoryTa ?? this.categoryTa,
      description: description ?? this.description,
      descriptionTa: descriptionTa ?? this.descriptionTa,
      rituals: rituals ?? this.rituals,
      ritualsTa: ritualsTa ?? this.ritualsTa,
      deity: deity ?? this.deity,
      deityTa: deityTa ?? this.deityTa,
      significance: significance ?? this.significance,
      significanceTa: significanceTa ?? this.significanceTa,
      isHoliday: isHoliday ?? this.isHoliday,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      isPublished: isPublished ?? this.isPublished,
      status: status ?? this.status,
      isSaved: isSaved ?? this.isSaved,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  factory Festival.fromJson(Map<String, dynamic> json) {
    final d = DateTime.parse(json['date'] as String);
    final n = json['name'] as String? ?? json['name_english'] as String? ?? json['title'] as String? ?? '';
    final t = json['type'] as String? ?? 'hindu';
    return Festival(
      id: json['id'] as String? ?? '${d.year}-${d.month}-${d.day}-$n',
      date: d,
      tamilDateStr: json['tamil_date_str'] as String? ?? '',
      tamilMonth: json['tamil_month'] as String? ?? 'புரட்டாசி',
      tamilYear: json['tamil_year'] as String? ?? 'சுபகிருது வருடம்',
      dayOfWeekEn: json['day_of_week_en'] as String? ?? 'Monday',
      dayOfWeekTa: json['day_of_week_ta'] as String? ?? 'திங்கள்',
      name: n,
      nameTa: json['name_ta'] as String? ?? json['name_tamil'] as String? ?? json['title_ta'] as String? ?? '',
      type: t,
      typeTa: json['type_ta'] as String? ?? (t == 'government' ? 'அரசு விடுமுறை' : 'ஆன்மீகத் திருவிழா'),
      category: json['category'] as String? ?? 'Festivals',
      categoryTa: json['category_ta'] as String? ?? 'பண்டிகைகள்',
      description: json['description'] as String? ?? json['description_english'] as String? ?? json['significance'] as String? ?? '',
      descriptionTa: json['description_ta'] as String? ?? json['description_tamil'] as String? ?? json['significance_ta'] as String? ?? '',
      rituals: json['rituals'] as String? ?? '',
      ritualsTa: json['rituals_ta'] as String? ?? '',
      deity: json['deity'] as String? ?? '',
      deityTa: json['deity_ta'] as String? ?? '',
      significance: json['significance'] as String? ?? '',
      significanceTa: json['significance_ta'] as String? ?? '',
      isHoliday: json['is_holiday'] as bool? ?? (t == 'government'),
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String? ?? 'Tamil Nadu',
      isPublished: json['is_published'] as bool? ?? true,
      status: json['status'] as String? ?? 'PUBLISHED',
      isSaved: json['is_saved'] as bool? ?? false,
      hasReminder: json['has_reminder'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'tamil_date_str': tamilDateStr,
      'tamil_month': tamilMonth,
      'tamil_year': tamilYear,
      'day_of_week_en': dayOfWeekEn,
      'day_of_week_ta': dayOfWeekTa,
      'name': name,
      'name_ta': nameTa,
      'type': type,
      'type_ta': typeTa,
      'category': category,
      'category_ta': categoryTa,
      'description': description,
      'description_ta': descriptionTa,
      'rituals': rituals,
      'rituals_ta': ritualsTa,
      'deity': deity,
      'deity_ta': deityTa,
      'significance': significance,
      'significance_ta': significanceTa,
      'is_holiday': isHoliday,
      'image_url': imageUrl,
      'location': location,
      'is_published': isPublished,
      'status': status,
      'is_saved': isSaved,
      'has_reminder': hasReminder,
    };
  }
}

class UserDevice {
  final String id;
  final String userId;
  final String deviceToken;
  final String platform; // 'android' | 'ios' | 'web'
  final String? appVersion;
  final Map<String, dynamic>? deviceInfo;
  final bool isActive;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDevice({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.platform,
    this.appVersion,
    this.deviceInfo,
    this.isActive = true,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceToken: json['device_token'] as String,
      platform: json['platform'] as String? ?? 'android',
      appVersion: json['app_version'] as String?,
      deviceInfo: json['device_info'] is Map<String, dynamic> ? json['device_info'] as Map<String, dynamic> : null,
      isActive: json['is_active'] as bool? ?? true,
      lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at'] as String) : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_token': deviceToken,
      'platform': platform,
      if (appVersion != null) 'app_version': appVersion,
      if (deviceInfo != null) 'device_info': deviceInfo,
      'is_active': isActive,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class NotificationItem {
  final String id;
  final String? userId;
  final String? campaignId;
  final String title;
  final String titleTa;
  final String message; // alias body
  final String messageTa; // alias bodyTa
  final String notificationType; // 'reminder' | 'festival' | 'special_day' | 'muhurtham' | 'panchangam' | 'marketing' | 'important_update'
  final String? relatedItemType; // 'muhurtham' | 'festival' | 'special_day' | 'panchangam' | 'reminder' | 'campaign'
  final String? relatedItemId;
  final DateTime sentAt;
  final DateTime? openedAt;
  final String status; // 'SENT' | 'DELIVERED' | 'OPENED' | 'FAILED'
  final bool isRead;
  final String category; // 'marketing' | 'panchangam' | 'admin' | 'general'
  final String? deepLink;
  final String? mediaUrl;

  NotificationItem({
    required this.id,
    this.userId,
    this.campaignId,
    required this.title,
    required this.titleTa,
    required this.message,
    required this.messageTa,
    this.notificationType = 'general',
    this.relatedItemType,
    this.relatedItemId,
    required this.sentAt,
    this.openedAt,
    this.status = 'SENT',
    this.isRead = false,
    this.category = 'general',
    this.deepLink,
    this.mediaUrl,
  });

  String get body => message;
  String get bodyTa => messageTa;

  String localizedTitle(bool isTamil) {
    if (isTamil && titleTa.isNotEmpty) return titleTa;
    return title;
  }

  String localizedBody(bool isTamil) {
    if (isTamil && messageTa.isNotEmpty) return messageTa;
    return message;
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? campaignId,
    String? title,
    String? titleTa,
    String? message,
    String? messageTa,
    String? notificationType,
    String? relatedItemType,
    String? relatedItemId,
    DateTime? sentAt,
    DateTime? openedAt,
    String? status,
    bool? isRead,
    String? category,
    String? deepLink,
    String? mediaUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      titleTa: titleTa ?? this.titleTa,
      message: message ?? this.message,
      messageTa: messageTa ?? this.messageTa,
      notificationType: notificationType ?? this.notificationType,
      relatedItemType: relatedItemType ?? this.relatedItemType,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      sentAt: sentAt ?? this.sentAt,
      openedAt: openedAt ?? this.openedAt,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      deepLink: deepLink ?? this.deepLink,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }

  factory NotificationItem.fromCampaign(NotificationCampaign campaign, {bool isRead = false}) {
    final catLower = campaign.category.toLowerCase();
    final titleEn = campaign.titleEnglish.isNotEmpty ? campaign.titleEnglish : campaign.title;
    final titleTa = campaign.titleTamil.isNotEmpty ? campaign.titleTamil : titleEn;
    final msgEn = campaign.messageEnglish.isNotEmpty ? campaign.messageEnglish : campaign.body;
    final msgTa = campaign.messageTamil.isNotEmpty ? campaign.messageTamil : msgEn;

    return NotificationItem(
      id: campaign.id,
      campaignId: campaign.id,
      title: titleEn,
      titleTa: titleTa,
      message: msgEn,
      messageTa: msgTa,
      notificationType: catLower,
      relatedItemType: catLower,
      relatedItemId: campaign.deepLink,
      sentAt: campaign.sentAt ?? campaign.createdAt,
      openedAt: null,
      status: campaign.status,
      isRead: isRead,
      category: catLower,
      deepLink: campaign.deepLink,
      mediaUrl: campaign.mediaReference,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final tEn = json['title'] as String? ?? json['title_english'] as String? ?? 'Notification';
    final tTa = json['title_ta'] as String? ?? json['title_tamil'] as String? ?? tEn;
    final bEn = json['body'] as String? ?? json['message'] as String? ?? json['message_english'] as String? ?? '';
    final bTa = json['body_ta'] as String? ?? json['message_ta'] as String? ?? json['message_tamil'] as String? ?? bEn;
    final rawType = json['notification_type'] as String? ?? json['category'] as String? ?? 'general';
    final type = rawType.toLowerCase();

    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      campaignId: json['campaign_id'] as String?,
      title: tEn,
      titleTa: tTa,
      message: bEn,
      messageTa: bTa,
      notificationType: type,
      relatedItemType: json['related_item_type'] as String? ?? type,
      relatedItemId: json['related_item_id'] as String?,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : DateTime.now(),
      openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at'] as String) : null,
      status: json['status'] as String? ?? 'SENT',
      isRead: json['is_read'] as bool? ?? (json['opened_at'] != null),
      category: (json['category'] as String? ?? type).toLowerCase(),
      deepLink: json['deep_link'] as String?,
      mediaUrl: json['media_reference'] as String? ?? json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      if (campaignId != null) 'campaign_id': campaignId,
      'title': title,
      'title_tamil': titleTa,
      'body': message,
      'body_tamil': messageTa,
      'notification_type': notificationType,
      if (relatedItemType != null) 'related_item_type': relatedItemType,
      if (relatedItemId != null) 'related_item_id': relatedItemId,
      'sent_at': sentAt.toIso8601String(),
      if (openedAt != null) 'opened_at': openedAt!.toIso8601String(),
      'status': status,
      'is_read': isRead,
      'category': category,
      if (deepLink != null) 'deep_link': deepLink,
      if (mediaUrl != null) 'media_url': mediaUrl,
    };
  }
}


typedef NotificationLogItem = NotificationItem;

class NotificationCampaign {
  final String id;
  final String title;
  final String titleTamil;
  final String titleEnglish;
  final String body;
  final String messageTamil;
  final String messageEnglish;
  final String category; // 'PANCHANGAM' | 'MUHURTHAM' | 'FESTIVAL' | 'SPECIAL_DAY' | 'REMINDER' | 'IMPORTANT_UPDATE' | 'ANNOUNCEMENT' | 'MARKETING'
  final String audienceType; // 'all_eligible' | 'opt_in_marketing' | 'active_users' | 'category_subscribers'
  final Map<String, dynamic>? targetFilter;
  final String notificationType;
  final String status; // 'DRAFT' | 'SCHEDULED' | 'SENDING' | 'SENT' | 'CANCELLED' | 'FAILED'
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String? deepLink;
  final String? mediaReference;
  final String? idempotencyKey;
  final int totalTargeted;
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalFailed;
  final int totalSkipped;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationCampaign({
    required this.id,
    required this.title,
    required this.titleTamil,
    required this.titleEnglish,
    required this.body,
    required this.messageTamil,
    required this.messageEnglish,
    required this.category,
    required this.audienceType,
    this.targetFilter,
    this.notificationType = 'campaign',
    this.status = 'DRAFT',
    this.scheduledAt,
    this.sentAt,
    this.deepLink,
    this.mediaReference,
    this.idempotencyKey,
    this.totalTargeted = 0,
    this.totalSent = 0,
    this.totalDelivered = 0,
    this.totalOpened = 0,
    this.totalFailed = 0,
    this.totalSkipped = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationCampaign.fromJson(Map<String, dynamic> json) {
    return NotificationCampaign(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['title_english'] as String? ?? '',
      titleTamil: json['title_tamil'] as String? ?? '',
      titleEnglish: json['title_english'] as String? ?? '',
      body: json['body'] as String? ?? json['message_english'] as String? ?? '',
      messageTamil: json['message_tamil'] as String? ?? '',
      messageEnglish: json['message_english'] as String? ?? '',
      category: json['category'] as String? ?? 'MARKETING',
      audienceType: json['audience_type'] as String? ?? 'all_eligible',
      targetFilter: json['target_filter'] as Map<String, dynamic>?,
      notificationType: json['notification_type'] as String? ?? 'campaign',
      status: json['status'] as String? ?? 'DRAFT',
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      deepLink: json['deep_link'] as String?,
      mediaReference: json['media_reference'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      totalTargeted: json['total_targeted'] as int? ?? 0,
      totalSent: json['total_sent'] as int? ?? 0,
      totalDelivered: json['total_delivered'] as int? ?? 0,
      totalOpened: json['total_opened'] as int? ?? 0,
      totalFailed: json['total_failed'] as int? ?? 0,
      totalSkipped: json['total_skipped'] as int? ?? 0,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_tamil': titleTamil,
      'title_english': titleEnglish,
      'body': body,
      'message_tamil': messageTamil,
      'message_english': messageEnglish,
      'category': category,
      'audience_type': audienceType,
      if (targetFilter != null) 'target_filter': targetFilter,
      'notification_type': notificationType,
      'status': status,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
      if (deepLink != null) 'deep_link': deepLink,
      if (mediaReference != null) 'media_reference': mediaReference,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      'total_targeted': totalTargeted,
      'total_sent': totalSent,
      'total_delivered': totalDelivered,
      'total_opened': totalOpened,
      'total_failed': totalFailed,
      'total_skipped': totalSkipped,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationCampaign copyWith({
    String? id,
    String? title,
    String? titleTamil,
    String? titleEnglish,
    String? body,
    String? messageTamil,
    String? messageEnglish,
    String? category,
    String? audienceType,
    Map<String, dynamic>? targetFilter,
    String? notificationType,
    String? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? deepLink,
    String? mediaReference,
    String? idempotencyKey,
    int? totalTargeted,
    int? totalSent,
    int? totalDelivered,
    int? totalOpened,
    int? totalFailed,
    int? totalSkipped,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationCampaign(
      id: id ?? this.id,
      title: title ?? this.title,
      titleTamil: titleTamil ?? this.titleTamil,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      body: body ?? this.body,
      messageTamil: messageTamil ?? this.messageTamil,
      messageEnglish: messageEnglish ?? this.messageEnglish,
      category: category ?? this.category,
      audienceType: audienceType ?? this.audienceType,
      targetFilter: targetFilter ?? this.targetFilter,
      notificationType: notificationType ?? this.notificationType,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      deepLink: deepLink ?? this.deepLink,
      mediaReference: mediaReference ?? this.mediaReference,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      totalTargeted: totalTargeted ?? this.totalTargeted,
      totalSent: totalSent ?? this.totalSent,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      totalOpened: totalOpened ?? this.totalOpened,
      totalFailed: totalFailed ?? this.totalFailed,
      totalSkipped: totalSkipped ?? this.totalSkipped,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CampaignDeliveryAnalytics {
  final int totalCampaigns;
  final int draftCampaigns;
  final int scheduledCampaigns;
  final int sentCampaigns;
  final int failedCampaigns;
  final int cancelledCampaigns;
  final int totalNotificationsSent;
  final int totalNotificationsDelivered;
  final int totalNotificationsOpened;
  final double deliveryRatePercentage;
  final double openRatePercentage;

  CampaignDeliveryAnalytics({
    required this.totalCampaigns,
    required this.draftCampaigns,
    required this.scheduledCampaigns,
    required this.sentCampaigns,
    required this.failedCampaigns,
    required this.cancelledCampaigns,
    required this.totalNotificationsSent,
    required this.totalNotificationsDelivered,
    required this.totalNotificationsOpened,
    required this.deliveryRatePercentage,
    required this.openRatePercentage,
  });

  factory CampaignDeliveryAnalytics.empty() {
    return CampaignDeliveryAnalytics(
      totalCampaigns: 0,
      draftCampaigns: 0,
      scheduledCampaigns: 0,
      sentCampaigns: 0,
      failedCampaigns: 0,
      cancelledCampaigns: 0,
      totalNotificationsSent: 0,
      totalNotificationsDelivered: 0,
      totalNotificationsOpened: 0,
      deliveryRatePercentage: 0.0,
      openRatePercentage: 0.0,
    );
  }
}

enum SavedItemType {
  all,
  panchangam,
  muhurtham,
  specialDay,
  festival;

  String toDbString() {
    switch (this) {
      case SavedItemType.panchangam:
        return 'panchangam';
      case SavedItemType.muhurtham:
        return 'muhurtham';
      case SavedItemType.specialDay:
        return 'special_day';
      case SavedItemType.festival:
        return 'festival';
      case SavedItemType.all:
        return 'all';
    }
  }

  static SavedItemType fromDbString(String str) {
    switch (str.toLowerCase()) {
      case 'panchangam':
        return SavedItemType.panchangam;
      case 'muhurtham':
        return SavedItemType.muhurtham;
      case 'special_day':
      case 'specialday':
      case 'day':
        return SavedItemType.specialDay;
      case 'festival':
        return SavedItemType.festival;
      default:
        return SavedItemType.panchangam;
    }
  }

  String label(bool isTamil) {
    switch (this) {
      case SavedItemType.all:
        return isTamil ? 'அனைத்தும்' : 'All';
      case SavedItemType.panchangam:
        return isTamil ? 'பஞ்சாங்கம்' : 'Panchangam';
      case SavedItemType.muhurtham:
        return isTamil ? 'முகூர்த்தம்' : 'Muhurtham';
      case SavedItemType.specialDay:
        return isTamil ? 'சிறப்பு நாட்கள்' : 'Special Days';
      case SavedItemType.festival:
        return isTamil ? 'பண்டிகைகள்' : 'Festivals';
    }
  }
}

class SavedItem {
  final String id;
  final String userId;
  final String itemType; // 'muhurtham' | 'panchangam' | 'special_day' | 'festival'
  final String itemId;
  final DateTime savedAt;
  
  // Display metadata for rich SavedItemCard rendering without extra async fetches
  final String title;
  final String titleTa;
  final String subtitle;
  final String subtitleTa;
  final DateTime? date;
  final String tamilDateStr;
  final String category;
  final String categoryTa;
  final String? imageUrl;

  SavedItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    required this.savedAt,
    this.title = '',
    this.titleTa = '',
    this.subtitle = '',
    this.subtitleTa = '',
    this.date,
    this.tamilDateStr = '',
    this.category = '',
    this.categoryTa = '',
    this.imageUrl,
  });

  SavedItemType get typeEnum => SavedItemType.fromDbString(itemType);

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemType: json['item_type'] as String,
      itemId: json['item_id'] as String,
      savedAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : (json['saved_at'] != null ? DateTime.parse(json['saved_at'] as String) : DateTime.now()),
      title: json['title'] as String? ?? '',
      titleTa: json['title_ta'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      subtitleTa: json['subtitle_ta'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      tamilDateStr: json['tamil_date_str'] as String? ?? '',
      category: json['category'] as String? ?? '',
      categoryTa: json['category_ta'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_type': itemType,
      'item_id': itemId,
      'created_at': savedAt.toIso8601String(),
      'title': title,
      'title_ta': titleTa,
      'subtitle': subtitle,
      'subtitle_ta': subtitleTa,
      'date': date?.toIso8601String(),
      'tamil_date_str': tamilDateStr,
      'category': category,
      'category_ta': categoryTa,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

enum ReminderFilter {
  upcoming,
  past,
  all;

  String label(bool isTamil) {
    switch (this) {
      case ReminderFilter.upcoming:
        return isTamil ? 'வரவிருக்கும்' : 'Upcoming';
      case ReminderFilter.past:
        return isTamil ? 'முடிந்தவை' : 'Past';
      case ReminderFilter.all:
        return isTamil ? 'அனைத்தும்' : 'All';
    }
  }
}

class Reminder {
  final String id;
  final String userId;
  final String itemType; // 'muhurtham' | 'panchangam' | 'special_day' | 'festival' | 'event'
  final String itemId;
  final String title;
  final String titleTa;
  final String subtitle;
  final String subtitleTa;
  final DateTime eventDate;
  final String reminderTime; // e.g., "08:00 PM"
  final DateTime reminderAt;
  final String reminderType; // '1_day_before' | 'morning_6am' | '1_hour_before' | 'custom'
  final bool isSet; // is_enabled in DB
  final String status; // 'active' | 'triggered' | 'dismissed'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Reminder({
    required this.id,
    required this.userId,
    this.itemType = 'event',
    this.itemId = '',
    required this.title,
    this.titleTa = '',
    this.subtitle = '',
    this.subtitleTa = '',
    required this.eventDate,
    required this.reminderTime,
    DateTime? reminderAt,
    this.reminderType = '1_day_before',
    required this.isSet,
    this.status = 'active',
    DateTime? createdAt,
    this.updatedAt,
  })  : reminderAt = reminderAt ?? eventDate,
        createdAt = createdAt ?? DateTime.now();

  SavedItemType get itemTypeEnum => SavedItemType.fromDbString(itemType);

  bool get isPast => reminderAt.isBefore(DateTime.now());

  Reminder copyWith({
    String? id,
    String? userId,
    String? itemType,
    String? itemId,
    String? title,
    String? titleTa,
    String? subtitle,
    String? subtitleTa,
    DateTime? eventDate,
    String? reminderTime,
    DateTime? reminderAt,
    String? reminderType,
    bool? isSet,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      titleTa: titleTa ?? this.titleTa,
      subtitle: subtitle ?? this.subtitle,
      subtitleTa: subtitleTa ?? this.subtitleTa,
      eventDate: eventDate ?? this.eventDate,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderType: reminderType ?? this.reminderType,
      isSet: isSet ?? this.isSet,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final eventD = json['event_date'] != null 
        ? DateTime.parse(json['event_date'] as String) 
        : (json['reminder_time'] != null ? DateTime.parse(json['reminder_time'] as String) : DateTime.now());
    final remAt = json['reminder_at'] != null 
        ? DateTime.parse(json['reminder_at'] as String) 
        : (json['reminder_time'] != null ? DateTime.tryParse(json['reminder_time'] as String) ?? eventD : eventD);

    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemType: json['item_type'] as String? ?? 'event',
      itemId: json['item_id'] as String? ?? '',
      title: json['title'] as String? ?? json['name_english'] as String? ?? 'Reminder',
      titleTa: json['title_ta'] as String? ?? json['name_tamil'] as String? ?? 'நினைவூட்டல்',
      subtitle: json['subtitle'] as String? ?? '',
      subtitleTa: json['subtitle_ta'] as String? ?? '',
      eventDate: eventD,
      reminderTime: json['reminder_time_str'] as String? ?? (json['reminder_time'] is String ? json['reminder_time'] as String : '08:00 PM'),
      reminderAt: remAt,
      reminderType: json['reminder_type'] as String? ?? '1_day_before',
      isSet: json['is_set'] as bool? ?? json['is_enabled'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_type': itemType,
      'item_id': itemId,
      'title': title,
      'title_ta': titleTa,
      'subtitle': subtitle,
      'subtitle_ta': subtitleTa,
      'event_date': eventDate.toIso8601String(),
      'reminder_time': reminderAt.toIso8601String(),
      'reminder_type': reminderType,
      'is_enabled': isSet,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Admin Dashboard Real-Time Metrics Model
/// Strictly reflects verified database aggregations or clean fallback (no fake data).
class AdminDashboardMetrics {
  final int totalUsers;
  final int activeUsers;
  final int upcomingMuhurtham;
  final int upcomingFestivals;
  final int pendingContent;
  final int scheduledNotifications;
  final DateTime lastRefreshedAt;
  final bool isLive;

  AdminDashboardMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.upcomingMuhurtham,
    required this.upcomingFestivals,
    required this.pendingContent,
    required this.scheduledNotifications,
    required this.lastRefreshedAt,
    this.isLive = true,
  });

  factory AdminDashboardMetrics.empty() {
    return AdminDashboardMetrics(
      totalUsers: 0,
      activeUsers: 0,
      upcomingMuhurtham: 0,
      upcomingFestivals: 0,
      pendingContent: 0,
      scheduledNotifications: 0,
      lastRefreshedAt: DateTime.now(),
      isLive: false,
    );
  }

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return AdminDashboardMetrics(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      upcomingMuhurtham: json['upcoming_muhurtham'] as int? ?? 0,
      upcomingFestivals: json['upcoming_festivals'] as int? ?? 0,
      pendingContent: json['pending_content'] as int? ?? 0,
      scheduledNotifications: json['scheduled_notifications'] as int? ?? 0,
      lastRefreshedAt: json['last_refreshed_at'] != null
          ? DateTime.parse(json['last_refreshed_at'] as String)
          : DateTime.now(),
      isLive: json['is_live'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'upcoming_muhurtham': upcomingMuhurtham,
      'upcoming_festivals': upcomingFestivals,
      'pending_content': pendingContent,
      'scheduled_notifications': scheduledNotifications,
      'last_refreshed_at': lastRefreshedAt.toIso8601String(),
      'is_live': isLive,
    };
  }
}

/// Content Status Workflow States
enum ContentWorkflowStatus {
  draft,
  scheduled,
  published,
  archived,
}

extension ContentWorkflowStatusExtension on ContentWorkflowStatus {
  String get value {
    switch (this) {
      case ContentWorkflowStatus.draft:
        return 'DRAFT';
      case ContentWorkflowStatus.scheduled:
        return 'SCHEDULED';
      case ContentWorkflowStatus.published:
        return 'PUBLISHED';
      case ContentWorkflowStatus.archived:
        return 'ARCHIVED';
    }
  }

  static ContentWorkflowStatus fromString(String str) {
    switch (str.toUpperCase()) {
      case 'DRAFT':
        return ContentWorkflowStatus.draft;
      case 'SCHEDULED':
        return ContentWorkflowStatus.scheduled;
      case 'PUBLISHED':
        return ContentWorkflowStatus.published;
      case 'ARCHIVED':
      case 'EXPIRED':
      default:
        return ContentWorkflowStatus.archived;
    }
  }
}

/// Admin Content & Poster Item Model
class ContentItem {
  final String id;
  final String titleTamil;
  final String titleEnglish;
  final String? descriptionTamil;
  final String? descriptionEnglish;
  final String category; // 'FESTIVAL' | 'SPECIAL_DAY' | 'MUHURTHAM' | 'PANCHANGAM' | 'ANNOUNCEMENT' | 'INFORMATION' | 'POSTER'
  final String status; // 'DRAFT' | 'SCHEDULED' | 'PUBLISHED' | 'ARCHIVED'
  final DateTime? publishAt;
  final DateTime? expireAt;
  final int priority;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ContentMedia> mediaList;

  ContentItem({
    required this.id,
    required this.titleTamil,
    required this.titleEnglish,
    this.descriptionTamil,
    this.descriptionEnglish,
    required this.category,
    this.status = 'DRAFT',
    this.publishAt,
    this.expireAt,
    this.priority = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.mediaList = const [],
  });

  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
  bool get isScheduled => status.toUpperCase() == 'SCHEDULED';
  bool get isDraft => status.toUpperCase() == 'DRAFT';
  bool get isArchived => status.toUpperCase() == 'ARCHIVED';

  String localizedTitle(String lang) => lang == 'ta' ? titleTamil : titleEnglish;
  String? localizedDescription(String lang) => lang == 'ta' ? descriptionTamil : descriptionEnglish;

  ContentItem copyWith({
    String? id,
    String? titleTamil,
    String? titleEnglish,
    String? descriptionTamil,
    String? descriptionEnglish,
    String? category,
    String? status,
    DateTime? publishAt,
    DateTime? expireAt,
    int? priority,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ContentMedia>? mediaList,
  }) {
    return ContentItem(
      id: id ?? this.id,
      titleTamil: titleTamil ?? this.titleTamil,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      descriptionTamil: descriptionTamil ?? this.descriptionTamil,
      descriptionEnglish: descriptionEnglish ?? this.descriptionEnglish,
      category: category ?? this.category,
      status: status ?? this.status,
      publishAt: publishAt ?? this.publishAt,
      expireAt: expireAt ?? this.expireAt,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaList: mediaList ?? this.mediaList,
    );
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['content_media'] as List<dynamic>?;
    final List<ContentMedia> parsedMedia = mediaJson != null
        ? mediaJson.map((m) => ContentMedia.fromJson(m as Map<String, dynamic>)).toList()
        : [];

    return ContentItem(
      id: json['id'] as String,
      titleTamil: json['title_tamil'] as String? ?? '',
      titleEnglish: json['title_english'] as String? ?? '',
      descriptionTamil: json['description_tamil'] as String?,
      descriptionEnglish: json['description_english'] as String?,
      category: json['category'] as String? ?? 'POSTER',
      status: json['status'] as String? ?? 'DRAFT',
      publishAt: json['publish_at'] != null ? DateTime.tryParse(json['publish_at'] as String) : null,
      expireAt: json['expire_at'] != null ? DateTime.tryParse(json['expire_at'] as String) : null,
      priority: json['priority'] as int? ?? 0,
      createdBy: json['created_by'] as String? ?? 'admin',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      mediaList: parsedMedia,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_tamil': titleTamil,
      'title_english': titleEnglish,
      'description_tamil': descriptionTamil,
      'description_english': descriptionEnglish,
      'category': category,
      'status': status,
      'publish_at': publishAt?.toIso8601String(),
      'expire_at': expireAt?.toIso8601String(),
      'priority': priority,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Content Media Attachment Model
class ContentMedia {
  final String id;
  final String contentId;
  final String mediaType; // 'IMAGE' | 'POSTER' | 'BANNER' | 'ICON'
  final String mediaUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentMedia({
    required this.id,
    required this.contentId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentMedia.fromJson(Map<String, dynamic> json) {
    return ContentMedia(
      id: json['id'] as String,
      contentId: json['content_id'] as String,
      mediaType: json['media_type'] as String? ?? 'IMAGE',
      mediaUrl: json['media_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Admin Media Library Asset Model
class MediaAsset {
  final String id;
  final String fileName;
  final int fileSize; // bytes
  final String mimeType;
  final String storagePath;
  final String publicUrl;
  final String? thumbnailUrl;
  final String mediaType; // 'IMAGE' | 'POSTER' | 'BANNER' | 'ICON' | 'DOCUMENT'
  final String? relatedContentId;
  final String status; // 'ACTIVE' | 'ARCHIVED' | 'DELETED'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaAsset({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.publicUrl,
    this.thumbnailUrl,
    this.mediaType = 'IMAGE',
    this.relatedContentId,
    this.status = 'ACTIVE',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      fileName: json['file_name'] as String? ?? 'media_asset',
      fileSize: json['file_size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? 'image/jpeg',
      storagePath: json['storage_path'] as String? ?? '',
      publicUrl: json['public_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaType: json['media_type'] as String? ?? 'IMAGE',
      relatedContentId: json['related_content_id'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      createdBy: json['created_by'] as String? ?? 'admin',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType,
      'related_content_id': relatedContentId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Admin Audit Log Model (Strictly confidential)
class AdminAuditLog {
  final String id;
  final String adminId;
  final String? adminEmail;
  final String action; // 'CREATE' | 'UPDATE' | 'PUBLISH' | 'SCHEDULE' | 'ARCHIVE' | 'DELETE' | 'RESTORE' | 'MEDIA_UPLOAD'
  final String module; // 'CALENDAR' | 'PANCHANGAM' | 'MUHURTHAM' | 'SPECIAL_DAYS' | 'FESTIVALS' | 'CONTENT' | 'MEDIA'
  final String recordId;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  AdminAuditLog({
    required this.id,
    required this.adminId,
    this.adminEmail,
    required this.action,
    required this.module,
    required this.recordId,
    this.previousState,
    this.newState,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      adminEmail: json['admin_email'] as String?,
      action: json['action'] as String,
      module: json['module'] as String,
      recordId: json['record_id'] as String,
      previousState: json['previous_state'] as Map<String, dynamic>?,
      newState: json['new_state'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'admin_email': adminEmail,
      'action': action,
      'module': module,
      'record_id': recordId,
      'previous_state': previousState,
      'new_state': newState,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Bulk Import Preview & Validation Summary
class BulkImportResult {
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int duplicateRows;
  final List<String> errors;
  final List<Map<String, dynamic>> previewRecords;
  final bool isCommitted;

  BulkImportResult({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.duplicateRows,
    required this.errors,
    required this.previewRecords,
    this.isCommitted = false,
  });

  factory BulkImportResult.empty() {
    return BulkImportResult(
      totalRows: 0,
      validRows: 0,
      invalidRows: 0,
      duplicateRows: 0,
      errors: [],
      previewRecords: [],
    );
  }
}

/// Personal Important Date Model (Strictly Private to Owner)
class ImportantDateItem {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String date;
  final String eventType; // BIRTHDAY, ANNIVERSARY, WEDDING, FUNCTION, FAMILY_EVENT, CUSTOM
  final bool reminderEnabled;
  final String reminderTime;
  final String repeatType; // NONE, YEARLY, MONTHLY
  final DateTime createdAt;
  final DateTime updatedAt;

  ImportantDateItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    this.eventType = 'CUSTOM',
    this.reminderEnabled = true,
    this.reminderTime = '09:00 AM',
    this.repeatType = 'NONE',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImportantDateItem.fromJson(Map<String, dynamic> json) {
    return ImportantDateItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Personal Event',
      description: json['description'] as String?,
      date: json['date'] as String,
      eventType: json['event_type'] as String? ?? 'CUSTOM',
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String? ?? '09:00 AM',
      repeatType: json['repeat_type'] as String? ?? 'NONE',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'date': date,
      'event_type': eventType,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime,
      'repeat_type': repeatType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Personal Date Note Model (Strictly Private to Owner)
class PersonalNoteItem {
  final String id;
  final String userId;
  final String date;
  final String title;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalNoteItem({
    required this.id,
    required this.userId,
    required this.date,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalNoteItem.fromJson(Map<String, dynamic> json) {
    return PersonalNoteItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'title': title,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// User Saved Location Model
class UserLocationItem {
  final String id;
  final String userId;
  final String name;
  final String city;
  final String? state;
  final String country;
  final double? latitude;
  final double? longitude;
  final String timezone;
  final bool isDefault;
  final DateTime createdAt;

  UserLocationItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.city,
    this.state,
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.timezone = 'Asia/Kolkata',
    this.isDefault = false,
    required this.createdAt,
  });

  factory UserLocationItem.fromJson(Map<String, dynamic> json) {
    return UserLocationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? json['city'] as String? ?? 'Location',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'India',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Global Search Result Types
enum SearchResultType {
  panchangam,
  festival,
  specialDay,
  muhurtham,
  calendarDate,
  contentPoster,
  importantDate,
  savedItem,
}

/// Centralized Global Search Result Model
class SearchResult {
  final String id;
  final String titleTamil;
  final String titleEnglish;
  final String? subtitleTamil;
  final String? subtitleEnglish;
  final String? date;
  final SearchResultType type;
  final String category;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  SearchResult({
    required this.id,
    required this.titleTamil,
    required this.titleEnglish,
    this.subtitleTamil,
    this.subtitleEnglish,
    this.date,
    required this.type,
    required this.category,
    this.imageUrl,
    this.metadata,
  });
}

/// Today At A Glance Summary Model
class TodaySummary {
  final String date;
  final String tamilDate;
  final String tamilMonth;
  final String tamilYear;
  final String weekdayTamil;
  final String weekdayEnglish;
  final String tithi;
  final String nakshatra;
  final String? nallaNeram;
  final String? rahuKalam;
  final String? yamagandam;
  final String? kuligai;
  final String? sunrise;
  final String? sunset;
  final List<String> festivals;
  final List<String> specialDays;
  final bool hasMuhurtham;
  final String? muhurthamDetails;

  TodaySummary({
    required this.date,
    required this.tamilDate,
    required this.tamilMonth,
    required this.tamilYear,
    required this.weekdayTamil,
    required this.weekdayEnglish,
    required this.tithi,
    required this.nakshatra,
    this.nallaNeram,
    this.rahuKalam,
    this.yamagandam,
    this.kuligai,
    this.sunrise,
    this.sunset,
    this.festivals = const [],
    this.specialDays = const [],
    this.hasMuhurtham = false,
    this.muhurthamDetails,
  });
}
