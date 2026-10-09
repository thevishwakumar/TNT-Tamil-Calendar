import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tnt_models.dart';
import 'supabase_service.dart';
import 'device_service.dart';
import '../features/admin/notifications/repositories/admin_campaign_repository.dart';
import 'push_notification_service.dart';

/// Notification Permission Status Enum
enum NotificationPermissionStatus { notDetermined, granted, denied }

/// Centralized Notification Service for TNT Application
/// Coordinates:
/// - Permission request onboarding & status
/// - User Notification Preferences (including strict opt-in marketing)
/// - Device Push Token registration via DeviceService
/// - Broadcast Campaigns (notification_campaigns) from Admin Dashboard
/// - Notification History (notification_logs) & Mark as Read / Mark All as Read
/// - Deep Linking to approved public content
/// - Integration with Reminders, Festivals, Special Days, Muhurtham, and Panchangam
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseService _db = SupabaseService();
  final DeviceService _deviceService = DeviceService();

  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.notDetermined;
  NotificationPreferences _preferences = const NotificationPreferences();
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  NotificationPermissionStatus get permissionStatus => _permissionStatus;
  NotificationPreferences get preferences => _preferences;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DeviceService get deviceService => _deviceService;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Add incoming foreground push notification to in-memory list
  void addPushNotification(NotificationItem item) {
    if (!_notifications.any((n) => n.id == item.id)) {
      _notifications.insert(0, item);
      notifyListeners();
    }
  }

  /// Initialize notification service
  Future<void> init() async {
    await fetchPreferences();
    await fetchNotifications();
  }

  /// Whether a notification category is allowed based on user preferences
  bool _isCategoryAllowed(String type) {
    if (!_preferences.allNotifications) return false;
    final t = type.toLowerCase();
    switch (t) {
      case 'marketing':
        return _preferences.marketingNotifications; // Strict opt-in
      case 'festival':
        return _preferences.festivalNotifications;
      case 'muhurtham':
        return _preferences.muhurthamNotifications;
      case 'special_day':
        return _preferences.specialDayNotifications;
      case 'panchangam':
        return _preferences.panchangamNotifications;
      case 'reminder':
        return _preferences.reminderNotifications;
      case 'important_update':
      case 'announcement':
        return _preferences.importantUpdates;
      default:
        return true;
    }
  }

  /// Fetch notifications from both Supabase (broadcast campaigns & personal logs) and local repositories
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds =
          (prefs.getStringList('tnt_read_notifications') ?? []).toSet();

      final List<NotificationItem> loadedItems = [];

      // 1. Fetch broadcast notification campaigns sent from Admin Dashboard (Supabase)
      if (_db.isInitialized) {
        try {
          final res = await _db.client
              .from('notification_campaigns')
              .select('*')
              .eq('status', 'SENT')
              .order('sent_at', ascending: false)
              .limit(50);

          for (final item in res) {
            try {
              final notif = NotificationItem.fromJson(item);
              final isRead = readIds.contains(notif.id) ||
                  (notif.campaignId != null &&
                      readIds.contains(notif.campaignId));
              if (_isCategoryAllowed(notif.notificationType)) {
                loadedItems.add(notif.copyWith(isRead: isRead));
              }
            } catch (e) {
              debugPrint('Campaign parse error: $e');
            }
          }
        } catch (e) {
          debugPrint('Supabase notification_campaigns fetch error: $e');
        }
      }

      // 2. Fetch sent campaigns from AdminCampaignRepository (for offline / session-created campaigns)
      try {
        final adminRepo = AdminCampaignRepository();
        final localSent = await adminRepo.getCampaigns(status: 'SENT');
        for (final camp in localSent) {
          if (!loadedItems
              .any((n) => n.id == camp.id || n.campaignId == camp.id)) {
            if (_isCategoryAllowed(camp.category.toLowerCase())) {
              final isRead = readIds.contains(camp.id);
              loadedItems
                  .add(NotificationItem.fromCampaign(camp, isRead: isRead));
            }
          }
        }
      } catch (e) {
        debugPrint('Admin campaigns fetch error: $e');
      }

      // 3. Fetch user-specific notification logs from Supabase if authenticated
      if (_db.isInitialized) {
        try {
          final user = _db.client.auth.currentUser;
          if (user != null) {
            final res = await _db.client
                .from('notification_logs')
                .select('*')
                .eq('user_id', user.id)
                .order('sent_at', ascending: false)
                .limit(50);

            for (final item in res) {
              try {
                final notif = NotificationItem.fromJson(item);
                final isRead = notif.isRead || readIds.contains(notif.id);
                if (_isCategoryAllowed(notif.notificationType)) {
                  if (!loadedItems.any((n) => n.id == notif.id)) {
                    loadedItems.add(notif.copyWith(isRead: isRead));
                  }
                }
              } catch (e) {
                debugPrint('Notification log parse error: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Supabase notification_logs fetch error: $e');
        }
      }

      // 4. Fallback local delivery logs from AdminCampaignRepository
      try {
        final adminRepo = AdminCampaignRepository();
        for (final log in adminRepo.localDeliveryLogs) {
          final logId = log['id'] as String;
          if (!loadedItems.any((n) => n.id == logId)) {
            final notif = NotificationItem.fromJson(log);
            if (_isCategoryAllowed(notif.notificationType)) {
              final isRead = readIds.contains(logId) || notif.isRead;
              loadedItems.add(notif.copyWith(isRead: isRead));
            }
          }
        }
      } catch (e) {
        debugPrint('Local delivery logs fetch error: $e');
      }

      // 5. Sort by sentAt descending
      loadedItems.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      _notifications.clear();
      _notifications.addAll(loadedItems);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dynamically add or update campaign notification (invoked immediately when admin dispatches)
  void addCampaignNotification(NotificationCampaign campaign) {
    if (campaign.status.toUpperCase() != 'SENT') return;
    if (!_isCategoryAllowed(campaign.category)) return;

    final notif = NotificationItem.fromCampaign(campaign, isRead: false);
    final idx = _notifications
        .indexWhere((n) => n.id == notif.id || n.campaignId == notif.id);
    if (idx != -1) {
      _notifications[idx] = notif;
    } else {
      _notifications.insert(0, notif);
    }
    notifyListeners();
  }

  /// Request notification permission with clear rationale
  Future<bool> requestPermission() async {
    _isLoading = true;
    notifyListeners();

    try {
      final granted = await PushNotificationService()
          .requestNotificationPermission(forcePrompt: true);
      _permissionStatus = granted
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;

      if (granted) {
        // Ensure allNotifications is enabled
        _preferences = _preferences.copyWith(allNotifications: true);
        await savePreferences(_preferences);
      }

      _isLoading = false;
      notifyListeners();
      return granted;
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
      final sp = await SharedPreferences.getInstance();
      final savedStr = sp.getString('tnt_notification_prefs');
      if (savedStr != null) {
        final data = jsonDecode(savedStr) as Map<String, dynamic>;
        _preferences = NotificationPreferences.fromJson(data);
        notifyListeners();
      }
    } catch (_) {}

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
      final sp = await SharedPreferences.getInstance();
      await sp.setString('tnt_notification_prefs', jsonEncode(prefs.toJson()));
    } catch (_) {}

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
      debugPrint('Supabase preferences update error: $e');
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

      try {
        final prefs = await SharedPreferences.getInstance();
        final readIds =
            (prefs.getStringList('tnt_read_notifications') ?? []).toSet();
        readIds.add(notificationId);
        await prefs.setStringList('tnt_read_notifications', readIds.toList());
      } catch (_) {}

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
    final List<String> allIds = [];
    for (int i = 0; i < _notifications.length; i++) {
      allIds.add(_notifications[i].id);
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          openedAt: now,
          status: 'OPENED',
        );
      }
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds =
          (prefs.getStringList('tnt_read_notifications') ?? []).toSet();
      readIds.addAll(allIds);
      await prefs.setStringList('tnt_read_notifications', readIds.toList());
    } catch (_) {}

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
    if (!_isCategoryAllowed(notificationType)) return;

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

  /// Clear session state upon user sign out to guarantee zero cross-user data leakage
  void clearSession() {
    _notifications.clear();
    _preferences = const NotificationPreferences();
    _errorMessage = null;
    notifyListeners();
  }
}
