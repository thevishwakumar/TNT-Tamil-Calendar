import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/legal_config.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/location_models.dart';
import '../../core/widgets/location_selector_modal.dart';
import '../../services/auth_state_manager.dart';
import '../../more/screens/terms_conditions_screen.dart';
import '../../more/screens/privacy_policy_screen.dart';

class SignupScreen extends StatefulWidget {
  final AuthStateManager authStateManager;
  final VoidCallback? onSignInTap;

  const SignupScreen({
    super.key,
    required this.authStateManager,
    this.onSignInTap,
  });

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _accountFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();

  int _currentStep = 1; // 1: Account, 2: Location & Legal Consent
  String _countryCode = '+91';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;
  String? _statusError;

  // Selected Location (Default: Coimbatore, Tamil Nadu, India)
  TNTCity _selectedLocation = const TNTCity(
    id: 'cbe',
    districtId: 'cbe_dist',
    stateId: 'tn',
    countryId: 'in',
    name: 'Coimbatore',
    nameTa: 'கோயம்புத்தூர்',
    latitude: 11.01,
    longitude: 76.95,
    timezone: 'Asia/Kolkata',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _goToStep2(bool isTamil) {
    if (!_accountFormKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _statusError = isTamil ? 'கடவுச்சொற்கள் பொருந்தவில்லை' : 'Passwords do not match');
      return;
    }

    setState(() {
      _statusError = null;
      _currentStep = 2;
    });
  }

