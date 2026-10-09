import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tnt_models.dart';
import '../services/supabase_service.dart';
import 'panchang_repository.dart';
import 'location_repository.dart';
import '../core/network/tnt_resilience.dart';

// =====================================================================
// AUTHENTICATION REPOSITORY
// =====================================================================
enum AuthState { loading, authenticated, unauthenticated, error }

class AuthRepository {
  final SupabaseService _db = SupabaseService();

  /// Reactive stream to listen to Supabase authentication state
  Stream<AuthState> get authStateChanges {
    if (!_db.isInitialized) {
      return Stream.value(AuthState.unauthenticated);
    }
    return _db.client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session != null) {
        return AuthState.authenticated;
      }
      return AuthState.unauthenticated;
    });
  }

  /// Check current active user session
  Future<bool> isSessionActive() async {
    if (!_db.isInitialized) return false;
    final session = _db.client.auth.currentSession;
    return session != null && !session.isExpired;
  }

  /// Sign Up with default USER role triggered securely on Postgres
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String language = 'ta',
  }) async {
    if (!_db.isInitialized) {
      throw TNTException('Supabase not initialized.', 'CONFIG_ERROR');
    }
    try {
      final response = await _db.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'language': language,
        },
      );
      return response;
    } on AuthException catch (e) {
      throw TNTException(e.message, 'AUTH_SIGNUP_FAILED');
    } catch (e) {
      throw TNTException('Unexpected signup failure: $e', 'UNEXPECTED');
    }
  }

  /// Sign In with Email/Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!_db.isInitialized) {
      throw TNTException('Supabase not initialized.', 'CONFIG_ERROR');
    }
    try {
      final response = await _db.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw TNTException(e.message, 'AUTH_SIGNIN_FAILED');
    } catch (e) {
      throw TNTException('Unexpected sign-in failure: $e', 'UNEXPECTED');
    }
  }

  /// Sign In with Google OAuth Provider
  Future<bool> signInWithGoogle() async {
    if (!_db.isInitialized) {
      throw StateError("Database not initialized");
    }
    try {
      return await _db.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'tntcalendar://login-callback/',
      );
    } catch (e) {
      throw TNTException('Google OAuth failed: $e', 'GOOGLE_AUTH_FAILED');
    }
  }

  /// Resend confirmation email
  Future<void> resendVerificationEmail(String email) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw TNTException('Failed to resend confirmation email: $e', 'RESEND_FAILED');
    }
  }

  /// Secure Sign Out
  Future<void> signOut() async {
    if (!_db.isInitialized) return;
    try {
      await _db.client.auth.signOut();
    } catch (e) {
      throw TNTException('Sign out execution failed: $e', 'AUTH_SIGNOUT_FAILED');
    }
  }
}

// =====================================================================
// USER PROFILE REPOSITORY
// =====================================================================
class ProfileRepository {
  final SupabaseService _db = SupabaseService();

