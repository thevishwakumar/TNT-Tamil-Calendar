import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/tnt_localizations.dart';
import '../../../../services/auth_state_manager.dart';

class EmailVerificationPage extends StatefulWidget {
  final AuthStateManager authStateManager;

  const EmailVerificationPage({
    super.key,
    required this.authStateManager,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;
  int _attemptCount = 0;
  static const int _maxAttempts = 5;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name****@$domain';
    return '${name.substring(0, 1)}****${name.substring(name.length - 1)}@$domain';
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  void _handleVerify() async {
    final otp = _enteredOtp;
    if (otp.length != 6) {
      setState(() => _error = 'Please enter a valid 6-digit verification code.');
      return;
    }

    if (_attemptCount >= _maxAttempts) {
      setState(() => _error = 'Maximum verification attempts exceeded. Please resend a new OTP.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
      _attemptCount++;
    });

    try {
      final success = await widget.authStateManager.verifyEmailOtp(otp);
      if (!success && mounted) {
        setState(() {
          final remaining = _maxAttempts - _attemptCount;
          _error = remaining > 0
              ? 'Invalid verification code. ($remaining attempt${remaining > 1 ? 's' : ''} left)'
              : 'Maximum verification attempts exceeded. Please resend a new OTP.';
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Verification error: $e';
          _isVerifying = false;
        });
      }
    }
  }

  void _handleResend() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _error = null;
      _attemptCount = 0;
      for (final c in _otpControllers) {
        c.clear();
      }
    });

    try {
      await widget.authStateManager.resendVerificationEmail();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A new 6-digit OTP code has been sent to your email.'),
            backgroundColor: Colors.green[700],
          ),
        );
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to resend OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';
    final userEmail = widget.authStateManager.currentProfile?.email ?? 'your email';
    final maskedEmail = _maskEmail(userEmail);

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        backgroundColor: TNTColors.surface,
        elevation: 0,
        title: Text(
          isTamil ? 'மின்னஞ்சல் OTP சரிபார்ப்பு' : 'Email OTP Verification',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TNTColors.textPrimary,
          ),
        ),
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: isTamil ? 'வெளியேறு' : 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => widget.authStateManager.signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Email OTP Shield Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: TNTColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: TNTColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isTamil ? 'மின்னஞ்சல் சரிபார்ப்புக் குறியீடு' : 'Enter 6-Digit Email OTP',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TNTColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                isTamil
                    ? '6-இலக்க சரிபார்ப்புக் குறியீடு $maskedEmail முகவரிக்கு அனுப்பப்பட்டுள்ளது.'
                    : 'A 6-digit numeric verification code has been sent to $maskedEmail.',
                style: const TextStyle(
                  fontSize: 13,
                  color: TNTColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Security & 5-min expiry pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: TNTColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: TNTColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      isTamil ? 'குறியீடு 5 நிமிடங்களுக்கு செல்லுபடியாகும்' : 'Code expires in 5 minutes',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TNTColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 6-Digit Pin Input Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: TNTColors.surface,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: TNTColors.border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: TNTColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _handleVerify();
                          }
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Verify Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isTamil ? 'சரிபார் & தொடரவும்' : 'Verify & Continue',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend OTP Button with Cooldown
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: (_cooldownSeconds > 0 || _isResending) ? null : _handleResend,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TNTColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TNTColors.primary,
                          ),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? (isTamil
                                  ? 'மீண்டும் அனுப்ப $_cooldownSeconds விநாடிகள்'
                                  : 'Resend OTP in ${_cooldownSeconds}s')
                              : (isTamil ? 'புதிய OTP அனுப்புக' : 'Resend Verification Code'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _cooldownSeconds > 0
                                ? TNTColors.textSecondary
                                : TNTColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Wrong email option / sign out
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isTamil ? 'தவறான மின்னஞ்சலா? ' : 'Wrong email address? ',
                    style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => widget.authStateManager.signOut(),
                    child: Text(
                      isTamil ? 'வெளியேறி மீண்டும் பதிவு செய்க' : 'Sign Out & Retry',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
