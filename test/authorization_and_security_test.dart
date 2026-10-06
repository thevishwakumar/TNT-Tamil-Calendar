import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_tamil_calendar/core/authorization/admin_authorization_service.dart';
import 'package:tnt_tamil_calendar/models/tnt_models.dart';

void main() {
  group('Security, RBAC & Role Isolation Tests', () {
    late AdminAuthorizationService authService;

    setUp(() {
      authService = AdminAuthorizationService();
    });

    test('Non-admin user profile is rejected by authorization gate', () async {
      final user = UserProfile(
        id: 'usr_normal',
        fullName: 'Normal Devotee',
        email: 'user@example.com',
        role: 'user',
        isGuest: false,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isAuthorized = await authService.verifyAdminAccess(profile: user);
      expect(isAuthorized, false, reason: 'USER role must never pass Admin Authorization check.');
    });

    test('Admin user profile is approved by authorization gate', () async {
      final admin = UserProfile(
        id: 'usr_admin',
        fullName: 'Admin Gurukkal',
        email: 'admin@tntcalendar.in',
        role: 'admin',
        isGuest: false,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isAuthorized = await authService.verifyAdminAccess(profile: admin);
      expect(isAuthorized, true, reason: 'ADMIN role must pass Admin Authorization check.');
    });

    test('Guest user is rejected by admin gate', () async {
      final guest = UserProfile(
        id: 'guest_1',
        fullName: 'Guest User',
        email: 'guest@example.com',
        role: 'user',
        isGuest: true,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isAuthorized = await authService.verifyAdminAccess(profile: guest);
      expect(isAuthorized, false, reason: 'Guest must never access Admin resources.');
    });

    test('Null profile is rejected by admin gate', () async {
      final isAuthorized = await authService.verifyAdminAccess(profile: null);
      expect(isAuthorized, false, reason: 'Unauthenticated session must be denied access.');
    });
  });
}