  Future<UserProfile?> fetchUserProfile(String userId) async {
    if (!_db.isInitialized) return null;
    try {
      final data = await _db.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw TNTException('Profile fetching failed: $e', 'PROFILE_FETCH_FAILED');
    }
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client.from('profiles').update(profile.toJson()).eq('id', profile.id);
    } catch (e) {
      throw TNTException('Failed to upsert profile: $e', 'PROFILE_UPSERT_FAILED');
    }
  }

  Future<UserProfile> updateUserProfile(String userId, {required String fullName, String? mobile, String? city}) async {
    if (!_db.isInitialized) {
      throw TNTException('Offline state. Cannot edit profile live.', 'OFFLINE');
    }
    try {
      final data = await _db.client
          .from('profiles')
          .update({
            'full_name': fullName,
            if (mobile != null) 'phone': mobile,
            if (city != null) 'city': city,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();
      return UserProfile.fromJson(data);
    } catch (e) {
      throw TNTException('Failed to update live user profile: $e', 'PROFILE_UPDATE_FAILED');
    }
  }
}

// =====================================================================
// USER PREFERENCES REPOSITORY
// =====================================================================
class UserPreferencesRepository {
  final SupabaseService _db = SupabaseService();

  Future<UserPreferences?> fetchUserPreferences(String userId) async {
    if (!_db.isInitialized) return null;
    try {
      final data = await _db.client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserPreferences.fromJson(data);
    } catch (e) {
      throw TNTException('Preferences download failed: $e', 'PREFS_FETCH_FAILED');
    }
  }

  Future<void> savePreferences(UserPreferences prefs) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client.from('user_preferences').upsert({
        'user_id': prefs.userId,
        'language': prefs.language,
        'notifications_enabled': prefs.notificationsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw TNTException('Failed to synchronize user preferences: $e', 'PREFS_SAVE_FAILED');
    }
  }
}

// =====================================================================
// CALENDAR & PANCHANGAM REPOSITORY
// =====================================================================
class CalendarRepository {
  final SupabaseService _db = SupabaseService();
  static final Map<String, CalendarDay> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 30);

  static void invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  Future<CalendarDay?> fetchCalendarDay(DateTime date, {bool forceRefresh = false}) async {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final cachedTime = _cacheTimestamps[dateStr];
    if (!forceRefresh && cachedTime != null && DateTime.now().difference(cachedTime) < _cacheTtl) {
      final cached = _cache[dateStr];
      if (cached != null) return cached;
    }

    if (!_db.isInitialized) return null;
    try {
      final data = await TNTResilience.retry(
        operation: () => _db.client
            .from('calendar_days')
            .select()
            .eq('date', dateStr)
            .maybeSingle(),
        operationName: 'fetchCalendarDay',
      );
      if (data == null) return null;
      final day = CalendarDay.fromJson(data);
      _cache[dateStr] = day;
      _cacheTimestamps[dateStr] = DateTime.now();
      return day;
    } catch (e) {
      throw TNTException('Calendar retrieval failed: $e', 'CALENDAR_FETCH_FAILED');
    }
  }
}

class PanchangamRepository {
  final SupabaseService _db = SupabaseService();

  Future<PanchangamEntry?> fetchPanchangamEntry(String calendarDayId) async {
    if (!_db.isInitialized) return null;
    try {
      final data = await _db.client
          .from('panchangam_entries')
          .select()
          .eq('calendar_day_id', calendarDayId)
          .maybeSingle();
      if (data == null) return null;
      return PanchangamEntry.fromJson(data);
    } catch (e) {
      throw TNTException('Panchangam download failed: $e', 'PANCHANGAM_FETCH_FAILED');
    }
  }
}

// =====================================================================
// MUHURTHAM REPOSITORY
// =====================================================================
class MuhurthamRepository {
  final SupabaseService _db = SupabaseService();
  static final Map<String, List<MuhurthamDate>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  static void invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  Future<List<String>> fetchCategories() async {
    if (!_db.isInitialized) {
      return ['Marriage', 'Housewarming', 'Engagement', 'Business'];
    }
    try {
      final data = await TNTResilience.retry(
        operation: () => _db.client
            .from('muhurtham_dates')
            .select('category')
            .eq('is_published', true),
        operationName: 'fetchMuhurthamCategories',
      );
      final set = <String>{};
      for (final item in data as List) {
        if (item['category'] != null) {
          set.add(item['category'] as String);
        }
      }
      return set.isNotEmpty ? set.toList() : ['Marriage', 'Housewarming', 'Engagement', 'Business'];
    } catch (_) {
      return ['Marriage', 'Housewarming', 'Engagement', 'Business'];
    }
  }

  Future<List<MuhurthamDate>> fetchMarriageMuhurthams(int year, int month) async {
    return fetchMuhurthamDates(year: year, month: month, category: 'Marriage');
  }

