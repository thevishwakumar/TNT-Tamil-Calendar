import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/permission_service.dart';
import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';

class PrivacyPermissionsScreen extends StatefulWidget {
  const PrivacyPermissionsScreen({Key? key}) : super(key: key);

  @override
  _PrivacyPermissionsScreenState createState() => _PrivacyPermissionsScreenState();
}

class _PrivacyPermissionsScreenState extends State<PrivacyPermissionsScreen> with WidgetsBindingObserver {
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final location = await Permission.location.status;
    final notification = await Permission.notification.status;
    
    if (mounted) {
      setState(() {
        _locationStatus = location;
        _notificationStatus = notification;
        _isLoading = false;
      });
    }
  }

  String _getStatusText(PermissionStatus status, String Function(String) translate) {
    if (status.isGranted) return translate('status_allowed') == 'status_allowed' ? 'Allowed' : translate('status_allowed');
    if (status.isPermanentlyDenied) return translate('status_restricted') == 'status_restricted' ? 'Restricted' : translate('status_restricted');
    return translate('status_denied') == 'status_denied' ? 'Denied' : translate('status_denied');
  }

  Color _getStatusColor(PermissionStatus status) {
    if (status.isGranted) return Colors.green;
    if (status.isPermanentlyDenied) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final provider = TNTLocalizationsProvider.of(context);
    final localizations = provider?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;

    final title = translate('privacy_permissions') == 'privacy_permissions' ? 'Privacy & Permissions' : translate('privacy_permissions');

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: const [TNTBrandHeader()],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translate('permissions_desc') == 'permissions_desc' 
                  ? 'Manage your permissions. We only request permissions when necessary to provide you with the best experience.' 
                  : translate('permissions_desc'),
                style: const TextStyle(color: TNTColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              _buildPermissionCard(
                icon: Icons.location_on_rounded,
                title: translate('location_permission_title') == 'location_permission_title' ? 'Location' : translate('location_permission_title'),
                description: translate('location_permission_desc') == 'location_permission_desc' 
                  ? 'Required for accurate Panchangam, sunrise/sunset, and local events.' 
                  : translate('location_permission_desc'),
                status: _locationStatus,
                translate: translate,
                onRequest: () async {
                  await PermissionService().requestLocationPermission(context);
                  _checkPermissions();
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildPermissionCard(
                icon: Icons.notifications_active_rounded,
                title: translate('notification_permission_title') == 'notification_permission_title' ? 'Notifications' : translate('notification_permission_title'),
                description: translate('notification_permission_desc') == 'notification_permission_desc' 
                  ? 'Required to receive festival alerts and calendar reminders.' 
                  : translate('notification_permission_desc'),
                status: _notificationStatus,
                translate: translate,
                onRequest: () async {
                  await PermissionService().requestNotificationPermission(context);
                  _checkPermissions();
                },
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    required String Function(String) translate,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TNTColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: TNTColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TNTColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      '${translate("status") == "status" ? "Status" : translate("status")}: ${_getStatusText(status, translate)}', 
                      style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: status.isGranted ? () => openAppSettings() : onRequest,
              child: Text(
                status.isGranted || status.isPermanentlyDenied
                  ? (translate('manage_permission') == 'manage_permission' ? 'Manage Permission' : translate('manage_permission'))
                  : (translate('request_permission') == 'request_permission' ? 'Request Permission' : translate('request_permission')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
