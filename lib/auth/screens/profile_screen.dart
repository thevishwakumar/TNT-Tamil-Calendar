import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/auth_state_manager.dart';
import '../../models/tnt_models.dart';

class ProfileScreen extends StatefulWidget {
  final AuthStateManager authStateManager;

  const ProfileScreen({super.key, required this.authStateManager});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;

  bool _isSaving = false;
  String? _statusError;
  String? _statusSuccess;

  @override
  void initState() {
    super.initState();
    final profile = widget.authStateManager.currentProfile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _mobileController = TextEditingController(text: ''); // Available in DB profiles mapping
    _cityController = TextEditingController(text: 'Chennai');
    _stateController = TextEditingController(text: 'Tamil Nadu');
    _countryController = TextEditingController(text: 'India');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _saveProfileChanges(TNTLocalizations localizations) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _statusError = null;
      _statusSuccess = null;
    });

    try {
      await widget.authStateManager.updateProfile(
        fullName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        city: _cityController.text.trim(),
      );
      
      setState(() {
        _statusSuccess = localizations.translate('profile_updated_successfully');
      });
    } catch (e) {
      setState(() {
        _statusError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;
    final profile = widget.authStateManager.currentProfile;
    final prefs = widget.authStateManager.currentPreferences;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          translate('profile'),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Identity Header Card
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: TNTColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 32, color: TNTColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? 'TNT User',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.email ?? 'user@tntapp.com',
                              style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.authStateManager.isAdmin
                                    ? Colors.red.shade50
                                    : TNTColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.authStateManager.isAdmin
                                    ? translate('admin_role_tag').toUpperCase()
                                    : translate('user_role_tag').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.authStateManager.isAdmin ? Colors.red : TNTColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (_statusSuccess != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _statusSuccess!,
                    style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (_statusError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _statusError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Edit Section Form
              Text(
                translate('full_name'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(),
                validator: (val) => (val == null || val.isEmpty) ? translate('field_cannot_be_empty') : null,
              ),
              const SizedBox(height: 14),

              Text(
                translate('mobile_number'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translate('city'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _cityController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _buildInputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translate('state'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _stateController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _buildInputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                translate('country'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _countryController,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(),
              ),
              const SizedBox(height: 24),

              // Save Changes Action Button
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveProfileChanges(localizations!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TNTColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        translate('save_btn'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),

              // Preferences Section
              Text(
                translate('notification_settings').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Column(
                  children: [
                    _buildPreferenceSwitchTile(
                      translate('enable_general_notif'),
                      prefs?.notificationsEnabled ?? true,
                      (bool val) {
                        widget.authStateManager.updatePreferences(
                          UserPreferences(
                            userId: profile?.id ?? '',
                            language: prefs?.language ?? 'ta',
                            location: prefs?.location ?? 'Chennai',
                            notificationsEnabled: val,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: TNTColors.border),
                    _buildPreferenceSwitchTile(translate('festival_notif'), true, null),
                    const Divider(height: 1, color: TNTColors.border),
                    _buildPreferenceSwitchTile(translate('muhurtham_notif'), true, null),
                    const Divider(height: 1, color: TNTColors.border),
                    _buildPreferenceSwitchTile(translate('special_day_notif'), true, null),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitchTile(String title, bool val, Function(bool)? onChanged) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      activeThumbColor: TNTColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TNTColors.textPrimary),
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: TNTColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TNTColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TNTColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TNTColors.primary, width: 1.5)),
    );
  }
}