  Future<List<MuhurthamDate>> fetchMuhurthamDates({
    required int year,
    required int month,
    String? category,
    String? phase,
    String? location,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$year-$month-$category-$phase-$location';
    final cachedTime = _cacheTimestamps[cacheKey];
    if (!forceRefresh && cachedTime != null && DateTime.now().difference(cachedTime) < _cacheTtl) {
      final cached = _cache[cacheKey];
      if (cached != null) return cached;
    }

    // 1. Fetch Supabase overrides/custom Muhurthams
    List<MuhurthamDate> supabaseData = [];
    if (_db.isInitialized) {
      try {
        final startDate = "$year-${month.toString().padLeft(2, '0')}-01";
        final endDate = "$year-${month.toString().padLeft(2, '0')}-31";
        
        var query = _db.client
            .from('muhurtham_dates')
            .select()
            .eq('is_published', true)
            .gte('date', startDate)
            .lte('date', endDate);

        if (category != null && category.isNotEmpty && category != 'All' && category != 'all') {
          query = query.eq('category', category);
        }
        if (phase != null && phase.isNotEmpty && phase != 'All' && phase != 'all') {
          query = query.eq('is_valarthirai', phase == 'valarpirai');
        }

        final data = await TNTResilience.retry(
          operation: () => query.order('date'),
          operationName: 'fetchMuhurthamDates',
        );
        supabaseData = (data as List).map((json) => MuhurthamDate.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Supabase Muhurtham fetch failed: $e');
      }
    }

    // 2. Fetch Navamsha API monthly data
    final panchangRepo = PanchangRepository();
    final activeLocation = UserLocationItem(id: 'default', userId: 'default', name: 'Coimbatore', city: 'Coimbatore', createdAt: DateTime.now(), latitude: 11.0168, longitude: 76.9558, timezone: '+05:30');
    final monthlyBundles = await panchangRepo.getMonthlyPanchangam(year: year, month: month, location: activeLocation, forceRefresh: forceRefresh);

    // 3. Merge: Currently Navamsha daily bundle returns `muhurthams: []` inside the model,
    // so we extract them if they exist in the future, and combine with Supabase.
    final List<MuhurthamDate> apiData = [];
    for (var bundle in monthlyBundles) {
      apiData.addAll(bundle.muhurthams);
    }

    // Merge logic: Supabase overrides take precedence if they share the same ID.
    // Otherwise, append all.
    final mergedMap = <String, MuhurthamDate>{};
    for (var apiItem in apiData) {
      mergedMap[apiItem.id] = apiItem;
    }
    for (var supItem in supabaseData) {
      mergedMap[supItem.id] = supItem; // Overrides API
    }

    final result = mergedMap.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    _cache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return result;
  }
}

// =====================================================================
// SPECIAL DAYS & FESTIVALS REPOSITORY
// =====================================================================
class SpecialDaysRepository {
  final SupabaseService _db = SupabaseService();
  static final Map<String, List<SpecialDay>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  static void invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  Future<List<String>> fetchCategories() async {
    if (!_db.isInitialized) {
      return [
        'Amavasai', 'Pournami', 'Pradosham', 'Sashti', 
        'Ekadashi', 'Krithigai', 'Chaturthi', 'Sankatahara Chaturthi',
        'Ashtami', 'Navami', 'Sankranti', 'Special Day'
      ];
    }
    try {
      final data = await TNTResilience.retry(
        operation: () => _db.client
            .from('special_days')
            .select('category')
            .eq('is_published', true),
        operationName: 'fetchSpecialDayCategories',
      );
      final set = <String>{};
      for (final item in data as List) {
        if (item['category'] != null) {
          set.add(item['category'] as String);
        }
      }
      return set.isNotEmpty ? set.toList() : [
        'Amavasai', 'Pournami', 'Pradosham', 'Sashti', 
        'Ekadashi', 'Krithigai', 'Chaturthi', 'Sankatahara Chaturthi'
      ];
    } catch (_) {
      return [
        'Amavasai', 'Pournami', 'Pradosham', 'Sashti', 
        'Ekadashi', 'Krithigai', 'Chaturthi', 'Sankatahara Chaturthi'
      ];
    }
  }

  Future<List<SpecialDay>> fetchSpecialDays(int year, int month, {String? category, bool forceRefresh = false}) async {
    final cacheKey = '$year-$month-$category';
    final cachedTime = _cacheTimestamps[cacheKey];
    if (!forceRefresh && cachedTime != null && DateTime.now().difference(cachedTime) < _cacheTtl) {
      final cached = _cache[cacheKey];
      if (cached != null) return cached;
    }

    List<SpecialDay> supabaseData = [];
    if (_db.isInitialized) {
      try {
        final startDate = "$year-${month.toString().padLeft(2, '0')}-01";
        final endDate = "$year-${month.toString().padLeft(2, '0')}-31";
        
        var query = _db.client
            .from('special_days')
            .select()
            .eq('is_published', true)
            .gte('date', startDate)
            .lte('date', endDate);

        if (category != null && category.isNotEmpty && category != 'All' && category != 'all') {
          query = query.eq('category', category.toLowerCase());
        }
            
        final data = await TNTResilience.retry(
          operation: () => query.order('date'),
          operationName: 'fetchSpecialDays',
        );
        supabaseData = (data as List).map((json) => SpecialDay.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Supabase Special days fetch failed: $e');
      }
    }

    final panchangRepo = PanchangRepository();
    final activeLocation = UserLocationItem(id: 'default', userId: 'default', name: 'Coimbatore', city: 'Coimbatore', createdAt: DateTime.now(), latitude: 11.0168, longitude: 76.9558, timezone: '+05:30');
    final monthlyBundles = await panchangRepo.getMonthlyPanchangam(year: year, month: month, location: activeLocation, forceRefresh: forceRefresh);

    final List<SpecialDay> apiData = [];
    for (var bundle in monthlyBundles) {
      // Filter by category if requested
      var filtered = bundle.specialDays;
      if (category != null && category.isNotEmpty && category != 'All' && category != 'all') {
        filtered = filtered.where((d) => d.category.toLowerCase() == category.toLowerCase()).toList();
      }
      apiData.addAll(filtered);
    }

    // Merge: Override Navamsha API data with Supabase data by ID or Date+Category match
    final mergedMap = <String, SpecialDay>{};
    for (var apiItem in apiData) {
      mergedMap[apiItem.id] = apiItem;
    }
    for (var supItem in supabaseData) {
      // Try to find if it overrides an API item by matching category and date
      final overriddenKey = mergedMap.keys.firstWhere(
        (key) => mergedMap[key]!.date.year == supItem.date.year &&
                 mergedMap[key]!.date.month == supItem.date.month &&
                 mergedMap[key]!.date.day == supItem.date.day &&
                 mergedMap[key]!.category.toLowerCase() == supItem.category.toLowerCase(),
        orElse: () => supItem.id,
      );
      mergedMap[overriddenKey] = supItem;
    }

    final deletedKeys = await getDeletedSpecialDayKeys();
    final result = mergedMap.values.where((sp) {
      if (sp.id.isNotEmpty && deletedKeys.contains(sp.id)) return false;
      final kTa = '${sp.date.year}-${sp.date.month}-${sp.date.day}_${sp.titleTa}';
      final kEn = '${sp.date.year}-${sp.date.month}-${sp.date.day}_${sp.title}';
      if (deletedKeys.contains(kTa) || deletedKeys.contains(kEn)) return false;
      return true;
    }).toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    _cache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return result;
  }

  static const String _deletedSpecialDaysKey = 'tnt_deleted_special_days_keys';

  Future<void> markSpecialDayDeleted(SpecialDay sp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deletedSpecialDaysKey) ?? [];
      final key1 = sp.id;
      final key2 = '${sp.date.year}-${sp.date.month}-${sp.date.day}_${sp.titleTa}';
      final key3 = '${sp.date.year}-${sp.date.month}-${sp.date.day}_${sp.title}';
      final set = list.toSet()..addAll([if (key1.isNotEmpty) key1, key2, key3]);
      await prefs.setStringList(_deletedSpecialDaysKey, set.toList());
    } catch (_) {}
  }

  Future<void> unmarkSpecialDayDeleted(SpecialDay sp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deletedSpecialDaysKey) ?? [];
      final set = list.toSet();
      if (sp.id.isNotEmpty) set.remove(sp.id);
      set.remove('${sp.date.year}-${sp.date.month}-${sp.date.day}_${sp.titleTa}');
      set.remove('${sp.date.year}-${sp.date.month}-${sp.date.day}_${sp.title}');
      await prefs.setStringList(_deletedSpecialDaysKey, set.toList());
    } catch (_) {}
  }

  Future<Set<String>> getDeletedSpecialDayKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_deletedSpecialDaysKey) ?? []).toSet();
    } catch (_) {
      return {};
    }
  }
}

