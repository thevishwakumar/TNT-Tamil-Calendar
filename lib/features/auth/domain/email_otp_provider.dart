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
      : _client = client ?? SupabaseService().client;

  @override
  Future<bool> sendOtp(String email, {String? userId}) async {
    final client = _client ?? SupabaseService().client;

    try {
      await client.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: false, // Don't create if doesn't exist? Wait, we need it to create if signing up.
      );
      return true;
    } catch (e) {
      try {
        await client.auth.signInWithOtp(
          email: email.trim().toLowerCase(),
          shouldCreateUser: true,
        );
        return true;
      } catch (e2) {
        print('Error sending OTP: ');
        return false;
      }
    }
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    final client = _client ?? SupabaseService().client;

    try {
      final response = await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: otp.trim(),
        type: OtpType.email,
      );
      return response.session != null;
    } catch (e) {
      print('Error verifying OTP: ');
      return false;
    }
  }

  @override
  Future<bool> resendOtp(String email, {String? userId}) async {
    return sendOtp(email, userId: userId);
  }
}
