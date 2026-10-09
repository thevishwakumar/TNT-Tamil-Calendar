import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/tnt_localizations.dart';
import '../../../../services/auth_state_manager.dart';
import '../../../../auth/screens/login_screen.dart';
import '../../../../auth/screens/signup_screen.dart';
import '../../../../more/screens/terms_conditions_screen.dart';
import '../../../../more/screens/privacy_policy_screen.dart';

class AuthWelcomePage extends StatefulWidget {
  final AuthStateManager authStateManager;

  const AuthWelcomePage({
    super.key,
    required this.authStateManager,
  });

  @override
  State<AuthWelcomePage> createState() => _AuthWelcomePageState();
}

class _AuthWelcomePageState extends State<AuthWelcomePage> {
  bool _isGoogleLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await widget.authStateManager.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        String errorText = e.toString();
        if (errorText.contains('SocketException') || errorText.contains('host lookup') || errorText.contains('ClientException')) {
          errorText = TNTLocalizationsProvider.of(context)?.localizations.translate('connection_error') ?? 'Please check your internet connection and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _toggleLanguage(String langCode) {
    widget.authStateManager.setLanguage(langCode);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';

    return Scaffold(
      backgroundColor: TNTColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Bar: Small Clean Language Selector (தமிழ் | English)
              // Top Bar: Small Clean Language Selector
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: TNTColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TNTColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _toggleLanguage('ta'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isTamil ? TNTColors.primary.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD', style: TextStyle(
                            color: isTamil ? TNTColors.primary : TNTColors.textSecondary,
                            fontWeight: isTamil ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          )),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _toggleLanguage('en'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: !isTamil ? TNTColors.primary.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('English', style: TextStyle(
                            color: !isTamil ? TNTColors.primary : TNTColors.textSecondary,
                            fontWeight: !isTamil ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // TOP: Centered Single TNT Logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 260,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Image.asset(
                      'assets/images/tnt_logo.jpg',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TNT Title & Tagline
              const Text(
                'TNT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: TNTColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isTamil
                    ? 'தமிழ் நாள்காட்டி & பஞ்சாங்கம்'
                    : 'Tamil Calendar & Panchangam',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: TNTColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Short Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  isTamil
                      ? 'உங்கள் தினசரி நாள்காட்டி மற்றும் பஞ்சாங்க வழிகாட்டி'
                      : 'Your daily Tamil Calendar & Panchangam',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TNTColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Primary Button: Continue with Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.surface,
                    foregroundColor: TNTColors.textPrimary,
                    elevation: 0,
                    side: const BorderSide(color: TNTColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: TNTColors.primary),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isTamil
                                  ? 'Google மூலம் தொடரவும்'
                                  : 'Continue with Google',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: TNTColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Button: Continue with Email / Mobile
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignupScreen(
                            authStateManager: widget.authStateManager),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        isTamil
                            ? 'மின்னஞ்சல் / கைபேசி மூலம் பதிவு செய்ய'
                            : 'Continue with Email / Mobile',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Already have an account? Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isTamil
                        ? 'ஏற்கனவே கணக்கு உள்ளதா? '
                        : 'Already have an account? ',
                    style: const TextStyle(
                        fontSize: 13, color: TNTColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                              authStateManager: widget.authStateManager),
                        ),
                      );
                    },
                    child: Text(
                      isTamil ? 'உள்நுழைக' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // LEGAL LINKS AT BOTTOM (Tappable links to full legal pages)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isTamil
                          ? 'தொடர்வதன் மூலம், எங்கள் '
                          : 'By continuing, you agree to our ',
                      style: const TextStyle(
                          fontSize: 11, color: TNTColors.textMuted),
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
                        isTamil ? 'Terms & Conditions' : 'Terms & Conditions',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      isTamil ? ' மற்றும் ' : ' and ',
                      style: const TextStyle(
                          fontSize: 11, color: TNTColors.textMuted),
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
                        isTamil ? 'Privacy Policy' : 'Privacy Policy',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      isTamil ? ' ஐ ஏற்கிறீர்கள்.' : '.',
                      style: const TextStyle(
                          fontSize: 11, color: TNTColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