class FestivalRepository {
  final SupabaseService _db = SupabaseService();
  static final Map<String, List<Festival>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  static void invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  Future<List<String>> fetchCategories() async {
    if (!_db.isInitialized) {
      return ['Festivals', 'Government Holiday', 'Hindu', 'Christian', 'Muslim'];
    }
    try {
      final data = await TNTResilience.retry(
        operation: () => _db.client
            .from('festivals')
            .select('type')
            .eq('is_published', true),
        operationName: 'fetchFestivalCategories',
      );
      final set = <String>{};
      for (final item in data as List) {
        if (item['type'] != null) {
          set.add(item['type'] as String);
        }
      }
      return set.isNotEmpty ? set.toList() : ['Festivals', 'Government Holiday'];
    } catch (_) {
      return ['Festivals', 'Government Holiday'];
    }
  }

  Future<List<Festival>> fetchFestivals(int year, int month, {String? category, bool forceRefresh = false}) async {
    final cacheKey = '$year-$month-$category';
    final cachedTime = _cacheTimestamps[cacheKey];
    if (!forceRefresh && cachedTime != null && DateTime.now().difference(cachedTime) < _cacheTtl) {
      final cached = _cache[cacheKey];
      if (cached != null) return cached;
    }

    List<Festival> supabaseData = [];
    if (_db.isInitialized) {
      try {
        final startDate = "$year-${month.toString().padLeft(2, '0')}-01";
        final endDate = "$year-${month.toString().padLeft(2, '0')}-31";
        
        var query = _db.client
            .from('festivals')
            .select()
            .eq('is_published', true)
            .gte('date', startDate)
            .lte('date', endDate);

        if (category != null && category.isNotEmpty && category != 'All' && category != 'all') {
          query = query.eq('type', category.toLowerCase());
        }
            
        final data = await TNTResilience.retry(
          operation: () => query.order('date'),
          operationName: 'fetchFestivals',
        );
        supabaseData = (data as List).map((json) => Festival.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Supabase Festival fetch failed: $e');
      }
    }

    final panchangRepo = PanchangRepository();
    final activeLocation = UserLocationItem(id: 'default', userId: 'default', name: 'Coimbatore', city: 'Coimbatore', createdAt: DateTime.now(), latitude: 11.0168, longitude: 76.9558, timezone: '+05:30');
    final monthlyBundles = await panchangRepo.getMonthlyPanchangam(year: year, month: month, location: activeLocation, forceRefresh: forceRefresh);

    final List<Festival> apiData = [];
    for (var bundle in monthlyBundles) {
      var filtered = bundle.festivals;
      if (category != null && category.isNotEmpty && category != 'All' && category != 'all') {
        filtered = filtered.where((f) => f.type.toLowerCase() == category.toLowerCase()).toList();
      }
      apiData.addAll(filtered);
    }

    final mergedMap = <String, Festival>{};
    for (var apiItem in apiData) {
      mergedMap[apiItem.id] = apiItem;
    }
    for (var supItem in supabaseData) {
      mergedMap[supItem.id] = supItem;
    }

    final deletedKeys = await getDeletedFestivalKeys();
    final result = mergedMap.values.where((f) {
      if (f.id.isNotEmpty && deletedKeys.contains(f.id)) return false;
      final kTa = '${f.date.year}-${f.date.month}-${f.date.day}_${f.nameTa}';
      final kEn = '${f.date.year}-${f.date.month}-${f.date.day}_${f.name}';
      if (deletedKeys.contains(kTa) || deletedKeys.contains(kEn)) return false;
      return true;
    }).toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    _cache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return result;
  }

  static const String _deletedFestivalsKey = 'tnt_deleted_festival_keys';

  Future<void> markFestivalDeleted(Festival f) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deletedFestivalsKey) ?? [];
      final key1 = f.id;
      final key2 = '${f.date.year}-${f.date.month}-${f.date.day}_${f.nameTa}';
      final key3 = '${f.date.year}-${f.date.month}-${f.date.day}_${f.name}';
      final set = list.toSet()..addAll([if (key1.isNotEmpty) key1, key2, key3]);
      await prefs.setStringList(_deletedFestivalsKey, set.toList());
    } catch (_) {}
  }

  Future<void> unmarkFestivalDeleted(Festival f) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deletedFestivalsKey) ?? [];
      final set = list.toSet();
      if (f.id.isNotEmpty) set.remove(f.id);
      set.remove('${f.date.year}-${f.date.month}-${f.date.day}_${f.nameTa}');
      set.remove('${f.date.year}-${f.date.month}-${f.date.day}_${f.name}');
      await prefs.setStringList(_deletedFestivalsKey, set.toList());
    } catch (_) {}
  }

  Future<Set<String>> getDeletedFestivalKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_deletedFestivalsKey) ?? []).toSet();
    } catch (_) {
      return {};
    }
  }
}

