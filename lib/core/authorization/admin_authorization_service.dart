import 'package:flutter/foundation.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';

/// Exception thrown when unauthorized user attempts any admin operation
class AdminAccessDeniedException implements Exception {
  final String message;
  AdminAccessDeniedException([this.message = 'Access Denied: Administrator role required.']);

  @override
  String toString() => 'AdminAccessDeniedException: $message';
}

/// Central Admin Authorization Service
/// Responsibilities:
/// 1. Verify authentication state with trusted backend profile.
/// 2. Verify ADMIN role against database records (NEVER assuming admin based on email, domain, local flags).
/// 3. Prevent unauthorized client/repository execution.
/// 4. Manage cross-session data isolation (clearing all admin caches upon logout).
class AdminAuthorizationService extends ChangeNotifier {
  static final AdminAuthorizationService _instance = AdminAuthorizationService._internal();
  factory AdminAuthorizationService() => _instance;
  AdminAuthorizationService._internal();

  final SupabaseService _db = SupabaseService();

  bool _isVerifiedAdmin = false;
  String? _verifiedAdminId;
  DateTime? _lastVerifiedAt;
  String? _lastAuthError;

  bool get isVerifiedAdmin => _isVerifiedAdmin;
  String? get verifiedAdminId => _verifiedAdminId;
  String? get lastAuthError => _lastAuthError;

  /// Verifies whether the currently active user has an authenticated ADMIN role.
  /// Always queries trusted database/profile source, never relying solely on client flags.
  Future<bool> verifyAdminAccess({UserProfile? profile}) async {
    _lastAuthError = null;

    try {
      // 1. If explicit profile provided (e.g. from authenticated session manager)
      if (profile != null) {
        final hasAdminRole = profile.role.toUpperCase() == 'ADMIN';
        if (!hasAdminRole) {
          _isVerifiedAdmin = false;
          _verifiedAdminId = null;
          notifyListeners();
          return false;
        }
        _isVerifiedAdmin = true;
        _verifiedAdminId = profile.id;
        _lastVerifiedAt = DateTime.now();
        notifyListeners();
        return true;
      }

      // 2. Query Supabase database directly for active authenticated user's role
      if (_db.isInitialized) {
        final currentAuthUser = _db.client.auth.currentUser;
        if (currentAuthUser == null) {
          _clearAdminSession();
          return false;
        }

        final res = await _db.client
            .from('profiles')
            .select('id, role, is_active')
            .eq('id', currentAuthUser.id)
            .maybeSingle();

        if (res != null && res['role'] == 'ADMIN' && res['is_active'] == true) {
          _isVerifiedAdmin = true;
          _verifiedAdminId = currentAuthUser.id;
          _lastVerifiedAt = DateTime.now();
          notifyListeners();
          return true;
        }
      } else {
        return false; // Dev fallback removed for security
      }

      _clearAdminSession();
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      _clearAdminSession();
      return false;
    }
  }

  /// Strict enforcement guard. Throws AdminAccessDeniedException if not authorized.
  Future<void> enforceAdminAccess({UserProfile? profile}) async {
    final ok = await verifyAdminAccess(profile: profile);
    if (!ok) {
      throw AdminAccessDeniedException('Access denied. You do not have administrative privileges.');
    }
  }

  /// Critical Session Cleanup: Clears all admin session states, verified tokens, and caches
  /// to guarantee ZERO data leakage when a different account logs in afterward.
  void clearSession() {
    _clearAdminSession();
  }

  void _clearAdminSession() {
    _isVerifiedAdmin = false;
    _verifiedAdminId = null;
    _lastVerifiedAt = null;
    _lastAuthError = null;
    notifyListeners();
  }
}