  void _handleFinalSignUp(bool isTamil) async {
    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _statusError = isTamil
            ? 'தொடர்வதற்கு பயன்பாட்டு விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கவும்.'
            : 'Please accept Terms & Conditions and Privacy Policy to proceed.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusError = null;
    });

    final rawPhone = _mobileController.text.trim().replaceAll(' ', '');
    final normalizedMobile = rawPhone.isNotEmpty ? '$_countryCode$rawPhone' : '';

    try {
      await widget.authStateManager.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        mobile: normalizedMobile,
        termsAccepted: true,
      );

      // Save initial location preference
      if (widget.authStateManager.currentPreferences != null) {
        final updatedPrefs = widget.authStateManager.currentPreferences!.copyWith(
          location: _selectedLocation.name,
        );
        await widget.authStateManager.updatePreferences(updatedPrefs);
      }

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        setState(() {
          if (errorStr.contains('SocketException') || errorStr.contains('host lookup') || errorStr.contains('ClientException')) {
            _statusError = TNTLocalizationsProvider.of(context)?.localizations.translate('connection_error') ?? 'Please check your internet connection and try again.';
          } else if (errorStr.contains('PostgrestException') || errorStr.contains('PROFILE_UPSERT_FAILED')) {
            final isTa = TNTLocalizationsProvider.of(context)?.localizations.language == AppLanguage.tamil;
            _statusError = isTa ? 'சர்வர் பிழை. மீண்டும் முயற்சிக்கவும்.' : 'Server error. Please try again.';
          } else if (errorStr.contains('AuthException')) {
            final isTa = TNTLocalizationsProvider.of(context)?.localizations.language == AppLanguage.tamil;
            if (errorStr.contains('already registered')) {
              _statusError = isTa ? 'இந்த மின்னஞ்சல் / எண் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது' : 'This account is already registered.';
            } else {
              _statusError = isTa ? 'அங்கீகார பிழை. மீண்டும் முயற்சிக்கவும்.' : 'Authentication error. Please try again.';
            }
          } else {
            _statusError = errorStr.replaceAll(RegExp(r'TNTException\s*\([^)]*\):\s*|Exception:\s*'), '');
          }
          _isLoading = false;
        });
      }
    }
  }

  void _openLocationPicker(bool isTamil) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: LocationSelectorModal(
          initialCity: _selectedLocation,
          isTamil: isTamil,
          onCitySelected: (city) {
            setState(() {
              _selectedLocation = city;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final currentLang = TNTLocalizationsProvider.of(context)?.localizations.language ?? AppLanguage.tamil;
    final isTamil = currentLang == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        backgroundColor: TNTColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.textPrimary),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          isTamil ? 'புதிய கணக்கு' : 'Create Account',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        actions: [ const TNTBrandHeader(), 
          TextButton(
            onPressed: () {
              final provider = TNTLocalizationsProvider.of(context);
              if (currentLang == AppLanguage.english) {
                provider?.onLanguageChanged(AppLanguage.tamil);
              } else {
                provider?.onLanguageChanged(AppLanguage.english);
              }
            },
            child: Text(
              currentLang == AppLanguage.english ? 'தமிழ்' : 'English',
              style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: TNTColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep >= 2 ? TNTColors.primary : TNTColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTamil ? 'படி 1: கணக்கு விவரங்கள்' : 'Step 1: Account Info',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _currentStep == 1 ? TNTColors.primary : TNTColors.textSecondary,
                    ),
                  ),
                  Text(
                    isTamil ? 'படி 2: இருப்பிடம் & விதிமுறைகள்' : 'Step 2: Location & Terms',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _currentStep == 2 ? TNTColors.primary : TNTColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Single TNT Brand Mark
              Center(
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: const BoxDecoration(
                    color: TNTColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'TNT',
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _currentStep == 1
                    ? (isTamil ? 'கணக்கு விவரங்களை உள்ளிடவும்' : 'Enter Account Details')
                    : (isTamil ? 'இருப்பிடத்தைத் தேர்ந்தெடுக்கவும்' : 'Select Your Location'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
              ),
              const SizedBox(height: 4),

              Text(
                _currentStep == 1
                    ? (isTamil ? 'உங்கள் அடிப்படை தகவல்களை உள்ளிடவும்' : 'Fill in your personal details below')
                    : (isTamil ? 'பஞ்சாங்கம் & சூரியோதய கணக்கீட்டிற்கு இருப்பிடம் தேவை' : 'Required for daily sunrise, sunset & panchangam calculations'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Status / Error Alert Box
              if (_statusError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_statusError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // STEP 1: ACCOUNT FORM
              if (_currentStep == 1)
                Form(
                  key: _accountFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      Text(
                        isTamil ? 'முழு பெயர் *' : 'Full Name *',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isTamil ? 'உதாரணம்: ஆனந்தகிருஷ்ணன்' : 'e.g. Ananthakrishnan R',
                          hintStyle: const TextStyle(fontSize: 13, color: TNTColors.textMuted),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: TNTColors.primary, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.primary, width: 1.5)),
                          filled: true,
                          fillColor: TNTColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isTamil ? 'பெயரை உள்ளிடவும்' : 'Please enter your full name';
                          }
                          if (val.trim().length < 2) {
                            return isTamil ? 'குறைந்தது 2 எழுத்துகள் தேவை' : 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email Address
                      Text(
                        isTamil ? 'மின்னஞ்சல் முகவரி *' : 'Email Address *',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'name@email.com',
                          hintStyle: const TextStyle(fontSize: 13, color: TNTColors.textMuted),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: TNTColors.primary, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.primary, width: 1.5)),
                          filled: true,
                          fillColor: TNTColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isTamil ? 'மின்னஞ்சலை உள்ளிடவும்' : 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                            return isTamil ? 'சரியான மின்னஞ்சலை உள்ளிடவும்' : 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Optional Mobile Number (Clearly labeled OPTIONAL)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTamil ? 'கைபேசி எண்' : 'Mobile Number',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TNTColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTamil ? 'விருப்பத்திற்குரியது (Optional)' : 'Optional',
                              style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: TNTColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: TNTColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _countryCode,
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '+65', child: Text('🇸🇬 +65', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '+60', child: Text('🇲🇾 +60', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '+94', child: Text('🇱🇰 +94', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                                onChanged: (val) => setState(() => _countryCode = val ?? '+91'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: isTamil ? '9876543210 (விருப்பம்)' : '9876543210 (Optional)',
                                hintStyle: const TextStyle(fontSize: 13, color: TNTColors.textMuted),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.primary, width: 1.5)),
                                filled: true,
                                fillColor: TNTColors.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Password
                      Text(
                        isTamil ? 'கடவுச்சொல் *' : 'Password *',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          hintStyle: const TextStyle(fontSize: 13, color: TNTColors.textMuted),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: TNTColors.primary, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.primary, width: 1.5)),
                          filled: true,
                          fillColor: TNTColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return isTamil ? 'கடவுச்சொல்லை உள்ளிடவும்' : 'Please enter a password';
                          }
                          if (val.length < 6) {
                            return isTamil ? 'குறைந்தது 6 எழுத்துகள் தேவை' : 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      Text(
                        isTamil ? 'கடவுச்சொல்லை உறுதிப்படுத்தவும் *' : 'Confirm Password *',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          hintStyle: const TextStyle(fontSize: 13, color: TNTColors.textMuted),
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: TNTColors.primary, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.primary, width: 1.5)),
                          filled: true,
                          fillColor: TNTColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return isTamil ? 'கடவுச்சொல்லை மீண்டும் உள்ளிடவும்' : 'Please confirm your password';
                          }
                          if (val != _passwordController.text) {
                            return isTamil ? 'கடவுச்சொற்கள் பொருந்தவில்லை' : 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Next Button to Step 2
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _goToStep2(isTamil),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TNTColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isTamil ? 'அடுத்தது: இருப்பிடம் தேர்வு செய்க' : 'Next: Select Location',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // STEP 2: SEARCHABLE HIERARCHICAL LOCATION & LEGAL CONSENT
              if (_currentStep == 2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Card
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTamil ? 'தேர்ந்தெடுக்கப்பட்ட இருப்பிடம்' : 'Selected Location',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
                              ),
                              TextButton.icon(
                                onPressed: () => _openLocationPicker(isTamil),
                                icon: const Icon(Icons.edit_location_alt_rounded, size: 16, color: TNTColors.primary),
                                label: Text(
                                  isTamil ? 'மாற்று' : 'Change',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: TNTColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: TNTColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTamil ? _selectedLocation.nameTa : _selectedLocation.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedLocation.latitude.toStringAsFixed(2)}°N, ${_selectedLocation.longitude.toStringAsFixed(2)}°E • ${_selectedLocation.timezone}',
                                  style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Manual Selection Button
                    OutlinedButton.icon(
                      onPressed: () => _openLocationPicker(isTamil),
                      icon: const Icon(Icons.search_rounded, size: 18, color: TNTColors.primary),
                      label: Text(
                        isTamil ? 'நாடுகள் / நகரங்களைத் தேடவும்' : 'Search Countries / Cities',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TNTColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Legal Consent Checkboxes
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TNTColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TNTColors.border),
                      ),
                      child: Column(
                        children: [
                          // Terms of Service Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  activeColor: TNTColors.primary,
                                  onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text(
                                      isTamil ? 'எங்கள் ' : 'I agree to the ',
                                      style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const TermsConditionsScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        isTamil ? 'பயன்பாட்டு விதிமுறைகள் (v${TNTLegalConfig.termsVersion})' : 'Terms & Conditions (v${TNTLegalConfig.termsVersion})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: TNTColors.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isTamil ? ' ஐ ஏற்கிறேன்.' : '.',
                                      style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: TNTColors.border),

                          // Privacy Policy Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _privacyAccepted,
                                  activeColor: TNTColors.primary,
                                  onChanged: (val) => setState(() => _privacyAccepted = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text(
                                      isTamil ? 'எங்கள் ' : 'I agree to the ',
                                      style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const PrivacyPolicyScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        isTamil ? 'தனியுரிமைக் கொள்கை (v${TNTLegalConfig.privacyVersion})' : 'Privacy Policy (v${TNTLegalConfig.privacyVersion})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: TNTColors.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isTamil ? ' ஐ ஏற்கிறேன்.' : '.',
                                      style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Final Signup Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleFinalSignUp(isTamil),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TNTColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isTamil ? 'பதிவு செய்து தொடரவும்' : 'Sign Up & Continue',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Already have account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isTamil ? 'ஏற்கனவே கணக்கு உள்ளதா? ' : 'Already have an account? ',
                    style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (widget.onSignInTap != null) {
                        widget.onSignInTap!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      isTamil ? 'உள்நுழைக' : 'Sign In',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


