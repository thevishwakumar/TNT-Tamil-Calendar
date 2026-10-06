import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_state_manager.dart';
import '../../auth/screens/profile_screen.dart';
import '../../special_days/screens/special_days_screen.dart';
import '../../festivals/screens/festivals_screen.dart';
import '../../saved/screens/saved_items_screen.dart';
import '../../reminders/screens/reminders_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/screens/notification_settings_screen.dart';
import 'about_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'privacy_permissions_screen.dart';

class MoreScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final AuthStateManager authStateManager;

  const MoreScreen({
    super.key,
    required this.apiService,
    required this.authStateManager,
  });

  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = TNTLocalizationsProvider.of(context);
    final localizations = provider?.localizations;
    final currentLang = localizations?.language ?? AppLanguage.tamil;
    String translate(String key) => localizations?.translate(key) ?? key;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          translate('more'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      actions: const [TNTBrandHeader()],
      ),
      body: ListenableBuilder(
        listenable: widget.authStateManager,
        builder: (context, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // User Profile Card Section
                _buildProfileSection(translate),
                const SizedBox(height: 12),

                // Calendrical Utilities Group
                _buildSectionHeader(translate('calendar_utilities')),
                _buildMenuTile(
                  Icons.star_outline_rounded,
                  translate('special_days'),
                  TNTColors.auspicious,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpecialDaysScreen(apiService: widget.apiService),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.festival_outlined,
                  translate('festivals'),
                  TNTColors.accent,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FestivalsScreen(apiService: widget.apiService),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.bookmark_outline_rounded,
                  translate('saved'),
                  TNTColors.primary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedItemsScreen(apiService: widget.apiService),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.alarm_rounded,
                  translate('reminder_btn'),
                  const Color(0xFFD97706),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RemindersScreen(apiService: widget.apiService),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 12),

                // Preferences & Actions Group
                _buildSectionHeader(translate('settings')),
                _buildMenuTile(
                  Icons.notifications_none_rounded,
                  translate('notifications'),
                  TNTColors.primary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(apiService: widget.apiService),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.tune_rounded,
                  translate('notification_settings'),
                  TNTColors.textSecondary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildLanguageToggleTile(localizations, currentLang, provider),
                _buildMenuTile(
                  Icons.info_outline_rounded,
                  translate('about_tnt'),
                  TNTColors.primary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.privacy_tip_rounded,
                  localizations?.language == AppLanguage.tamil ? 'தனியுரிமை மற்றும் அனுமதிகள்' : 'Privacy & Permissions',
                  TNTColors.primary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPermissionsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.gavel_rounded,
                  localizations?.language == AppLanguage.tamil ? 'விதிமுறைகள் & நிபந்தனைகள்' : 'Terms & Conditions',
                  TNTColors.textSecondary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  Icons.privacy_tip_outlined,
                  localizations?.language == AppLanguage.tamil ? 'தனியுரிமைக் கொள்கை' : 'Privacy Policy',
                  TNTColors.textSecondary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Account logout
                _buildMenuTile(
                  Icons.logout_rounded,
                  translate('logout'),
                  Colors.red,
                  () => _showLogoutDialog(context, translate),
                ),

                const SizedBox(height: 30),
                
                const Text(
                  'TNT Tamil Calendar v1.0.0',
                  style: TextStyle(fontSize: 11, color: TNTColors.textMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileSection(String Function(String) translate) {
    final profile = widget.authStateManager.currentProfile;
    final name = profile?.fullName ?? 'TNT User';
    final email = profile?.email ?? 'user@tntapp.com';
    final role = widget.authStateManager.isAdmin ? 'ADMIN' : 'USER';

    return Container(
      color: TNTColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      width: double.infinity,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: TNTColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2), width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person_rounded, size: 28, color: TNTColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.authStateManager.isAdmin ? Colors.red.shade50 : TNTColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.bold, 
                      color: widget.authStateManager.isAdmin ? Colors.red : TNTColors.primary, 
                      letterSpacing: 0.5
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: TNTColors.textMuted),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(authStateManager: widget.authStateManager),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textMuted, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      color: TNTColors.surface,
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: color == Colors.red ? Colors.red : TNTColors.textPrimary
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: TNTColors.textMuted),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
    );
  }

  Widget _buildLanguageToggleTile(
    TNTLocalizations? localizations,
    AppLanguage currentLang,
    TNTLocalizationsProvider? provider,
  ) {
    final title = localizations?.translate('language_selection') ?? 'Language / மொழி';
    
    return Container(
      color: TNTColors.surface,
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TNTColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.translate_rounded, size: 18, color: TNTColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TNTColors.textPrimary),
        ),
        trailing: Switch(
          value: currentLang == AppLanguage.english,
          activeThumbColor: TNTColors.primary,
          activeTrackColor: TNTColors.primary.withValues(alpha: 0.12),
          inactiveThumbColor: TNTColors.primaryDark,
          inactiveTrackColor: TNTColors.primaryDark.withValues(alpha: 0.12),
          onChanged: (bool isEnglish) {
            if (provider != null) {
              provider.onLanguageChanged(isEnglish ? AppLanguage.english : AppLanguage.tamil);
            }
          },
        ),
        subtitle: Text(
          currentLang == AppLanguage.tamil ? 'தமிழ் மொழி தேர்வு செய்யப்பட்டுள்ளது' : 'English language selected',
          style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String Function(String) translate) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: TNTColors.surface,
          title: Text(translate('logout')),
          content: Text(translate('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(translate('cancel'), style: const TextStyle(color: TNTColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.authStateManager.signOut();
              },
              child: Text(translate('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