// =====================================================================
// SAVED ITEMS & REMINDERS REPOSITORIES (Row-Level Security Bound)
// =====================================================================
class SavedItemsRepository {
  final SupabaseService _db = SupabaseService();

  Future<List<SavedItem>> fetchSavedItems() async {
    if (!_db.isInitialized) return [];
    try {
      final data = await _db.client.from('user_saved_items').select().order('created_at', ascending: false);
      return (data as List).map((json) => SavedItem.fromJson(json)).toList();
    } catch (e) {
      throw TNTException('Saved items synchronization failed: $e', 'SAVED_FETCH_FAILED');
    }
  }

  Future<void> saveItemRecord(SavedItem item, String userId) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client.from('user_saved_items').upsert({
        'user_id': userId,
        'item_type': item.typeEnum.toDbString(),
        'item_id': item.itemId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw TNTException('Failed to save bookmark record: $e', 'SAVED_INSERT_FAILED');
    }
  }

  Future<void> deleteSavedItem(String itemType, String itemId, String userId) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client
          .from('user_saved_items')
          .delete()
          .eq('user_id', userId)
          .eq('item_type', itemType)
          .eq('item_id', itemId);
    } catch (e) {
      throw TNTException('Failed to delete bookmark: $e', 'SAVED_DELETE_FAILED');
    }
  }

  Future<void> toggleSaved(String itemType, String itemId, String userId) async {
    if (!_db.isInitialized) return;
    try {
      final existing = await _db.client
          .from('user_saved_items')
          .select()
          .eq('user_id', userId)
          .eq('item_type', itemType)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existing != null) {
        await deleteSavedItem(itemType, itemId, userId);
      } else {
        await _db.client.from('user_saved_items').insert({
          'user_id': userId,
          'item_type': itemType,
          'item_id': itemId,
        });
      }
    } catch (e) {
      throw TNTException('Failed to modify saved bookmark: $e', 'SAVED_TOGGLE_FAILED');
    }
  }
}

