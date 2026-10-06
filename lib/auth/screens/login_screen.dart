import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/auth_state_manager.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthStateManager authStateManager;
  final VoidCallback? onSignUpTap;
  final VoidCallback? onForgotPasswordTap;

  const LoginScreen({
    super.key,
    required this.authStateManager,
    this.onSignUpTap,
    this.onForgotPasswordTap,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _statusError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn(TNTLocalizations localizations) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusError = null;
    });

    try {
      await widget.authStateManager.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        setState(() {
          if (errorStr.contains('Invalid login credentials')) {
            _statusError = localizations!.language == AppLanguage.tamil
                ? 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறானது'
                : 'Invalid email or password';
          } else if (errorStr.contains('SocketException') || errorStr.contains('host lookup') || errorStr.contains('ClientException')) {
            _statusError = localizations?.translate('connection_error') ?? 'Please check your internet connection and try again.';
          } else if (errorStr.contains('PostgrestException') || errorStr.contains('PROFILE_UPSERT_FAILED') || errorStr.contains('AuthException')) {
            _statusError = localizations?.language == AppLanguage.tamil
                ? 'சர்வர் பிழை. மீண்டும் முயற்சிக்கவும்.'
                : 'Server error. Please try again.';
          } else {
            _statusError = errorStr.replaceAll(RegExp(r'TNTException\s*\([^)]*\):\s*|Exception:\s*'), '');
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await widget.authStateManager.signInWithGoogle();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final currentLang = TNTLocalizationsProvider.of(context)?.localizations.language ?? AppLanguage.tamil;
    final isTamil = currentLang == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Brand Header
                  Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.asset(
                  'assets/images/tnt_logo.jpg',
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
                  const SizedBox(height: 14),

                  // Header: TNT & Sign in to your account
                  const Text(
                    'TNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: TNTColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTamil ? 'உங்கள் கணக்கில் உள்நுழைக' : 'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TNTColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Display Authentication State Error
                  if (_statusError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusError!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Continue with Google
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TNTColors.surface,
                        foregroundColor: TNTColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(color: TNTColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: TNTColors.primary),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
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
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isTamil ? 'Google மூலம் தொடரவும்' : 'Continue with Google',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: TNTColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: TNTColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          isTamil ? 'அல்லது' : 'OR',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: TNTColors.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Email Input Field
                  Text(
                    isTamil ? 'மின்னஞ்சல் முகவரி' : 'Email',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TNTColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: TNTColors.surface,
                      hintText: 'name@email.com',
                      hintStyle: const TextStyle(color: TNTColors.textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: TNTColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: TNTColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: TNTColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return isTamil ? 'மின்னஞ்சலை உள்ளிடவும்' : 'Please enter your email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return isTamil ? 'சரியான மின்னஞ்சலை உள்ளிடவும்' : 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password Input Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTamil ? 'கடவுச்சொல்' : 'Password',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TNTColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.onForgotPasswordTap != null) {
                            widget.onForgotPasswordTap!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  authStateManager: widget.authStateManager,
                                  onBackToLoginTap: () => Navigator.pop(context),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          isTamil ? 'கடவுச்சொல் மறந்துவிட்டதா?' : 'Forgot Password?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TNTColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: TNTColors.surface,
                      hintText: '••••••',
                      hintStyle: const TextStyle(color: TNTColors.textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: TNTColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: TNTColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: TNTColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: TNTColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return isTamil ? 'கடவுச்சொல்லை உள்ளிடவும்' : 'Please enter your password';
                      }
                      if (val.length < 6) {
                        return isTamil ? 'குறைந்தது 6 எழுத்துகள் தேவை' : 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign In Action Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleSignIn(localizations!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TNTColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isTamil ? 'உள்நுழைக' : 'Sign In',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Create New Account Text Option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isTamil ? 'கணக்கு இல்லையா? ' : "Don't have an account? ",
                        style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                if (widget.onSignUpTap != null) {
                                  widget.onSignUpTap!();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SignupScreen(
                                        authStateManager: widget.authStateManager,
                                        onSignInTap: () => Navigator.pop(context),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          isTamil ? 'புதிய கணக்கு துவங்குக' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: TNTColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
