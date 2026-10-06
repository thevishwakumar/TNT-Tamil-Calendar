import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/colors.dart';
import 'core/localization/tnt_localizations.dart';
import 'home/screens/home_screen.dart';
import 'calendar/screens/calendar_screen.dart';
import 'panchangam/screens/panchangam_screen.dart';
import 'muhurtham/screens/muhurtham_screen.dart';
import 'more/screens/more_screen.dart';
import 'services/supabase_service.dart';
import 'services/production_api_service.dart';
import 'services/auth_state_manager.dart';
import 'admin/screens/admin_dashboard.dart';
import 'main_screen.dart';
import 'features/auth/presentation/pages/auth_welcome_page.dart';
import 'features/auth/presentation/pages/email_verification_page.dart';
import 'features/auth/presentation/pages/mobile_verification_page.dart';
import 'features/auth/presentation/pages/account_status_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env.staging");
  } catch (e) {
    print('Could not load .env.staging: ');
  }
  
  // We do NOT await SupabaseService().init() here to avoid long white screen!
  // Instead, it is initialized asynchronously. We trigger it immediately.
  SupabaseService().init();

  final apiService = SupabaseApiService();

  runApp(TNTApp(apiService: apiService));
}

class TNTApp extends StatefulWidget {
  final ITNTApiService apiService;

  const TNTApp({super.key, required this.apiService});

  @override
  _TNTAppState createState() => _TNTAppState();
}

class _TNTAppState extends State<TNTApp> {
  AppLanguage _currentLanguage = AppLanguage.tamil; 
  late AuthStateManager _authStateManager;

  @override
  void initState() {
    super.initState();
    _authStateManager = AuthStateManager();
  }

  void _handleLanguageChanged(AppLanguage lang) {
    setState(() {
      _currentLanguage = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TNTLocalizationsProvider(
      localizations: TNTLocalizations(_currentLanguage),
      onLanguageChanged: _handleLanguageChanged,
      child: MaterialApp(
        title: 'TNT Tamil Calendar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: TNTColors.primary,
          scaffoldBackgroundColor: TNTColors.background,
          colorScheme: const ColorScheme.light(
            primary: TNTColors.primary,
            secondary: TNTColors.accent,
            surface: TNTColors.surface,
            onPrimary: Colors.white,
            onSecondary: TNTColors.textPrimary,
          ),
          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          fontFamilyFallback: const ['Noto Sans Tamil', 'Mukta Malar', 'sans-serif'],
        ),
        home: AuthStateGateway(
          authStateManager: _authStateManager,
          apiService: widget.apiService,
        ),
      ),
    );
  }
}

class AuthStateGateway extends StatefulWidget {
  final AuthStateManager authStateManager;
  final ITNTApiService apiService;

  const AuthStateGateway({
    Key? key,
    required this.authStateManager,
    required this.apiService,
  }) : super(key: key);

  @override
  _AuthStateGatewayState createState() => _AuthStateGatewayState();
}

class _AuthStateGatewayState extends State<AuthStateGateway> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authStateManager,
      builder: (context, _) {
        final state = widget.authStateManager.state;

        switch (state) {
          case AppAuthState.loading:
            return Scaffold(
              backgroundColor: TNTColors.surface,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/tnt_logo.jpg',
                      height: 220,
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(color: TNTColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      TNTLocalizationsProvider.of(context)?.localizations.translate('loading_tnt') ?? 'Loading TNT Tamil Calendar...',
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w500, 
                        color: TNTColors.textSecondary
                      ),
                    ),
                  ],
                ),
              ),
            );

          case AppAuthState.unauthenticated:
            return AuthWelcomePage(authStateManager: widget.authStateManager);

          case AppAuthState.pendingEmailVerification:
            return EmailVerificationPage(authStateManager: widget.authStateManager);

          case AppAuthState.pendingMobileVerification:
            return MobileVerificationPage(authStateManager: widget.authStateManager);

          case AppAuthState.authenticatedUser:
            return MainScreen(apiService: widget.apiService, authStateManager: widget.authStateManager);

          case AppAuthState.authenticatedAdmin:
            return AdminDashboard(authStateManager: widget.authStateManager);

          case AppAuthState.suspended:
            return AccountStatusPage(authStateManager: widget.authStateManager);

          case AppAuthState.error:
            return Scaffold(
              backgroundColor: TNTColors.surface,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/tnt_logo.jpg',
                      height: 120,
                      width: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      TNTLocalizationsProvider.of(context)?.localizations.language == AppLanguage.tamil
                          ? 'TNT Tamil Calendar ஏற்ற முடியவில்லை'
                          : 'Unable to load TNT Tamil Calendar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TNTColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TNTLocalizationsProvider.of(context)?.localizations.translate(
                          widget.authStateManager.errorMessage ?? 'An error occurred') ??
                          (widget.authStateManager.errorMessage ?? 'An error occurred'),
                      style: const TextStyle(color: TNTColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TNTColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      onPressed: () => widget.authStateManager.retry(),
                      child: Text(TNTLocalizationsProvider.of(context)?.localizations.translate('retry_btn') ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
