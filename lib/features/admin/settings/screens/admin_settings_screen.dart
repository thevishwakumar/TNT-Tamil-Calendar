import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback onBackPressed;
  const AdminSettingsScreen({super.key, required this.onBackPressed});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Mock state for system settings
  bool _maintenanceMode = false;
  bool _forceAppUpdate = true;
  bool _disableUserRegistration = false;
  bool _enableDebugLogs = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.textPrimary),
                  onPressed: widget.onBackPressed,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.settings_rounded, color: TNTColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Admin Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // System Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TNTColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Configuration',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage global app behavior and maintenance states.',
                    style: TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingToggle(
                    'Maintenance Mode',
                    'Disable app access for users during server updates.',
                    Icons.build_circle_outlined,
                    _maintenanceMode,
                    (val) => setState(() => _maintenanceMode = val),
                    isDanger: true,
                  ),
                  const Divider(height: 24, color: TNTColors.border),
                  _buildSettingToggle(
                    'Force App Update',
                    'Require users to update to the latest app version.',
                    Icons.system_update_alt_rounded,
                    _forceAppUpdate,
                    (val) => setState(() => _forceAppUpdate = val),
                  ),
                  const Divider(height: 24, color: TNTColors.border),
                  _buildSettingToggle(
                    'Disable User Registration',
                    'Temporarily pause new user sign-ups.',
                    Icons.person_add_disabled_rounded,
                    _disableUserRegistration,
                    (val) => setState(() => _disableUserRegistration = val),
                  ),
                  const Divider(height: 24, color: TNTColors.border),
                  _buildSettingToggle(
                    'Enable Debug Logs',
                    'Collect verbose crash logs for admin monitoring.',
                    Icons.bug_report_outlined,
                    _enableDebugLogs,
                    (val) => setState(() => _enableDebugLogs = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Advanced Actions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TNTColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advanced Actions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Perform system-level cache clearing and resets.',
                    style: TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _buildActionRow(
                    'Clear App Cache',
                    'Purge server-side Redis and CDN cache layers.',
                    Icons.cleaning_services_rounded,
                    'Clear Cache',
                    () => _showDummyActionSnackbar('Server cache cleared successfully.'),
                  ),
                  const SizedBox(height: 16),
                  _buildActionRow(
                    'Sync Timezones',
                    'Force sync panchangam local timezone databases.',
                    Icons.sync_rounded,
                    'Force Sync',
                    () => _showDummyActionSnackbar('Timezones synchronized.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, size: 18, color: TNTColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secured with public.is_admin() database enforcement.',
                      style: TextStyle(
                        fontSize: 11,
                        color: TNTColors.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged, {bool isDanger = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDanger ? Colors.red.withValues(alpha: 0.1) : TNTColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: isDanger ? Colors.red : TNTColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDanger ? Colors.red : TNTColors.primary,
        ),
      ],
    );
  }

  Widget _buildActionRow(String title, String subtitle, IconData icon, String btnText, VoidCallback onPressed) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: TNTColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            btnText,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
          ),
        ),
      ],
    );
  }

  void _showDummyActionSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: TNTColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