class ReminderRepository {
  final SupabaseService _db = SupabaseService();

  Future<List<Reminder>> fetchReminders() async {
    if (!_db.isInitialized) return [];
    try {
      final data = await _db.client.from('user_reminders').select().order('reminder_time', ascending: true);
      return (data as List).map((json) => Reminder.fromJson(json)).toList();
    } catch (e) {
      throw TNTException('Reminders download failed: $e', 'REMINDERS_FETCH_FAILED');
    }
  }

  Future<Reminder> insertReminder(Reminder reminder) async {
    if (!_db.isInitialized) return reminder;
    try {
      final data = await _db.client
          .from('user_reminders')
          .insert({
            'user_id': reminder.userId,
            'item_type': reminder.itemType,
            'item_id': reminder.itemId,
            'reminder_time': reminder.reminderAt.toIso8601String(),
            'is_enabled': reminder.isSet,
          })
          .select()
          .single();
      return Reminder.fromJson(data);
    } catch (e) {
      throw TNTException('Failed to create reminder: $e', 'REMINDER_CREATE_FAILED');
    }
  }

  Future<void> updateReminderStatus(String reminderId, bool isSet) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client
          .from('user_reminders')
          .update({
            'is_enabled': isSet,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reminderId);
    } catch (e) {
      throw TNTException('Failed to update reminder status: $e', 'REMINDER_UPDATE_FAILED');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    if (!_db.isInitialized) return;
    try {
      await _db.client.from('user_reminders').delete().eq('id', reminderId);
    } catch (e) {
      throw TNTException('Failed to remove reminder: $e', 'REMINDER_DELETE_FAILED');
    }
  }
}

// =====================================================================
// ANALYTICS REPOSITORY (Strictly Guarded by Postgres Role Rules)
// =====================================================================
class AnalyticsRepository {
  final SupabaseService _db = SupabaseService();

  /// Safe logging for metrics (accessible by anyone / anonymous)
  Future<void> logEvent({required String eventName, String? contentId, Map<String, dynamic>? metadata}) async {
    if (!_db.isInitialized) return;
    try {
      final user = _db.client.auth.currentUser;
      await _db.client.from('analytics_events').insert({
        if (user != null) 'user_id': user.id,
        'event_name': eventName,
        if (contentId != null) 'content_id': contentId,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      // Fail silently for analytics events to prevent interrupting core flow
      print('Analytics logging silently skipped: $e');
    }
  }

  /// Strictly Guarded Admin query - Postgres throws 'Permission Denied' exception if user is not ADMIN
  Future<List<Map<String, dynamic>>> fetchDailySummary() async {
    if (!_db.isInitialized) {
      throw TNTException('Offline. Admin analytics unavailable.', 'OFFLINE');
    }
    try {
      final data = await _db.client
          .from('daily_analytics')
          .select()
          .order('analytics_date', ascending: false)
          .limit(15);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw TNTException('Access denied. Admin authorization is verified at Postgres tier only: $e', 'RLS_DENIED');
    }
  }
}
