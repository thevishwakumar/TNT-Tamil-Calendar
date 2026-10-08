import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/tnt_models.dart';

/// Central Configuration Loader for Supabase Secrets
class SupabaseConfig {
  static String get url {
    const envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    if (dotenv.isInitialized) {
      return dotenv.env['SUPABASE_URL'] ?? 'https://placeholder-tnt-project.supabase.co';
    }
    return 'https://placeholder-tnt-project.supabase.co';
  }
  
  static String get anonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;
    if (dotenv.isInitialized) {
      return dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIn0.signature';
    }
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIn0.signature';
  }
}

/// Central Service holding initialized Supabase client instance and general status checks.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  Future<void>? _initFuture;

  bool get isInitialized => _isInitialized;

  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('SupabaseService has not been initialized. Call init() first.');
    }
    return Supabase.instance.client;
  }

  /// Safe Initializer that catches network or invalid key configuration failures gracefully
  Future<void> init() {
    if (_isInitialized) return Future.value();
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Supabase connection timed out. Please check your internet connection.');
      });
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      print('Supabase initialization failed: $e. Falling back to development mock mode.');
      rethrow; // Rethrow to let AuthStateManager catch it and show error state
    } finally {
      _initFuture = null;
    }
  }
}

/// Reusable operational error wrapper
class TNTException implements Exception {
  final String message;
  final String code;

  TNTException(this.message, [this.code = 'UNKNOWN']);

  @override
  String toString() => 'TNTException ($code): $message';
}

/// Service Interfaces to establish the architecture contract
abstract class ITNTApiService {
  // Authentication & Profile Contract
  Future<UserProfile?> getCurrentUserProfile();
  Future<UserProfile> updateUserProfile(String fullName);
  Future<UserPreferences> getUserPreferences();
  Future<void> saveUserPreferences(UserPreferences prefs);

  // Calendar & Panchangam Contracts
  Future<CalendarDay> getCalendarDay(DateTime date);
  Future<PanchangamEntry> getPanchangam(DateTime date);
  Future<List<TimingEntry>> getImportantTimings(DateTime date);

  // Muhurtham, Festivals, and Special Days Contracts
  Future<List<MuhurthamDate>> getMarriageMuhurthams(int year, int month);
  Future<List<MuhurthamDate>> getMuhurthamDates({
    required int year,
    required int month,
    String? category,
    String? phase,
    String? location,
  });
  Future<List<String>> getApprovedMuhurthamCategories();
  Future<List<String>> getApprovedSpecialDayCategories();
  Future<List<String>> getApprovedFestivalCategories();
  Future<List<SpecialDay>> getSpecialDays(int year, int month, {String? category});
  Future<List<Festival>> getFestivals(int year, int month, {String? category});

  // Reminders & Saved Items Contracts
  Future<List<SavedItem>> getSavedItems();
  Future<void> toggleSaveItem(String itemType, String itemId);
  Future<List<Reminder>> getReminders();
  Future<Reminder> setReminder(String title, DateTime eventDate, String reminderTime);

  // Marketing & Notifications
  Future<List<NotificationItem>> getNotifications();

  // Admin Dashboard Contracts (Restricted to verified ADMIN role)
  Future<AdminDashboardMetrics> getAdminDashboardMetrics();
}

