import 'package:flutter/material.dart';
import '../models/tnt_models.dart';
import 'supabase_service.dart';
import 'device_service.dart';

/// Notification Permission Status Enum
enum NotificationPermissionStatus { notDetermined, granted, denied }

/// Centralized Notification Service for TNT Application
/// Coordinates:
/// - Permission request onboarding & status
/// - User Notification Preferences (including strict opt-in marketing)
/// - Device Push Token registration via DeviceService
/// - Notification History (notification_logs) & Mark as Read / Mark All as Read
/// - Deep Linking to approved public content
/// - Integration with Reminders, Festivals, Special Days, Muhurtham, and Panchangam
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseService _db = SupabaseService();
  final DeviceService _deviceService = DeviceService();

  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.notDetermined;
  NotificationPreferences _preferences = const NotificationPreferences();
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  NotificationPermissionStatus get permissionStatus => _permissionStatus;
  NotificationPreferences get preferences => _preferences;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize notification service with seed logs
  Future<void> init() async {
    await fetchPreferences();
    await fetchNotifications();
  }

  /// Fetch notifications from real Supabase table
  Future<void> fetchNotifications() async {
    if (!_db.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final user = _db.client.auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await _db.client
          .from('notification_logs')
          .select('*')
          .eq('user_id', user.id)
          .order('sent_at', ascending: false)
          .limit(50);

      _notifications.clear();
      for (final item in (res as List)) {
        _notifications.add(NotificationItem.fromJson(item));
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request notification permission with clear rationale
  Future<bool> requestPermission() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate platform permission grant
      _permissionStatus = NotificationPermissionStatus.granted;
      
      // Register device token upon granting permission
      await _deviceService.registerDeviceToken();

      // Ensure allNotifications is enabled
      _preferences = _preferences.copyWith(allNotifications: true);
      await savePreferences(_preferences);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _permissionStatus = NotificationPermissionStatus.denied;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deny or dismiss permission dialog without breaking normal app functionality
  void dismissPermission() {
    _permissionStatus = NotificationPermissionStatus.denied;
    notifyListeners();
  }

  /// Fetch user notification preferences from Supabase or local cache
  Future<void> fetchPreferences() async {
    try {
      if (_db.isInitialized) {
        final user = _db.client.auth.currentUser;
        if (user != null) {
          final res = await _db.client
              .from('user_preferences')
              .select('*')
              .eq('user_id', user.id)
              .maybeSingle();

          if (res != null) {
            _preferences = NotificationPreferences.fromJson(res);
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {}
  }

  /// Save updated notification preferences
  Future<void> savePreferences(NotificationPreferences prefs) async {
    _preferences = prefs;
    notifyListeners();

    try {
      if (_db.isInitialized) {
        final user = _db.client.auth.currentUser;
        if (user != null) {
          await _db.client.from('user_preferences').upsert({
            'user_id': user.id,
            ...prefs.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Supabase preferences update error: $e');
    }
  }

  /// Toggle single preference category
  Future<void> togglePreference(String key, bool value) async {
    NotificationPreferences updated;
    switch (key) {
      case 'all':
        updated = _preferences.copyWith(allNotifications: value);
        break;
      case 'panchangam':
        updated = _preferences.copyWith(panchangamNotifications: value);
        break;
      case 'muhurtham':
        updated = _preferences.copyWith(muhurthamNotifications: value);
        break;
      case 'festivals':
        updated = _preferences.copyWith(festivalNotifications: value);
        break;
      case 'special_days':
        updated = _preferences.copyWith(specialDayNotifications: value);
        break;
      case 'reminders':
        updated = _preferences.copyWith(reminderNotifications: value);
        break;
      case 'important_updates':
        updated = _preferences.copyWith(importantUpdates: value);
        break;
      case 'marketing':
        updated = _preferences.copyWith(marketingNotifications: value);
        break;
      default:
        return;
    }
    await savePreferences(updated);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        openedAt: DateTime.now(),
        status: 'OPENED',
      );
      notifyListeners();

      if (_db.isInitialized) {
        try {
          await _db.client.rpc('mark_notification_as_read', params: {
            'p_notification_id': notificationId,
          });
        } catch (_) {}
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          openedAt: now,
          status: 'OPENED',
        );
      }
    }
    notifyListeners();

    if (_db.isInitialized) {
      try {
        await _db.client.rpc('mark_all_notifications_as_read');
      } catch (_) {}
    }
  }

  /// Receive / simulate push notification dispatch from secure backend
  Future<void> receiveSimulatedPush({
    required String title,
    required String titleTa,
    required String body,
    required String bodyTa,
    required String notificationType,
    String? relatedItemType,
    String? relatedItemId,
  }) async {
    // Check if user preferences allow this notification
    if (!_preferences.allNotifications) return;

    if (notificationType == 'marketing' && !_preferences.marketingNotifications) {
      return; // Respect strict opt-in rule
    }
    if (notificationType == 'festival' && !_preferences.festivalNotifications) return;
    if (notificationType == 'muhurtham' && !_preferences.muhurthamNotifications) return;
    if (notificationType == 'special_day' && !_preferences.specialDayNotifications) return;
    if (notificationType == 'panchangam' && !_preferences.panchangamNotifications) return;
    if (notificationType == 'reminder' && !_preferences.reminderNotifications) return;

    final newNotif = NotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      titleTa: titleTa,
      message: body,
      messageTa: bodyTa,
      notificationType: notificationType,
      relatedItemType: relatedItemType,
      relatedItemId: relatedItemId,
      sentAt: DateTime.now(),
      isRead: false,
      status: 'DELIVERED',
      category: notificationType,
    );

    _notifications.insert(0, newNotif);
    notifyListeners();
  }
}
