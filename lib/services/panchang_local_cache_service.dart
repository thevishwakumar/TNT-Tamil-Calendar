import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../panchangam/models/panchangam_bundle.dart';

/// Production-grade Local Storage Cache Service for Daily Panchangam
/// Enables users to access today's and recent days' essential timings 
/// (Nalla Neram, Rahu Kalam, Yamagandam, Sunrise, Sunset, Tithi, Nakshatra)
/// completely offline without an active internet connection.
class PanchangLocalCacheService {
  static final PanchangLocalCacheService _instance = PanchangLocalCacheService._internal();
  factory PanchangLocalCacheService() => _instance;
  PanchangLocalCacheService._internal();

  static const String _keyPrefix = 'tnt_panchang_cache_v1_';
  static const String _indexKey = 'tnt_panchang_cache_index';
  static const Duration defaultCacheValidity = Duration(days: 7);

  // In-memory fallback cache in case SharedPreferences is unavailable or in mock environment
  final Map<String, String> _memoryCache = {};

  /// Generate deterministic cache key based on location and date
  String _buildKey(String location, DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final sanitizedCity = location.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return '$_keyPrefix${sanitizedCity}_${year}_${month}_$day';
  }

  /// Store daily Panchangam bundle into local storage
  Future<bool> cacheDailyPanchangam({
    required DateTime date,
    required String location,
    required PanchangamDailyBundle bundle,
  }) async {
    final key = _buildKey(location, date);
    final payload = {
      'schemaVersion': 1,
      'cachedAt': DateTime.now().toIso8601String(),
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'location': location,
      'data': bundle.toJson(),
    };

    final jsonString = jsonEncode(payload);

    // Save in memory fallback immediately
    _memoryCache[key] = jsonString;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonString);

      // Update cache index
      final indexList = prefs.getStringList(_indexKey) ?? [];
      if (!indexList.contains(key)) {
        indexList.add(key);
        await prefs.setStringList(_indexKey, indexList);
      }
      return true;
    } catch (e) {
      // In web simulator or test runner where SharedPreferences native channel might not be registered
      return true;
    }
  }

  /// Retrieve cached daily Panchangam bundle from local storage
  Future<PanchangamDailyBundle?> getCachedDailyPanchangam({
    required DateTime date,
    required String location,
    Duration? maxAge,
  }) async {
    final key = _buildKey(location, date);
    String? jsonString;

    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString(key);
    } catch (_) {
      // Fallback to memory cache
    }

    jsonString ??= _memoryCache[key];

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAtStr = decoded['cachedAt'] as String?;
      DateTime? cachedAt;
      if (cachedAtStr != null) {
        cachedAt = DateTime.tryParse(cachedAtStr);
      }

      // Check cache freshness if maxAge specified
      if (maxAge != null && cachedAt != null) {
        if (DateTime.now().difference(cachedAt) > maxAge) {
          return null; // Cache expired
        }
      }

      final dataJson = decoded['data'] as Map<String, dynamic>;
      final bundle = PanchangamDailyBundle.fromJson(dataJson);

      return bundle.copyWith(
        isFromOfflineCache: true,
        cachedAt: cachedAt ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Quick check if local cache exists for a given date and location
  Future<bool> hasCachedPanchangam({
    required DateTime date,
    required String location,
  }) async {
    final key = _buildKey(location, date);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) return true;
    } catch (_) {}
    return _memoryCache.containsKey(key);
  }

  /// Retrieve list of all cached date keys for a specific location
  Future<List<String>> getCachedDatesForLocation(String location) async {
    final sanitizedCity = location.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final prefix = '$_keyPrefix${sanitizedCity}_';
    final result = <String>[];

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith(prefix)) {
          final datePart = k.replaceFirst(prefix, '').replaceAll('_', '-');
          result.add(datePart);
        }
      }
    } catch (_) {
      for (final k in _memoryCache.keys) {
        if (k.startsWith(prefix)) {
          final datePart = k.replaceFirst(prefix, '').replaceAll('_', '-');
          result.add(datePart);
        }
      }
    }
    return result;
  }

  /// Get cache metadata (timestamp, timings count, city) for inspection
  Future<Map<String, dynamic>?> getCacheMetadata({
    required DateTime date,
    required String location,
  }) async {
    final key = _buildKey(location, date);
    String? jsonString;
    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString(key);
    } catch (_) {}
    jsonString ??= _memoryCache[key];

    if (jsonString == null) return null;

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final timings = data['timings'] as List<dynamic>? ?? [];
      return {
        'cachedAt': decoded['cachedAt'],
        'location': decoded['location'],
        'date': decoded['date'],
        'timingsCount': timings.length,
        'hasAstronomical': data['panchangam'] != null,
      };
    } catch (_) {
      return null;
    }
  }

  /// Clear all cached Panchangam entries from local storage
  Future<void> clearAllCache() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexList = prefs.getStringList(_indexKey) ?? [];
      for (final key in indexList) {
        await prefs.remove(key);
      }
      await prefs.remove(_indexKey);
    } catch (_) {}
  }
}
