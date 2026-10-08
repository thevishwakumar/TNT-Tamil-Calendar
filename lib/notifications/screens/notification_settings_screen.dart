import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/notification_service.dart';
import '../../services/device_service.dart';

/// Notification Preferences & Settings Screen
/// Controls:
/// - General: All Notifications master toggle
/// - Content: Panchangam, Muhurtham, Festivals, Special Days
/// - Personal: Reminders
/// - Other: Important Updates, Marketing / Promotional (Strictly OFF by default!)
/// - Registered Device & FCM Push Token status display
/// - Test Notification Trigger for live verification
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final DeviceService _deviceService = DeviceService();

  @override
  void initState() {
    super.initState();
    _notificationService.fetchPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    return ListenableBuilder(
      listenable: Listenable.merge([_notificationService, _deviceService]),
      builder: (context, _) {
        final prefs = _notificationService.preferences;
        final isMasterEnabled = prefs.allNotifications;

        return Scaffold(
          backgroundColor: TNTColors.background,
          appBar: AppBar(
            backgroundColor: TNTColors.surface,
            elevation: 0,
            title: Text(
              translate('notification_settings'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textPrimary, fontSize: 16),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: TNTColors.border, height: 1),
            ),
            actions: const [TNTBrandHeader()],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. General Master Switch Card
                _buildSectionHeader(isTamil ? 'பொதுவான அமைப்புகள்' : 'General'),
                _buildToggleCard(
                  title: isTamil ? 'அனைத்து அறிவிப்புகள்' : 'All Notifications',
                  subtitle: isTamil
                      ? 'அனைத்து அறிவிப்புகளையும் ஒரே நேரத்தில் இயக்க அல்லது முடக்க'
                      : 'Master switch to enable or pause all app notifications',
                  value: isMasterEnabled,
                  isMaster: true,
                  onChanged: (val) {
                    _notificationService.togglePreference('all', val);
                  },
                ),
                const SizedBox(height: 20),

                // 2. Content Notifications Group
                _buildSectionHeader(isTamil ? 'உள்ளடக்க அறிவிப்புகள்' : 'Content Notifications'),
                Container(
                  decoration: BoxDecoration(
                    color: TNTColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TNTColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildToggleTile(
                        icon: Icons.shield_moon_rounded,
                        iconColor: const Color(0xFF1E3A8A),
                        title: isTamil ? 'பஞ்சாங்கம் அறிவிப்புகள்' : 'Panchangam Notifications',
                        subtitle: isTamil
                            ? 'தினசரி முக்கிய நேரங்கள் மற்றும் சுப ஹோரைகள்'
                            : 'Daily auspicious timings, Nalla Neram & Gowri panchangam',
                        value: isMasterEnabled && prefs.panchangamNotifications,
                        enabled: isMasterEnabled,
                        onChanged: (val) => _notificationService.togglePreference('panchangam', val),
                      ),
                      const Divider(height: 1, color: TNTColors.border),
                      _buildToggleTile(
                        icon: Icons.favorite_rounded,
                        iconColor: TNTColors.primary,
                        title: isTamil ? 'முகூர்த்த அறிவிப்புகள்' : 'Muhurtham Notifications',
                        subtitle: isTamil
                            ? 'வரவிருக்கும் சுப முகூர்த்த நாட்கள் மற்றும் நேரங்கள்'
                            : 'Alerts for upcoming verified auspicious marriage & event dates',
                        value: isMasterEnabled && prefs.muhurthamNotifications,
                        enabled: isMasterEnabled,
                        onChanged: (val) => _notificationService.togglePreference('muhurtham', val),
                      ),
                      const Divider(height: 1, color: TNTColors.border),
                      _buildToggleTile(
                        icon: Icons.festival_rounded,
                        iconColor: TNTColors.accent,
                        title: isTamil ? 'பண்டிகை அறிவிப்புகள்' : 'Festival Notifications',
                        subtitle: isTamil
                            ? 'முக்கிய ஆன்மீகப் பண்டிகைகள் மற்றும் அரசு விடுமுறைகள்'
                            : 'Important Hindu, Christian, Muslim festivals & holidays',
                        value: isMasterEnabled && prefs.festivalNotifications,
                        enabled: isMasterEnabled,
                        onChanged: (val) => _notificationService.togglePreference('festivals', val),
                      ),
                      const Divider(height: 1, color: TNTColors.border),
                      _buildToggleTile(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: TNTColors.auspicious,
                        title: isTamil ? 'சிறப்பு நாள் அறிவிப்புகள்' : 'Special Day Notifications',
                        subtitle: isTamil
                            ? 'அமாவாசை, பௌர்ணமி, பிரதோஷம், சஷ்டி விரத எச்சரிக்கைகள்'
                            : 'Amavasai, Pournami, Pradosham, Ekadashi & Vrat alerts',
                        value: isMasterEnabled && prefs.specialDayNotifications,
                        enabled: isMasterEnabled,
                        onChanged: (val) => _notificationService.togglePreference('special_days', val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Personal Notifications Group
                _buildSectionHeader(isTamil ? 'தனிப்பட்டவை' : 'Personal Notifications'),
                Container(
                  decoration: BoxDecoration(
                    color: TNTColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TNTColors.border),
                  ),
                  child: _buildToggleTile(
                    icon: Icons.alarm_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: isTamil ? 'நினைவூட்டல் அறிவிப்புகள்' : 'Reminder Notifications',
                    subtitle: isTamil
                        ? 'நீங்கள் சேமித்த முகூர்த்தம் மற்றும் பண்டிகை நினைவூட்டல்கள்'
                        : 'Alerts for your saved reminders and personal alerts',
                    value: isMasterEnabled && prefs.reminderNotifications,
                    enabled: isMasterEnabled,
                    onChanged: (val) => _notificationService.togglePreference('reminders', val),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Other & Marketing Group (Explicit Opt-In Required!)
                _buildSectionHeader(isTamil ? 'மற்றவை மற்றும் விளம்பரங்கள்' : 'Other & Updates'),
                Container(
                  decoration: BoxDecoration(
                    color: TNTColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TNTColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildToggleTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: TNTColors.textPrimary,
                        title: isTamil ? 'முக்கிய பயன்பாட்டு புதுப்பிப்புகள்' : 'Important App Updates',
                        subtitle: isTamil
                            ? 'செயலியின் புதிய அம்சங்கள் மற்றும் அவசியமான அறிவிப்புகள்'
                            : 'Critical app upgrades and system maintenance notices',
                        value: isMasterEnabled && prefs.importantUpdates,
                        enabled: isMasterEnabled,
                        onChanged: (val) => _notificationService.togglePreference('important_updates', val),
                      ),
                      const Divider(height: 1, color: TNTColors.border),
                      _buildToggleTile(
                        icon: Icons.campaign_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        title: isTamil ? 'சலுகைகள் மற்றும் விளம்பரங்கள்' : 'Marketing & Promotions',
                        subtitle: isTamil
                            ? 'சிறப்பு விளம்பரங்கள் மற்றும் கூட்டாளர் சலுகைகள் (முன்னிருப்பாக முடக்கப்பட்டுள்ளது)'
                            : 'Special offers and campaign posters (OFF by default)',
                        value: prefs.marketingNotifications,
                        enabled: true, // Marketing is separately consent-controlled
                        onChanged: (val) => _notificationService.togglePreference('marketing', val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Device Push Token Status Card
                _buildDeviceTokenCard(isTamil),
                const SizedBox(height: 16),


              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: TNTColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isMaster = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value && isMaster ? TNTColors.primary.withValues(alpha: 0.4) : TNTColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (value ? TNTColors.primary : TNTColors.textMuted).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              value ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: value ? TNTColors.primary : TNTColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: TNTColors.textPrimary,
                  ),
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
            activeThumbColor: TNTColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final effectiveColor = enabled ? iconColor : TNTColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: enabled ? TNTColors.textPrimary : TNTColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled ? TNTColors.textSecondary : TNTColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: TNTColors.primary,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTokenCard(bool isTamil) {
    final dev = _deviceService.currentDevice;
    final isRegistered = _deviceService.isRegistered;
    final platform = _deviceService.currentPlatform.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(
                isRegistered ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 16,
                color: isRegistered ? Colors.green : TNTColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                isTamil ? 'சாதன புஷ் பதிவு நிலை' : 'Device Token Registration',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isRegistered ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRegistered ? (isTamil ? 'செயலில் உள்ளது' : 'ACTIVE') : (isTamil ? 'நிலுவையில்' : 'PENDING'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isRegistered ? Colors.green.shade700 : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTamil
                ? 'தளம்: $platform • டோக்கன்: ${dev?.deviceToken.substring(0, 16) ?? 'registered-session'}...'
                : 'Platform: $platform • FCM Token: ${dev?.deviceToken.substring(0, 16) ?? 'registered-session'}...',
            style: const TextStyle(fontSize: 10, color: TNTColors.textMuted, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
