import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/tnt_models.dart';
import 'device_service.dart';
import 'notification_service.dart';
import '../features/admin/notifications/services/notification_deep_link_router.dart';

/// Top-level background message handler annotated with vm:entry-point.
/// Must be outside of any class to be invoked by the Flutter engine in background isolates.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Minimal diagnostic logging without sensitive payload data or tokens
    debugPrint(
        '[PushNotification] Background message received: ${message.messageId}');
  } catch (e) {
    debugPrint('[PushNotification] Background handler error: $e');
  }
}

/// Dedicated, Production-Grade Push Notification Service
/// Handles FCM token lifecycle, permission requests, foreground/background message dispatch,
/// and deep-link routing.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const String _prefPermissionRequestedKey =
      'tnt_fcm_permission_prompted';

  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;
  String? _fcmToken;
  GlobalKey<NavigatorState>? _navigatorKey;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  String? get fcmToken => _fcmToken;
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase & Push Notification Listeners safely.
  /// Never blocks app startup or crashes on unsupported environments.
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;

    try {
      // 1. Verify or initialize Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseAvailable = true;
    } catch (e) {
      _isFirebaseAvailable = false;
      debugPrint(
          '[PushNotification] Firebase not available on this platform: $e');
      return;
    }

    try {
      // 2. Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Listen for token refresh events
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) {
          _fcmToken = newToken;
          debugPrint('[PushNotification] FCM token refreshed');
          _syncTokenWithBackend(newToken);
        },
        onError: (err) {
          debugPrint('[PushNotification] Token refresh stream error: $err');
        },
      );

      // 4. Foreground message listener
      _onMessageSub = FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          _handleForegroundMessage(message);
        },
        onError: (err) {
          debugPrint('[PushNotification] onMessage listener error: $err');
        },
      );

      // 5. Notification tap while app is in background
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          _handleNotificationTap(message);
        },
        onError: (err) {
          debugPrint(
              '[PushNotification] onMessageOpenedApp listener error: $err');
        },
      );

      // 6. Check if app was launched from a terminated state via notification tap
      _checkInitialMessage();

      // 7. If permission was already granted previously, obtain token without re-prompting
      await _checkExistingPermissionAndRetrieveToken();

      _isInitialized = true;
      debugPrint(
          '[PushNotification] PushNotificationService initialized successfully');
    } catch (e) {
      debugPrint('[PushNotification] Error initializing listeners: $e');
    }
  }

  /// Check if the app was launched by tapping a notification from terminated state
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '[PushNotification] App launched from terminated state via notification');
        // Delay slightly to ensure UI navigator is attached
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('[PushNotification] getInitialMessage error: $e');
    }
  }

  /// Check existing notification permission status without prompting
  Future<void> _checkExistingPermissionAndRetrieveToken() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _retrieveAndSyncToken();
      }
    } catch (e) {
      debugPrint('[PushNotification] Permission check error: $e');
    }
  }

  /// Request notification permission at an appropriate user touchpoint.
  /// Prevents spamming user if permission was already granted or denied.
  Future<bool> requestNotificationPermission({bool forcePrompt = false}) async {
    if (!_isFirebaseAvailable) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyPrompted =
          prefs.getBool(_prefPermissionRequestedKey) ?? false;

      if (alreadyPrompted && !forcePrompt) {
        final currentSettings =
            await FirebaseMessaging.instance.getNotificationSettings();
        return currentSettings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            currentSettings.authorizationStatus ==
                AuthorizationStatus.provisional;
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      await prefs.setBool(_prefPermissionRequestedKey, true);

      final isGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint(
          '[PushNotification] Permission request result: ${settings.authorizationStatus}');

      if (isGranted) {
        await _retrieveAndSyncToken();
      }

      return isGranted;
    } catch (e) {
      debugPrint('[PushNotification] requestNotificationPermission error: $e');
      return false;
    }
  }

  /// Retrieve current FCM token and sync to Supabase user_devices
  Future<String?> _retrieveAndSyncToken() async {
    if (!_isFirebaseAvailable) return null;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        debugPrint('[PushNotification] FCM token acquired successfully');
        await _syncTokenWithBackend(token);
      }
      return token;
    } catch (e) {
      debugPrint('[PushNotification] Failed to retrieve FCM token: $e');
      return null;
    }
  }

  /// Syncs device push token with Supabase via DeviceService
  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final deviceService = DeviceService();
      await deviceService.registerDeviceToken(token: token);
    } catch (e) {
      debugPrint('[PushNotification] Backend token sync error: $e');
    }
  }

  /// Public hook to sync active token when user signs in or restores session
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken != null) {
      await _syncTokenWithBackend(_fcmToken!);
    } else {
      await _retrieveAndSyncToken();
    }
  }

  /// Deactivates device token association in Supabase upon user sign-out
  Future<void> onLogout() async {
    try {
      final deviceService = DeviceService();
      await deviceService.deactivateOnLogout();
      debugPrint('[PushNotification] Device token deactivated on logout');
    } catch (e) {
      debugPrint('[PushNotification] Logout deactivation error: $e');
    }
  }

  /// Handle foreground notification message without duplicate system alerts.
  /// Converts FCM message to NotificationItem and updates in-app notification feed.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '[PushNotification] Foreground message received: ${message.messageId}');

    try {
      final data = message.data;
      final notification = message.notification;

      final title =
          notification?.title ?? data['title'] ?? 'TNT Tamil Calendar';
      final body = notification?.body ?? data['body'] ?? data['message'] ?? '';
      final titleTa = data['title_ta'] ?? data['titleTa'] ?? title;
      final bodyTa = data['body_ta'] ?? data['bodyTa'] ?? body;
      final category = (data['category'] ?? data['type'] ?? 'general')
          .toString()
          .toLowerCase();
      final deepLink = data['deep_link'] ?? data['deepLink'];
      final campaignId = data['campaign_id'] ?? data['campaignId'];

      // Create model item and refresh in-app feed
      final item = NotificationItem(
        id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
        campaignId: campaignId,
        title: title,
        titleTa: titleTa,
        message: body,
        messageTa: bodyTa,
        category: category,
        notificationType: category,
        sentAt: message.sentTime ?? DateTime.now(),
        deepLink: deepLink,
        status: 'DELIVERED',
        isRead: false,
      );

      // Notify in-app notification service to refresh list and badge
      NotificationService().addPushNotification(item);
      NotificationService().fetchNotifications();

      // Show subtle in-app snackbar if navigator context is available
      final context = _navigatorKey?.currentContext;
      if (context != null && context.mounted && body.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: (deepLink != null && deepLink.toString().isNotEmpty)
                ? SnackBarAction(
                    label: 'Open',
                    onPressed: () {
                      _handleNotificationTap(message);
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PushNotification] Foreground message parsing error: $e');
    }
  }

  /// Handle user tapping on a notification (from background or terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[PushNotification] Notification tapped: ${message.messageId}');

    final data = message.data;
    final deepLink = data['deep_link'] ?? data['deepLink'];
    final context = _navigatorKey?.currentContext;

    if (context == null || !context.mounted) {
      debugPrint(
          '[PushNotification] Navigator context not ready for deep link navigation');
      return;
    }

    try {
      if (deepLink != null && deepLink.toString().trim().isNotEmpty) {
        NotificationDeepLinkRouter()
            .handleDeepLink(context, deepLink.toString());
      } else {
        // Fallback: If category indicates a specific section, route gracefully
        final category =
            (data['category'] ?? data['type'] ?? '').toString().toLowerCase();
        if (category == 'panchangam') {
          NotificationDeepLinkRouter()
              .handleDeepLink(context, 'tnt://panchangam');
        } else if (category == 'muhurtham') {
          NotificationDeepLinkRouter()
              .handleDeepLink(context, 'tnt://muhurtham');
        } else if (category == 'festival') {
          NotificationDeepLinkRouter()
              .handleDeepLink(context, 'tnt://calendar');
        }
      }
    } catch (e) {
      debugPrint('[PushNotification] Error handling notification tap: $e');
    }
  }

  /// Clean up stream subscriptions
  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _isInitialized = false;
  }
}
