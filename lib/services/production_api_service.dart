import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tnt_models.dart';
import 'supabase_service.dart';

class SupabaseApiService implements ITNTApiService {
  final SupabaseService _db = SupabaseService();

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    if (!_db.isInitialized) return null;
    final user = _db.client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await _db.client.from('user_profiles').select().eq('id', user.id).maybeSingle();
      if (res == null) return null;
      return UserProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(String fullName) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final user = _db.client.auth.currentUser;
    if (user == null) throw TNTException('User not authenticated');
    
    final res = await _db.client.from('user_profiles').update({'full_name': fullName}).eq('id', user.id).select().single();
    return UserProfile.fromJson(res);
  }

  @override
  Future<UserPreferences> getUserPreferences() async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final user = _db.client.auth.currentUser;
    if (user == null) throw TNTException('User not authenticated');

    final res = await _db.client.from('user_preferences').select().eq('user_id', user.id).maybeSingle();
    if (res == null) return UserPreferences(userId: user.id, language: 'ta', location: 'Chennai', notificationsEnabled: true);
    return UserPreferences.fromJson(res);
  }

  @override
  Future<void> saveUserPreferences(UserPreferences prefs) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final user = _db.client.auth.currentUser;
    if (user == null) throw TNTException('User not authenticated');

    await _db.client.from('user_preferences').upsert({
      'user_id': user.id,
      ...prefs.toJson(),
    });
  }

  @override
  Future<CalendarDay> getCalendarDay(DateTime date) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _db.client.from('calendar_days').select().eq('gregorian_date', dateStr).maybeSingle();
    
    if (res == null) throw TNTException('No calendar data available for this date');
    
    return CalendarDay(
      gregorianDate: DateTime.parse(res['gregorian_date']),
      tamilMonth: res['tamil_month'],
      tamilYear: res['tamil_year'],
      tamilDay: res['tamil_day'],
      tamilDateStr: res['tamil_date_str'],
      tithi: res['tithi'],
      tithiTa: res['tithi_ta'],
      nakshatra: res['nakshatra'],
      nakshatraTa: res['nakshatra_ta'],
      isAuspicious: res['is_auspicious'] ?? false,
    );
  }

  @override
  Future<PanchangamEntry> getPanchangam(DateTime date) async {
    // Relies on local calculation fallback as established in Phase 3
    throw TNTException('Panchangam should use NavamshaPanchangService local engine calculation fallback');
  }

  @override
  Future<List<TimingEntry>> getImportantTimings(DateTime date) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final res = await _db.client.from('important_timings').select().eq('date', dateStr);
    
    return (res as List).map((e) => TimingEntry(
      name: e['name'],
      nameTa: e['name_ta'],
      startTime: e['start_time'],
      endTime: e['end_time'],
      isAuspicious: e['is_auspicious'] ?? false,
    )).toList();
  }

  @override
  Future<List<MuhurthamDate>> getMarriageMuhurthams(int year, int month) async {
    return getMuhurthamDates(year: year, month: month, category: 'Marriage');
  }

  @override
  Future<List<MuhurthamDate>> getMuhurthamDates({
    required int year,
    required int month,
    String? category,
    String? phase,
    String? location,
  }) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final endStr = month == 12 ? '${year+1}-01-01' : '$year-${(month+1).toString().padLeft(2, '0')}-01';

    var query = _db.client.from('muhurtham_dates').select('*, muhurtham_timings(*)').gte('date', startStr).lt('date', endStr);
    if (category != null) {
      query = query.eq('category', category);
    }
    
    final res = await query.order('date', ascending: true);
    
    return (res as List).map((e) {
      final t = (e['muhurtham_timings'] as List?) ?? [];
      return MuhurthamDate(
        id: e['id'],
        date: DateTime.parse(e['date']),
        tamilDateStr: e['tamil_date_str'] ?? '',
        tamilMonth: e['tamil_month'] ?? '',
        tamilYear: e['tamil_year'] ?? '',
        dayOfWeekEn: e['day_of_week_en'] ?? '',
        dayOfWeekTa: e['day_of_week_ta'] ?? '',
        startTime: e['start_time'] ?? '',
        endTime: e['end_time'] ?? '',
        duration: e['duration'] ?? '',
        isValarthirai: e['is_valarthirai'] ?? false,
        category: e['category'],
        categoryTa: e['category_ta'] ?? '',
        description: e['description'] ?? '',
        descriptionTa: e['description_ta'] ?? '',
        nakshatra: e['nakshatra'] ?? '',
        nakshatraTa: e['nakshatra_ta'] ?? '',
        nakshatraTime: e['nakshatra_time'] ?? '',
        tithi: e['tithi'] ?? '',
        tithiTa: e['tithi_ta'] ?? '',
        yoga: e['yoga'] ?? '',
        yogaTa: e['yoga_ta'] ?? '',
        karana: e['karana'] ?? '',
        karanaTa: e['karana_ta'] ?? '',
        lagnam: e['lagnam'] ?? '',
        lagnamTa: e['lagnam_ta'] ?? '',
        subhaHorai: e['subha_horai'] ?? '',
        subhaHoraiTa: e['subha_horai_ta'] ?? '',
        rahuKalam: e['rahu_kalam'] ?? '',
        yamagandam: e['yamagandam'] ?? '',
        kuligai: e['kuligai'] ?? '',
        approvedStatus: e['approved_status'] ?? '',
        notes: e['notes'] ?? '',
        notesTa: e['notes_ta'] ?? '',
        location: e['location'] ?? 'Chennai',
        timingsCount: t.length,
        timings: t.map((te) => MuhurthamTimingItem(
          startTime: te['start_time'],
          endTime: te['end_time'],
          duration: te['duration'] ?? '',
          lagnam: te['lagnam'] ?? '',
          lagnamTa: te['lagnam_ta'] ?? '',
          nakshatra: te['nakshatra'] ?? '',
          nakshatraTa: te['nakshatra_ta'] ?? '',
          subhaHorai: te['subha_horai'] ?? '',
          subhaHoraiTa: te['subha_horai_ta'] ?? '',
          description: te['description'] ?? '',
          descriptionTa: te['description_ta'] ?? '',
          isPrime: te['is_prime'] ?? false,
        )).toList(),
      );
    }).toList();
  }

  @override
  Future<List<String>> getApprovedMuhurthamCategories() async {
    return ['Marriage', 'Housewarming', 'Engagement', 'Business']; // Minimal static config
  }

  @override
  Future<List<String>> getApprovedSpecialDayCategories() async {
    return ['Amavasai', 'Pournami', 'Pradosham', 'Karthigai'];
  }

  @override
  Future<List<String>> getApprovedFestivalCategories() async {
    return ['Hindu', 'Public Holiday', 'Bank Holiday'];
  }

  @override
  Future<List<SpecialDay>> getSpecialDays(int year, int month, {String? category}) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final endStr = month == 12 ? '${year+1}-01-01' : '$year-${(month+1).toString().padLeft(2, '0')}-01';
    
    var query = _db.client.from('special_days').select().gte('date', startStr).lt('date', endStr);
    if (category != null) {
      query = query.eq('category', category);
    }
    
    final res = await query.order('date', ascending: true);
    
        return (res as List).map((e) => SpecialDay(
      id: e['id'],
      date: DateTime.parse(e['date']),
      title: e['name'] ?? '',
      titleTa: e['name_ta'] ?? e['name'] ?? '',
      category: e['category'] ?? '',
      categoryTa: e['category_ta'] ?? e['category'] ?? '',
      isHoliday: false,
      description: e['significance'] ?? '',
      descriptionTa: e['significance_ta'] ?? '',
    )).toList();
  }

  @override
  Future<List<Festival>> getFestivals(int year, int month, {String? category}) async {
    if (!_db.isInitialized) throw TNTException('Supabase not initialized');
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final endStr = month == 12 ? '${year+1}-01-01' : '$year-${(month+1).toString().padLeft(2, '0')}-01';
    
    var query = _db.client.from('festivals').select().gte('date', startStr).lt('date', endStr);
    if (category != null) {
      query = query.eq('category', category);
    }
    
    final res = await query.order('date', ascending: true);
    
        return (res as List).map((e) => Festival(
      id: e['id'],
      date: DateTime.parse(e['date']),
      name: e['name'] ?? '',
      nameTa: e['name_ta'] ?? e['name'] ?? '',
      type: e['category'] ?? 'hindu',
      description: e['description'] ?? '',
      descriptionTa: e['description_ta'] ?? '',
      category: e['category'] ?? '',
      categoryTa: e['category_ta'] ?? e['category'] ?? '',
    )).toList();
  }

  @override
  Future<List<SavedItem>> getSavedItems() async {
    throw TNTException('Use SavedItemsRepository');
  }

  @override
  Future<void> toggleSaveItem(String itemType, String itemId) async {
    throw TNTException('Use SavedItemsRepository');
  }

  @override
  Future<List<Reminder>> getReminders() async {
    throw TNTException('Use ReminderRepository');
  }

  @override
  Future<Reminder> setReminder(String title, DateTime eventDate, String reminderTime) async {
    throw TNTException('Use ReminderRepository');
  }

  @override
  Future<List<NotificationItem>> getNotifications() async {
    throw TNTException('Use NotificationService');
  }

  @override
  Future<AdminDashboardMetrics> getAdminDashboardMetrics() async {
    throw TNTException('Use AdminAnalyticsRepository');
  }
}
