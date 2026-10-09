import 'package:flutter/material.dart';
import '../repositories/tnt_repositories.dart' hide AuthState;
import '../models/tnt_models.dart';
import '../features/auth/domain/sms_otp_provider.dart';
import '../features/auth/domain/email_otp_provider.dart';
import 'supabase_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/authorization/admin_authorization_service.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

enum AppAuthState {
  loading,
  unauthenticated,
  pendingEmailVerification,
  pendingMobileVerification,
  authenticatedUser,
  authenticatedAdmin,
  suspended,
  error,
}

class AuthStateManager extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final UserPreferencesRepository _prefRepo = UserPreferencesRepository();
  final SmsOtpProvider _smsOtpProvider = SupabaseEdgeFunctionSmsOtpProvider();
  final EmailOtpProvider _emailOtpProvider =
      SupabaseEdgeFunctionEmailOtpProvider();

  AppAuthState _state = AppAuthState.loading;
  UserProfile? _currentProfile;
  UserPreferences? _currentPreferences;
  String? _errorMessage;

  AppAuthState get state => _state;

  void retry() {
    _initializeAuth();
  }

  UserProfile? get currentProfile => _currentProfile;
  UserPreferences? get currentPreferences => _currentPreferences;
  String? get errorMessage => _errorMessage;
  String? get currentEmail =>
      _currentProfile?.email ??
      (SupabaseService().isInitialized
          ? SupabaseService().client.auth.currentUser?.email
          : null);

  bool get isLoading => _state == AppAuthState.loading;
  bool get isAuthenticated =>
      _state == AppAuthState.authenticatedUser ||
      _state == AppAuthState.authenticatedAdmin;
  bool get isAdmin => _state == AppAuthState.authenticatedAdmin;

  AuthStateManager() {
    _initializeAuth();
  }

  /// Initial entry point: checks active session, verifies email & mobile status, routes to appropriate state
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> _initializeAuth() async {
    print('[STARTUP] main started');
    print('[STARTUP] Supabase initialization started');
    _state = AppAuthState.loading;
    notifyListeners();

    try {
      await SupabaseService().init();
      print('[STARTUP] Supabase initialization completed');

      _authSubscription =
          SupabaseService().client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        print(
            'TNT Auth Event: ${event.name} | Session exists: ${session != null}');

        if (event == AuthChangeEvent.signedIn && session != null) {
          final user = session.user;
          print('TNT Auth: SIGNED_IN for user ${user.id}');
          // Load if not loaded, profile id differs, or transitioning from pending email verification
          if (_currentProfile?.id != user.id ||
              _state == AppAuthState.pendingEmailVerification) {
            loadUserSession(user.id, user.email ?? '');
          } else {
            print(
                'TNT Auth: Profile already loaded for this user. Skipping loadUserSession.');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          print('TNT Auth: SIGNED_OUT event received');
          _state = AppAuthState.unauthenticated;
          _currentProfile = null;
          _currentPreferences = null;
          AdminAuthorizationService().clearSession();
          NotificationService().clearSession();
          notifyListeners();
        }
      });

      print('[STARTUP] Auth restoration started');
      final active = await _authRepo.isSessionActive();
      if (!active) {
        print('[STARTUP] Auth restoration completed (No active session)');
        print('[STARTUP] Initial navigation started');
        _state = AppAuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final currentUser = SupabaseService().client.auth.currentUser;
      if (currentUser == null) {
        print('[STARTUP] Auth restoration completed (No current user)');
        print('[STARTUP] Initial navigation started');
        _state = AppAuthState.unauthenticated;
        notifyListeners();
        return;
      }

      await loadUserSession(currentUser.id, currentUser.email ?? '');
    } catch (e) {
      print('TNT Auth: _initializeAuth EXCEPTION: $e');
      _errorMessage = e.toString();
      _state = AppAuthState.error;
      notifyListeners();
    }
  }

  /// Load user profile and evaluate verification stages (Email -> Mobile -> Active)
  Future<void> loadUserSession(String userId, String email) async {
    print('TNT Auth: Starting loadUserSession for $userId');

    // FAST STARTUP: Optimistically unblock UI before network calls
    final authUser = SupabaseService().isInitialized
        ? SupabaseService().client.auth.currentUser
        : null;
    final isEmailConfirmed = authUser?.emailConfirmedAt != null;

    if (_state == AppAuthState.loading) {
      _state = isEmailConfirmed
          ? AppAuthState.authenticatedUser
          : AppAuthState.pendingEmailVerification;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _profileRepo.fetchUserProfile(userId),
        _prefRepo.fetchUserPreferences(userId),
      ]).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('connection_error');
      });
      print('[STARTUP] Auth restoration completed (Profile loaded)');
      print('[STARTUP] Initial navigation started');

      var profile = results[0] as UserProfile?;
      var prefs = results[1] as UserPreferences?;

      print('TNT Auth: fetchUserProfile returned: ${profile != null}');

      final authUser = SupabaseService().isInitialized
          ? SupabaseService().client.auth.currentUser
          : null;
      final isEmailConfirmed = authUser?.emailConfirmedAt != null;

      if (profile == null) {
        profile = UserProfile(
          id: userId,
          email: email,
          fullName: authUser?.userMetadata?['full_name'] as String? ??
              email.split('@')[0],
          phoneNumber: authUser?.userMetadata?['phone'] as String?,
          role: 'user', // strictly default USER role
          accountStatus:
              isEmailConfirmed ? 'ACTIVE' : 'PENDING_EMAIL_VERIFICATION',
          emailVerifiedAt: isEmailConfirmed ? DateTime.now() : null,
          createdAt: DateTime.now(),
        );
        // Only await this if it's a new user creation
        await _profileRepo.upsertUserProfile(profile);
      }

      _currentProfile = profile;
      _currentPreferences = prefs ??
          UserPreferences(
            userId: userId,
            language: 'ta',
            location: 'Chennai',
            notificationsEnabled: true,
          );

      // Check account status & route
      if (profile.isSuspended) {
        _state = AppAuthState.suspended;
      } else if (profile.isAdmin) {
        // Admins bypass normal public OTP verification
        _state = AppAuthState.authenticatedAdmin;
      } else if (!isEmailConfirmed &&
          profile.accountStatus == 'PENDING_EMAIL_VERIFICATION') {
        _state = AppAuthState.pendingEmailVerification;
      } else if (profile.accountStatus == 'PENDING_MOBILE_VERIFICATION') {
        _state = AppAuthState.pendingMobileVerification;
      } else {
        _state = AppAuthState.authenticatedUser;
      }
      if (_state == AppAuthState.authenticatedUser ||
          _state == AppAuthState.authenticatedAdmin) {
        PushNotificationService().syncTokenWithBackend();
      }
      print('TNT Auth: loadUserSession success. Final state: $_state');

      _errorMessage = null;
    } catch (e) {
      print('TNT Auth: loadUserSession EXCEPTION: $e');
      _errorMessage = e.toString();
      _state = AppAuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Google Sign-In Flow
  Future<void> signInWithGoogle() async {
    print('TNT Auth: signInWithGoogle started');
    _state = AppAuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseService().isInitialized) {
        print('TNT Auth: Calling _authRepo.signInWithGoogle()');
        await _authRepo.signInWithGoogle();
        print('TNT Auth: signInWithOAuth returned true (launched browser)');
        // Do not check currentUser here immediately.
        // The browser is opened and the flow is asynchronous.
        // We will rely on the onAuthStateChange listener to update the state once signed in.
        // We also clear the loading state so the user isn't stuck if they cancel.
        _state = AppAuthState.unauthenticated;
        notifyListeners();
        return;
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('host lookup') ||
          errorStr.contains('ClientException')) {
        _errorMessage = 'connection_error';
      } else {
        _errorMessage = errorStr;
      }
      _state = AppAuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// SignUp Action - Creates Auth account and puts profile into PENDING_EMAIL_VERIFICATION
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobile,
    required bool termsAccepted,
  }) async {
    if (!termsAccepted) {
      throw Exception(
          'You must accept the Terms of Service and Privacy Policy to create an account.');
    }

    _state = AppAuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseService().isInitialized) {
        final res = await _authRepo.signUp(
          email: email,
          password: password,
          fullName: fullName,
        );

        final user = res.user;
        if (user != null) {
          final pendingProfile = UserProfile(
            id: user.id,
            email: email,
            fullName: fullName,
            phoneNumber: mobile,
            role: 'user',
            accountStatus: 'PENDING_EMAIL_VERIFICATION',
            createdAt: DateTime.now(),
          );
          await _profileRepo.upsertUserProfile(pendingProfile);
          _currentProfile = pendingProfile;
          _state = AppAuthState.pendingEmailVerification;
          notifyListeners();
          return;
        }
      }

      throw Exception('Supabase initialization failed or network error');
    } catch (e) {
      _errorMessage = e.toString();
      _state = AppAuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// Dispatch 6-digit numeric OTP to current profile's email
  Future<bool> sendEmailOtp() async {
    final email = currentEmail;
    if (email == null) return false;
    return await _emailOtpProvider.sendOtp(email, userId: _currentProfile?.id);
  }

  /// Verify 6-digit Email OTP and progress user directly to Active state
  Future<bool> verifyEmailOtp(String otp) async {
    final email = currentEmail;
    if (email == null) return false;

    final isOtpValid = await _emailOtpProvider.verifyOtp(email, otp);
    if (!isOtpValid) return false;

    try {
      final currentUser = SupabaseService().isInitialized
          ? SupabaseService().client.auth.currentUser
          : null;
      final userId = _currentProfile?.id ?? currentUser?.id;
      if (userId == null) return false;

      UserProfile activeProfile;
      if (_currentProfile != null) {
        activeProfile = _currentProfile!.copyWith(
          emailVerifiedAt: DateTime.now(),
          accountStatus: 'ACTIVE',
          updatedAt: DateTime.now(),
        );
      } else {
        final fetched = await _profileRepo.fetchUserProfile(userId);
        if (fetched != null) {
          activeProfile = fetched.copyWith(
            emailVerifiedAt: DateTime.now(),
            accountStatus: 'ACTIVE',
            updatedAt: DateTime.now(),
          );
        } else {
          activeProfile = UserProfile(
            id: userId,
            email: email,
            fullName: currentUser?.userMetadata?['full_name'] as String? ??
                email.split('@')[0],
            phoneNumber: currentUser?.userMetadata?['phone'] as String?,
            role: 'user',
            accountStatus: 'ACTIVE',
            emailVerifiedAt: DateTime.now(),
            createdAt: DateTime.now(),
          );
        }
      }

      if (SupabaseService().isInitialized) {
        await _profileRepo.upsertUserProfile(activeProfile);
      }
      _currentProfile = activeProfile;

      // Ensure default user preferences
      _currentPreferences =
          await _prefRepo.fetchUserPreferences(activeProfile.id) ??
              UserPreferences(
                userId: activeProfile.id,
                language: 'ta',
                location: 'Chennai',
                notificationsEnabled: true,
              );
      await _prefRepo.savePreferences(_currentPreferences!);

      final isSystemAdmin = activeProfile.isAdmin;
      _state = isSystemAdmin
          ? AppAuthState.authenticatedAdmin
          : AppAuthState.authenticatedUser;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check Email Verification Status from actual Supabase Auth state (Legacy/Auto fallback)
  Future<bool> checkEmailVerificationStatus() async {
    final email = currentEmail;
    if (email == null) return false;

    try {
      if (SupabaseService().isInitialized) {
        final res = await SupabaseService().client.auth.getUser();
        final user = res.user;
        if (user?.emailConfirmedAt != null) {
          final updated = (_currentProfile ??
                  UserProfile(
                    id: user!.id,
                    email: email,
                    fullName: user.userMetadata?['full_name'] as String? ??
                        email.split('@')[0],
                    role: 'user',
                    accountStatus: 'ACTIVE',
                    createdAt: DateTime.now(),
                  ))
              .copyWith(
            emailVerifiedAt: DateTime.now(),
            accountStatus: 'ACTIVE',
            updatedAt: DateTime.now(),
          );

          if (SupabaseService().isInitialized) {
            await _profileRepo.upsertUserProfile(updated);
          }
          _currentProfile = updated;

          _currentPreferences =
              await _prefRepo.fetchUserPreferences(updated.id) ??
                  UserPreferences(
                    userId: updated.id,
                    language: 'ta',
                    location: 'Chennai',
                    notificationsEnabled: true,
                  );
          await _prefRepo.savePreferences(_currentPreferences!);

          _state = updated.isAdmin
              ? AppAuthState.authenticatedAdmin
              : AppAuthState.authenticatedUser;
          notifyListeners();
          return true;
        }
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Resend 6-digit email OTP (enforces 60s cooldown on edge function/client)
  Future<void> resendVerificationEmail() async {
    final email = currentEmail;
    if (email == null) return;
    await _emailOtpProvider.resendOtp(email, userId: _currentProfile?.id);
  }

  /// Send 6-digit Mobile OTP
  Future<bool> sendMobileOtp() async {
    if (_currentProfile?.phoneNumber == null) return false;
    return await _smsOtpProvider.sendOtp(_currentProfile!.phoneNumber!);
  }

  /// Verify 6-digit Mobile OTP and activate account
  Future<bool> verifyMobileOtp(String otp) async {
    if (_currentProfile == null || _currentProfile!.phoneNumber == null)
      return false;

    final isOtpValid =
        await _smsOtpProvider.verifyOtp(_currentProfile!.phoneNumber!, otp);
    if (!isOtpValid) return false;

    try {
      final activeProfile = _currentProfile!.copyWith(
        phoneVerifiedAt: DateTime.now(),
        accountStatus: 'ACTIVE',
        updatedAt: DateTime.now(),
      );

      await _profileRepo.upsertUserProfile(activeProfile);
      _currentProfile = activeProfile;

      // Ensure default user preferences with marketing OFF
      _currentPreferences =
          await _prefRepo.fetchUserPreferences(activeProfile.id) ??
              UserPreferences(
                userId: activeProfile.id,
                language: 'ta',
                location: 'Chennai',
                notificationsEnabled: true,
                // marketingNotifications: false,
              );
      await _prefRepo.savePreferences(_currentPreferences!);

      final isSystemAdmin = activeProfile.isAdmin;
      _state = isSystemAdmin
          ? AppAuthState.authenticatedAdmin
          : AppAuthState.authenticatedUser;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update Mobile Number during verification
  Future<void> updateMobileNumber(String newPhone) async {
    if (_currentProfile == null) return;
    final updated = _currentProfile!
        .copyWith(phoneNumber: newPhone, updatedAt: DateTime.now());
    await _profileRepo.upsertUserProfile(updated);
    _currentProfile = updated;
    notifyListeners();
  }

  /// SignIn Action with account state routing
  Future<void> signIn({required String email, required String password}) async {
    _state = AppAuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseService().isInitialized) {
        final res = await _authRepo.signIn(email: email, password: password);
        final user = res.user;
        if (user != null) {
          await loadUserSession(user.id, user.email ?? email);
          return;
        }
      }

      throw Exception('Invalid credentials or network error');
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('host lookup') ||
          errorStr.contains('ClientException')) {
        _errorMessage = 'connection_error';
      } else {
        _errorMessage = errorStr;
      }
      _state = AppAuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// Forgot password handler
  Future<void> forgotPassword(String email) async {
    try {
      if (SupabaseService().isInitialized) {
        await SupabaseService().client.auth.resetPasswordForEmail(email);
      }
    } catch (e) {
      throw Exception('Failed to send recovery email: $e');
    }
  }

  /// Verify OTP and reset password
  Future<void> verifyOtpAndResetPassword(
      String email, String otp, String newPassword) async {
    try {
      if (SupabaseService().isInitialized) {
        final res = await SupabaseService().client.auth.verifyOTP(
              email: email,
              token: otp,
              type: OtpType.recovery,
            );

        if (res.user != null) {
          await SupabaseService().client.auth.updateUser(
                UserAttributes(password: newPassword),
              );
        } else {
          throw Exception("Invalid OTP");
        }
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Change active language preference
  void setLanguage(String langCode) {
    if (_currentPreferences != null) {
      final updated = _currentPreferences!.copyWith(language: langCode);
      updatePreferences(updated);
    }
  }

  /// Update Profile Fields safely
  Future<void> updateProfile(
      {required String fullName, String? mobile, String? city}) async {
    if (_currentProfile == null) return;
    try {
      final updated = await _profileRepo.updateUserProfile(
        _currentProfile!.id,
        fullName: fullName,
        mobile: mobile,
        city: city,
      );
      _currentProfile = updated;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update Preferences
  Future<void> updatePreferences(UserPreferences prefs) async {
    try {
      await _prefRepo.savePreferences(prefs);
      _currentPreferences = prefs;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  /// Secure Sign Out & reset application state
  Future<void> signOut() async {
    _state = AppAuthState.loading;
    notifyListeners();
    try {
      await _authRepo.signOut();
    } catch (_) {
    } finally {
      _currentProfile = null;
      _currentPreferences = null;
      _state = AppAuthState.unauthenticated;
      _errorMessage = null;
      AdminAuthorizationService().clearSession();
      NotificationService().clearSession();
      PushNotificationService().onLogout();
      notifyListeners();
    }
  }
}
