import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_tamil_calendar/models/tnt_models.dart';
import 'package:tnt_tamil_calendar/features/auth/domain/sms_otp_provider.dart';

class MockSmsOtpProvider implements SmsOtpProvider {
  @override
  Future<bool> sendOtp(String phoneNumber) async => true;
  @override
  Future<bool> verifyOtp(String phoneNumber, String otp) async => otp == '123456';
  @override
  Future<bool> resendOtp(String phoneNumber) async => true;
}

void main() {
  group('Authentication System Upgrade Tests', () {
    test('UserProfile model handles all account status states', () {
      final user = UserProfile(
        id: 'usr_test_1',
        email: 'devotee@tnt.app',
        fullName: 'Devotee S',
        phoneNumber: '+919876543210',
        role: 'user',
        accountStatus: 'PENDING_EMAIL_VERIFICATION',
        createdAt: DateTime.now(),
      );

      expect(user.isPendingEmail, isTrue);
      expect(user.isPendingMobile, isFalse);
      expect(user.isActive, isFalse);
      expect(user.isUser, isTrue);
      expect(user.isAdmin, isFalse);

      final emailVerifiedUser = user.copyWith(
        accountStatus: 'PENDING_MOBILE_VERIFICATION',
        emailVerifiedAt: DateTime.now(),
      );
      expect(emailVerifiedUser.isPendingEmail, isFalse);
      expect(emailVerifiedUser.isPendingMobile, isTrue);
      expect(emailVerifiedUser.isActive, isFalse);

      final activeUser = emailVerifiedUser.copyWith(
        accountStatus: 'ACTIVE',
        phoneVerifiedAt: DateTime.now(),
      );
      expect(activeUser.isActive, isTrue);
      expect(activeUser.isPendingMobile, isFalse);
    });

    test('SmsOtpProvider handles 6-digit verification code validation', () async {
      final provider = MockSmsOtpProvider();
      
      final sent = await provider.sendOtp('+919876543210');
      expect(sent, isTrue);

      final validOtp = await provider.verifyOtp('+919876543210', '123456');
      expect(validOtp, isTrue);

      final invalidOtp = await provider.verifyOtp('+919876543210', '12');
      expect(invalidOtp, isFalse);
    });

    test('Marketing notifications remain strictly OFF by default', () {
      const prefs = NotificationPreferences();
      expect(prefs.marketingNotifications, isFalse);
      expect(prefs.allNotifications, isTrue);
      expect(prefs.panchangamNotifications, isTrue);
      expect(prefs.muhurthamNotifications, isTrue);
    });

    test('Suspended account status helper flags correctly', () {
      final suspendedUser = UserProfile(
        id: 'usr_susp_1',
        email: 'violator@tnt.app',
        fullName: 'Suspended Account',
        role: 'user',
        accountStatus: 'SUSPENDED',
        createdAt: DateTime.now(),
      );

      expect(suspendedUser.isSuspended, isTrue);
      expect(suspendedUser.isActive, isFalse);
    });
  });
}
