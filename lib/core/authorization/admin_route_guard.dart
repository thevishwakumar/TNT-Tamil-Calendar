import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_state_manager.dart';
import 'admin_authorization_service.dart';

/// Dedicated Admin Route Guard
/// Ensures that unauthenticated users or normal authenticated users
/// NEVER gain access to Admin screens or dashboard.
///
/// Behavior:
/// - If unauthenticated: -> Direct to Login or trigger unauthenticated fallback
/// - If authenticated USER: -> Deny access, route to User Home with security warning
/// - If authenticated ADMIN: -> Render the requested Admin screen
/// - If loading / verifying: -> Show secure loading state
class AdminRouteGuard extends StatefulWidget {
  final Widget child;
  final AuthStateManager authStateManager;
  final Widget? fallbackUserRoute;
  final Widget? fallbackUnauthenticatedRoute;

  const AdminRouteGuard({
    super.key,
    required this.child,
    required this.authStateManager,
    this.fallbackUserRoute,
    this.fallbackUnauthenticatedRoute,
  });

  @override
  _AdminRouteGuardState createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  final AdminAuthorizationService _authService = AdminAuthorizationService();
  bool _isChecking = true;
  bool _isAuthorizedAdmin = false;
  String? _guardError;

  @override
  void initState() {
    super.initState();
    _evaluateAdminAccess();
  }

  @override
  void didUpdateWidget(AdminRouteGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authStateManager.state != widget.authStateManager.state) {
      _evaluateAdminAccess();
    }
  }

  Future<void> _evaluateAdminAccess() async {
    setState(() {
      _isChecking = true;
      _guardError = null;
    });

    try {
      final authState = widget.authStateManager.state;
      if (authState == AppAuthState.unauthenticated) {
        setState(() {
          _isChecking = false;
          _isAuthorizedAdmin = false;
        });
        return;
      }

      final profile = widget.authStateManager.currentProfile;
      final isAdmin = await _authService.verifyAdminAccess(profile: profile);

      setState(() {
        _isChecking = false;
        _isAuthorizedAdmin = isAdmin;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _isAuthorizedAdmin = false;
        _guardError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: TNTColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: TNTColors.primary),
              SizedBox(height: 16),
              Text(
                'Verifying administrative credentials...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: TNTColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final authState = widget.authStateManager.state;

    // 1. Unauthenticated -> Redirect/Render unauthenticated fallback
    if (authState == AppAuthState.unauthenticated) {
      if (widget.fallbackUnauthenticatedRoute != null) {
        return widget.fallbackUnauthenticatedRoute!;
      }
      return Scaffold(
        backgroundColor: TNTColors.background,
        appBar: AppBar(
          title: const Text('Admin Access Required'),
          backgroundColor: TNTColors.surface,
          elevation: 0,
        actions: const [TNTBrandHeader()],
      ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You must be signed in with an administrative account to access this management area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: TNTColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Return to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Authenticated Normal USER -> Block Access (Forbidden)
    if (!_isAuthorizedAdmin) {
      if (widget.fallbackUserRoute != null) {
        return widget.fallbackUserRoute!;
      }
      return Scaffold(
        backgroundColor: TNTColors.background,
        appBar: AppBar(
          title: const Text('Restricted Access'),
          backgroundColor: TNTColors.surface,
          elevation: 0,
        actions: const [TNTBrandHeader()],
      ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account role (USER) does not have permission to view or manage admin consoles, private analytics, or internal schedules.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: TNTColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Authenticated ADMIN -> Render Admin content
    return widget.child;
  }
}
