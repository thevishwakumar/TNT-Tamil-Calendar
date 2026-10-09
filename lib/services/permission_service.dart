import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/localization/tnt_localizations.dart';
import 'push_notification_service.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Requests location permission with a pre-prompt explanation dialog.
  /// Does not request if permanently denied.
  Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;
    if (!context.mounted) return false;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, 'location');
      return false;
    }

    // Show just-in-time explanation before requesting
    final proceed = await _showExplanationDialog(
      context,
      titleKey: 'location_permission_title',
      descKey: 'location_permission_desc',
      defaultTitle: 'Location Required',
      defaultDesc:
          'Allow location access to provide accurate Panchangam, timings and location-based calendar information for your area.',
      icon: Icons.location_on_rounded,
    );

    if (proceed == true) {
      final newStatus = await Permission.locationWhenInUse.request();
      if (!context.mounted) return false;
      if (newStatus.isGranted) return true;
      if (newStatus.isPermanentlyDenied) {
        _showPermanentlyDeniedDialog(context, 'location');
      }
    }
    return false;
  }

  /// Requests notification permission with a pre-prompt explanation dialog.
  Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (!context.mounted) return false;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, 'notification');
      return false;
    }

    final proceed = await _showExplanationDialog(
      context,
      titleKey: 'notification_permission_title',
      descKey: 'notification_permission_desc',
      defaultTitle: 'Notifications Required',
      defaultDesc:
          'Allow notifications to receive festival updates, calendar reminders and important announcements.',
      icon: Icons.notifications_active_rounded,
    );

    if (proceed == true) {
      final newStatus = await Permission.notification.request();
      if (!context.mounted) return false;
      if (newStatus.isGranted) {
        PushNotificationService()
            .requestNotificationPermission(forcePrompt: true);
        return true;
      }
      if (newStatus.isPermanentlyDenied) {
        _showPermanentlyDeniedDialog(context, 'notification');
      }
    }
    return false;
  }

  /// Generic request for other permissions if needed (e.g., Camera for Admin).
  Future<bool> requestPermission(BuildContext context, Permission permission,
      String nameKey, String defaultName) async {
    final status = await permission.status;
    if (!context.mounted) return false;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, nameKey);
      return false;
    }

    // Generic explanation
    final proceed = await _showExplanationDialog(
      context,
      titleKey: 'permission_required_title',
      descKey: 'permission_required_desc',
      defaultTitle: '$defaultName Required',
      defaultDesc:
          'This feature requires access to $defaultName to function correctly.',
      icon: Icons.security_rounded,
    );

    if (proceed == true) {
      final newStatus = await permission.request();
      if (!context.mounted) return false;
      if (newStatus.isGranted) return true;
      if (newStatus.isPermanentlyDenied) {
        _showPermanentlyDeniedDialog(context, nameKey);
      }
    }
    return false;
  }

  Future<bool?> _showExplanationDialog(
    BuildContext context, {
    required String titleKey,
    required String descKey,
    required String defaultTitle,
    required String defaultDesc,
    required IconData icon,
  }) async {
    final provider = TNTLocalizationsProvider.of(context);
    final localizations = provider?.localizations;
    String translate(String key, String def) =>
        localizations?.translate(key) ?? def;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translate(titleKey, defaultTitle),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          translate(descKey, defaultDesc),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(translate('not_now', 'Not Now'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(translate('allow', 'Allow')),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog(
      BuildContext context, String permissionKey) {
    final provider = TNTLocalizationsProvider.of(context);
    final localizations = provider?.localizations;
    String translate(String key, String def) =>
        localizations?.translate(key) ?? def;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(translate('permission_denied_title', 'Permission Denied')),
        content: Text(
          translate(
            'permission_denied_permanently_desc',
            'Permission is disabled. You can enable it from Settings.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(translate('cancel', 'Cancel'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(translate('open_settings', 'Open Settings')),
          ),
        ],
      ),
    );
  }
}
