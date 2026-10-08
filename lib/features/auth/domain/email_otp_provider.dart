import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

/// Pluggable interface for Email 6-digit OTP delivery & verification
abstract class EmailOtpProvider {
  /// Send a 6-digit verification code to the given email address
  Future<bool> sendOtp(String email, {String? userId});

  /// Verify a 6-digit OTP code against the email and server challenge
  Future<bool> verifyOtp(String email, String otp);

  /// Resend verification code (subject to 60-second cooldown rate limit)
  Future<bool> resendOtp(String email, {String? userId});
}

/// Supabase Edge Function backed Email OTP Provider

/// Supabase Native Auth backed Email OTP Provider
class SupabaseEdgeFunctionEmailOtpProvider implements EmailOtpProvider {
  final SupabaseClient? _client;

  SupabaseEdgeFunctionEmailOtpProvider({SupabaseClient? client})
      : _client = client;

  @override
  Future<bool> sendOtp(String email, {String? userId}) async {
    final client = _client ?? SupabaseService().client;
    final cleanEmail = email.trim().toLowerCase();

    // 1. Try resending signup confirmation OTP first (for newly registered accounts)
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
      );
      return true;
    } catch (e) {
      // 2. If resend signup fails, fallback to signInWithOtp
      try {
        await client.auth.signInWithOtp(
          email: cleanEmail,
          shouldCreateUser: false,
        );
        return true;
      } catch (e2) {
        print('Error sending OTP: $e2');
        return false;
      }
    }
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    final client = _client ?? SupabaseService().client;
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    // 1. Try OtpType.signup first (for new signup confirmation)
    try {
      final response = await client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanOtp,
        type: OtpType.signup,
      );
      if (response.session != null || response.user != null) {
        return true;
      }
    } catch (e) {
      print('Signup OTP verification attempt error: $e');
    }

    // 2. Fallback to OtpType.email (magic link or signInWithOtp token)
    try {
      final response = await client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanOtp,
        type: OtpType.email,
      );
      return response.session != null || response.user != null;
    } catch (e2) {
      print('Email OTP verification attempt error: $e2');
      return false;
    }
  }

  @override
  Future<bool> resendOtp(String email, {String? userId}) async {
    return sendOtp(email, userId: userId);
  }
}
