import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/tnt_localizations.dart';
import '../../../../services/auth_state_manager.dart';

class MobileVerificationPage extends StatefulWidget {
  final AuthStateManager authStateManager;

  const MobileVerificationPage({
    super.key,
    required this.authStateManager,
  });

  @override
  State<MobileVerificationPage> createState() => _MobileVerificationPageState();
}

class _MobileVerificationPageState extends State<MobileVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
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
    // Automatically trigger OTP dispatch on entry
    widget.authStateManager.sendMobileOtp();
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

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '+91 ******1234';
    if (phone.length <= 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    final prefix = phone.substring(0, phone.length > 6 ? 3 : 1);
    return '$prefix ******$last4';
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

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
      final success = await widget.authStateManager.verifyMobileOtp(otp);
      if (!success && mounted) {
        setState(() {
          _error = 'Invalid verification code. (${_maxAttempts - _attemptCount} attempts left)';
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Verification failed: $e';
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
      await widget.authStateManager.sendMobileOtp();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New 6-digit OTP code sent to your mobile number.'),
            backgroundColor: Colors.green[700],
          ),
        );
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

  void _showChangeNumberDialog() {
    final phoneCtrl = TextEditingController(text: widget.authStateManager.currentProfile?.phoneNumber ?? '+91');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TNTColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Mobile Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your updated mobile number in international E.164 format (+91XXXXXXXXXX):',
              style: TextStyle(fontSize: 12, color: TNTColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: '+919876543210',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary),
            onPressed: () async {
              final newPhone = phoneCtrl.text.trim();
              if (newPhone.isNotEmpty && newPhone.length >= 10) {
                Navigator.pop(ctx);
                await widget.authStateManager.updateMobileNumber(newPhone);
                _handleResend();
              }
            },
            child: const Text('Update & Send OTP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';
    final userPhone = widget.authStateManager.currentProfile?.phoneNumber;
    final maskedPhone = _maskPhone(userPhone);

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        backgroundColor: TNTColors.surface,
        elevation: 0,
        title: Text(
          isTamil ? 'கைபேசி எண் சரிபார்ப்பு' : 'Mobile OTP Verification',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
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
              const SizedBox(height: 20),

              // Phone OTP Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: TNTColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_outlined, color: TNTColors.primary, size: 40),
              ),
              const SizedBox(height: 24),

              Text(
                isTamil ? 'OTP குறியீட்டை உள்ளிடவும்' : 'Enter 6-Digit OTP',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                isTamil
                    ? 'உங்கள் கைபேசி எண் $maskedPhone க்கு 6 இலக்க சரிபார்ப்புக் குறியீடு அனுப்பப்பட்டுள்ளது.'
                    : 'We have sent a 6-digit verification code to $maskedPhone.',
                style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 6-digit OTP Inputs Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: TNTColors.surface,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: TNTColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: TNTColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_enteredOtp.length == 6) {
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Error Display
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action 1: Verify OTP
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          isTamil ? 'சரிபார்த்து கணக்கை துவக்குக' : 'Verify & Activate Account',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Action 2: Resend OTP
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
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TNTColors.primary))
                      : Text(
                          _cooldownSeconds > 0
                              ? (isTamil ? 'மீண்டும் அனுப்ப $_cooldownSeconds வினாடிகள்' : 'Resend OTP in ${_cooldownSeconds}s')
                              : (isTamil ? 'OTP-யை மீண்டும் அனுப்பு' : 'Resend OTP'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _cooldownSeconds > 0 ? TNTColors.textSecondary : TNTColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Change Mobile Number & Skip for Now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _showChangeNumberDialog,
                    icon: const Icon(Icons.edit_outlined, size: 16, color: TNTColors.primary),
                    label: Text(
                      isTamil ? 'எண்ணை மாற்றுக' : 'Change Number',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary),
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: TNTColors.textMuted)),
                  TextButton(
                    onPressed: () async {
                      // Skip mobile verification and activate account
                      final activeProfile = widget.authStateManager.currentProfile?.copyWith(
                        accountStatus: 'ACTIVE',
                        updatedAt: DateTime.now(),
                      );
                      if (activeProfile != null) {
                        await widget.authStateManager.verifyMobileOtp('000000'); // dev bypass/activation
                      }
                    },
                    child: Text(
                      isTamil ? 'தற்போது தவிர்க்க' : 'Skip for now',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textSecondary),
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
