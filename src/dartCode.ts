export const dartFiles: { [key: string]: string } = {
  "pubspec.yaml": `name: tnt
description: "TNT - Tamil Calendar, Panchangam & Muhurtham Application."
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.5
  supabase_flutter: ^2.5.0
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true`,

  "supabase_migration.sql": `-- TNT Supabase Database Migration
-- PostgreSQL schema foundation with Row-Level Security (RLS) triggers

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    mobile TEXT,
    role TEXT NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
    language TEXT NOT NULL DEFAULT 'ta' CHECK (language IN ('ta', 'en')),
    city TEXT,
    state TEXT,
    country TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. User Preferences Table
CREATE TABLE public.user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    language TEXT NOT NULL DEFAULT 'ta',
    notifications_enabled BOOLEAN DEFAULT true,
    festival_notifications BOOLEAN DEFAULT true,
    muhurtham_notifications BOOLEAN DEFAULT true,
    special_day_notifications BOOLEAN DEFAULT true,
    marketing_notifications BOOLEAN DEFAULT false,
    location_permission_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Calendar Days Table
CREATE TABLE public.calendar_days (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE UNIQUE NOT NULL,
    tamil_date TEXT NOT NULL,
    tamil_month TEXT NOT NULL,
    tamil_year TEXT NOT NULL,
    weekday_tamil TEXT NOT NULL,
    weekday_english TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18. Admin Schedules Table (Strictly Confidential)
CREATE TABLE public.admin_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_date DATE NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    mandapam TEXT NOT NULL,
    event_type TEXT NOT NULL,
    marriage_details TEXT,
    internal_notes TEXT,
    status TEXT NOT NULL DEFAULT 'CONFIRMED',
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_schedules ENABLE ROW LEVEL SECURITY;

-- Security helper functions
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  );
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
CREATE POLICY "Profiles read" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles update own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Trigger: Automatically seed profile and preferences upon Auth SignUp
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role, language)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    'USER', -- Always default to non-privileged USER role
    COALESCE(new.raw_user_meta_data->>'language', 'ta')
  );

  INSERT INTO public.user_preferences (user_id, language)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'language', 'ta'));

  RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();`,

  "lib/services/auth_state_manager.dart": `import 'package:flutter/material.dart';
import '../repositories/tnt_repositories.dart';
import '../models/tnt_models.dart';
import 'supabase_service.dart';

enum AppAuthState {
  loading,
  unauthenticated,
  authenticatedUser,
  authenticatedAdmin,
  error
}

class AuthStateManager extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final UserPreferencesRepository _prefRepo = UserPreferencesRepository();
  
  AppAuthState _state = AppAuthState.loading;
  UserProfile? _currentProfile;
  UserPreferences? _currentPreferences;
  String? _errorMessage;

  AppAuthState get state => _state;
  UserProfile? get currentProfile => _currentProfile;
  UserPreferences? get currentPreferences => _currentPreferences;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == AppAuthState.loading;
  bool get isAuthenticated => _state == AppAuthState.authenticatedUser || _state == AppAuthState.authenticatedAdmin;
  bool get isAdmin => _state == AppAuthState.authenticatedAdmin;

  AuthStateManager() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _state = AppAuthState.loading;
    notifyListeners();

    try {
      final active = await _authRepo.isSessionActive();
      if (!active) {
        _state = AppAuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final currentUser = SupabaseService().client.auth.currentUser;
      if (currentUser == null) {
        _state = AppAuthState.unauthenticated;
        notifyListeners();
        return;
      }

      await loadUserSession(currentUser.id, currentUser.email ?? '');
    } catch (e) {
      _errorMessage = e.toString();
      _state = AppAuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> loadUserSession(String userId, String email) async {
    _state = AppAuthState.loading;
    notifyListeners();

    try {
      var profile = await _profileRepo.fetchUserProfile(userId);
      if (profile == null) {
        profile = UserProfile(
          id: userId,
          email: email,
          fullName: email.split('@')[0],
          role: 'user',
          createdAt: DateTime.now(),
        );
      }

      _currentProfile = profile;
      _currentPreferences = await _prefRepo.fetchUserPreferences(userId) ?? UserPreferences(
        userId: userId,
        language: 'ta',
        location: 'Chennai',
        notificationsEnabled: true,
      );

      final isSystemAdmin = profile.role.toLowerCase() == 'admin';
      _state = isSystemAdmin ? AppAuthState.authenticatedAdmin : AppAuthState.authenticatedUser;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AppAuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String mobile = '',
  }) async {
    _state = AppAuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authRepo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      final user = res.user;
      if (user != null) {
        await loadUserSession(user.id, user.email ?? email);
      } else {
        _state = AppAuthState.unauthenticated;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AppAuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _state = AppAuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authRepo.signIn(email: email, password: password);
      final user = res.user;
      if (user != null) {
        await loadUserSession(user.id, user.email ?? email);
      } else {
        _state = AppAuthState.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AppAuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      if (SupabaseService().isInitialized) {
        await SupabaseService().client.auth.resetPasswordForEmail(email);
      }
    } catch (e) {
      throw Exception('Failed to send recovery email: $e');
    }
  }

  Future<void> updateProfile({required String fullName, String? mobile, String? city}) async {
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

  Future<void> updatePreferences(UserPreferences prefs) async {
    try {
      await _prefRepo.savePreferences(prefs);
      _currentPreferences = prefs;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

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
      notifyListeners();
    }
  }
}`,

  "lib/features/auth/presentation/pages/auth_welcome_page.dart": `import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/tnt_localizations.dart';
import '../../../../services/auth_state_manager.dart';
import '../../../../auth/screens/login_screen.dart';
import '../../../../auth/screens/signup_screen.dart';

class AuthWelcomePage extends StatefulWidget {
  final AuthStateManager authStateManager;
  const AuthWelcomePage({Key? key, required this.authStateManager}) : super(key: key);
  @override
  State<AuthWelcomePage> createState() => _AuthWelcomePageState();
}`,

  "lib/auth/screens/signup_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/legal_config.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/location_models.dart';
import '../../core/widgets/location_selector_modal.dart';
import '../../services/auth_state_manager.dart';

class SignupScreen extends StatefulWidget {
  final AuthStateManager authStateManager;
  final VoidCallback? onSignInTap;
  const SignupScreen({Key? key, required this.authStateManager, this.onSignInTap}) : super(key: key);
  @override
  _SignupScreenState createState() => _SignupScreenState();
}`,

  "lib/models/location_models.dart": `/// Hierarchical Location Models: Country -> State -> District -> City
class TNTCountry { final String code, nameEn, nameTa, flag; const TNTCountry({required this.code, required this.nameEn, required this.nameTa, required this.flag}); }
class TNTState { final String id, countryCode, nameEn, nameTa; const TNTState({required this.id, required this.countryCode, required this.nameEn, required this.nameTa}); }
class TNTDistrict { final String id, stateId, nameEn, nameTa; const TNTDistrict({required this.id, required this.stateId, required this.nameEn, required this.nameTa}); }
class TNTCity { final String id, districtId, stateId, countryCode, nameEn, nameTa; final double latitude, longitude; final String timezone; const TNTCity({required this.id, required this.districtId, required this.stateId, required this.countryCode, required this.nameEn, required this.nameTa, required this.latitude, required this.longitude, required this.timezone}); }`,

  "lib/core/widgets/location_selector_modal.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/location_models.dart';

class LocationSelectorModal extends StatefulWidget {
  final TNTLocationSelection? initialSelection;
  final bool isTamil;
  final Function(TNTLocationSelection) onLocationSelected;
  const LocationSelectorModal({Key? key, this.initialSelection, required this.isTamil, required this.onLocationSelected}) : super(key: key);
}`,

  "lib/auth/screens/login_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/auth_state_manager.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthStateManager authStateManager;
  final VoidCallback? onSignUpTap;
  final VoidCallback? onForgotPasswordTap;

  const LoginScreen({
    Key? key,
    required this.authStateManager,
    this.onSignUpTap,
    this.onForgotPasswordTap,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _statusError;

  void _handleSignIn(TNTLocalizations localizations) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _statusError = null;
    });

    try {
      await widget.authStateManager.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _statusError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final translate = (String key) => localizations?.translate(key) ?? key;

    return Scaffold(
      backgroundColor: TNTColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: TNTColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('TNT', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(translate('app_name'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Text(translate('email'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.isEmpty) ? translate('field_cannot_be_empty') : null,
                  ),
                  const SizedBox(height: 14),
                  Text(translate('password'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleSignIn(localizations!),
                    style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary),
                    child: Text(translate('sign_in'), style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: widget.onSignUpTap,
                    child: Text(translate('create_account'), textAlign: TextAlign.center, style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}`,

  "lib/auth/screens/profile_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/auth_state_manager.dart';
import '../../models/tnt_models.dart';

class ProfileScreen extends StatefulWidget {
  final AuthStateManager authStateManager;

  const ProfileScreen({Key? key, required this.authStateManager}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.authStateManager.currentProfile?.fullName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final translate = (String k) => TNTLocalizationsProvider.of(context)?.localizations.translate(k) ?? k;
    
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(title: Text(translate('profile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(translate('full_name'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextFormField(controller: _nameController, decoration: const InputDecoration(filled: true, fillColor: Colors.white)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.authStateManager.updateProfile(fullName: _nameController.text);
                },
                style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary),
                child: Text(translate('save_btn'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}`,

  "lib/admin/screens/admin_dashboard.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../services/auth_state_manager.dart';

class AdminDashboard extends StatefulWidget {
  final AuthStateManager authStateManager;

  const AdminDashboard({Key? key, required this.authStateManager}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final translate = (String k) => TNTLocalizationsProvider.of(context)?.localizations.translate(k) ?? k;
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(translate('admin_dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => widget.authStateManager.signOut(),
          )
        ],
      ),
      body: Center(
        child: Text('Admin Dashboard - Authorized Actions Securely Guarded'),
      ),
    );
  }
}`,

  "lib/main.dart": `import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'core/localization/tnt_localizations.dart';
import 'services/auth_state_manager.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('TNT Calendar App')))));
}`,

  "lib/calendar/screens/calendar_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';
import 'date_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final Function(int)? onTabChanged;

  const CalendarScreen({Key? key, required this.apiService, this.onTabChanged}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Calendar rendering & query range loading...
}`,

  "lib/calendar/screens/date_details_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class DateDetailsScreen extends StatefulWidget {
  final DateTime date;
  final ITNTApiService apiService;

  const DateDetailsScreen({Key? key, required this.date, required this.apiService}) : super(key: key);

  @override
  _DateDetailsScreenState createState() => _DateDetailsScreenState();
}`,

  "lib/panchangam/screens/panchangam_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../models/panchangam_bundle.dart';
import '../repositories/panchangam_repository.dart';
import '../widgets/panchangam_header.dart';
import '../widgets/panchangam_date_bar.dart';
import '../widgets/panchangam_overview_card.dart';
import '../widgets/sun_moon_card.dart';
import '../widgets/timing_card.dart';
import '../widgets/special_observance_card.dart';
import '../widgets/muhurtham_status_card.dart';

class PanchangamScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final DateTime? initialDate;

  const PanchangamScreen({Key? key, required this.apiService, this.initialDate}) : super(key: key);

  @override
  _PanchangamScreenState createState() => _PanchangamScreenState();
}`,

  "lib/panchangam/widgets/panchangam_overview_card.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class PanchangamOverviewCard extends StatelessWidget {
  final PanchangamEntry panchangam;
  final CalendarDay? calendarDay;
  final DateTime date;

  const PanchangamOverviewCard({
    Key? key,
    required this.panchangam,
    required this.calendarDay,
    required this.date,
  }) : super(key: key);
}`,

  "lib/panchangam/widgets/sun_moon_card.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class SunMoonCard extends StatelessWidget {
  final PanchangamEntry panchangam;

  const SunMoonCard({Key? key, required this.panchangam}) : super(key: key);
}`,

  "lib/panchangam/widgets/timing_card.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class TimingCard extends StatelessWidget {
  final TimingEntry timing;

  const TimingCard({Key? key, required this.timing}) : super(key: key);
}`,

  "lib/panchangam/repositories/panchangam_repository.dart": `import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../models/panchangam_bundle.dart';

class PanchangamRepository {
  final PanchangamDataProvider dataProvider;
  final Map<String, PanchangamDailyBundle> _cache = {};

  PanchangamRepository({required this.dataProvider});

  Future<PanchangamDailyBundle?> getPanchangamBundle(
    DateTime date, {
    String location = 'Chennai',
    bool forceRefresh = false,
  }) async {
    // Queries Supabase & caches results
  }
}`,

  "lib/muhurtham/screens/muhurtham_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';
import '../widgets/muhurtham_date_card.dart';
import 'muhurtham_detail_screen.dart';

/// Main Muhurtham Screen supporting monthly browsing, city selector,
/// dynamic categories (Marriage, Housewarming, etc.), and auspicious phase filters.
class MuhurthamScreen extends StatefulWidget {
  final ITNTApiService apiService;
  final Function(int)? onTabChanged;

  const MuhurthamScreen({Key? key, required this.apiService, this.onTabChanged}) : super(key: key);

  @override
  _MuhurthamScreenState createState() => _MuhurthamScreenState();
}`,

  "lib/muhurtham/screens/muhurtham_detail_screen.dart": `import 'package:flutter/material.dart';
import '../../models/tnt_models.dart';
import '../../services/supabase_service.dart';

/// Dedicated Muhurtham Detail Screen providing:
/// - Gregorian & Tamil calendar header (Purattasi/Aippasi, day, location)
/// - Approved Muhurtham verification badge
/// - Timing breakdown: Start/End, duration, lagnam, nakshatra, subha horai
/// - Inauspicious times to avoid: Rahu Kalam, Yamagandam, Kuligai
/// - Astrological guidance, Save/Bookmark, Reminders, and Share.
class MuhurthamDetailScreen extends StatefulWidget {
  final MuhurthamDate muhurtham;
  final ITNTApiService apiService;
  final Function(int)? onNavigateTab;

  const MuhurthamDetailScreen({
    Key? key,
    required this.muhurtham,
    required this.apiService,
    this.onNavigateTab,
  }) : super(key: key);
}`,

  "lib/muhurtham/widgets/muhurtham_date_card.dart": `import 'package:flutter/material.dart';
import '../../models/tnt_models.dart';

/// Reusable MuhurthamDateCard:
/// Displays date, Tamil date, day, month, category badge, timing count,
/// auspicious phase (Valarpirai/Theipirai), and Save/Reminder/Share buttons.
class MuhurthamDateCard extends StatelessWidget {
  final MuhurthamDate item;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;
  final VoidCallback onSetReminder;
  final VoidCallback onShare;

  const MuhurthamDateCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onToggleSave,
    required this.onSetReminder,
    required this.onShare,
  }) : super(key: key);
}`,

  "lib/muhurtham/widgets/muhurtham_reminder_dialog.dart": `import 'package:flutter/material.dart';
import '../../models/tnt_models.dart';

/// Dialog allowing user to schedule alarms (1 day before, day-of morning 6 AM, or 1 hr prior).
class MuhurthamReminderDialog extends StatefulWidget {
  final MuhurthamDate muhurtham;
  final Function(String offsetLabel, DateTime scheduledTime) onConfirm;

  const MuhurthamReminderDialog({Key? key, required this.muhurtham, required this.onConfirm}) : super(key: key);
}`,

  "lib/muhurtham/widgets/muhurtham_share_sheet.dart": `import 'package:flutter/material.dart';
import '../../models/tnt_models.dart';

/// Bottom sheet formatting formatted Tamil and English messages ready to copy & share.
class MuhurthamShareSheet extends StatelessWidget {
  final MuhurthamDate muhurtham;

  const MuhurthamShareSheet({Key? key, required this.muhurtham}) : super(key: key);
}`,

  "lib/services/device_service.dart": `import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/tnt_models.dart';
import 'supabase_service.dart';

/// Device Push Notification & FCM Token Management Service
/// Architecture: Flutter App -> DeviceService -> Supabase (user_devices) -> Secure Backend -> FCM
class DeviceService extends ChangeNotifier {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final SupabaseService _db = SupabaseService();
  UserDevice? _currentDevice;
  String? _currentToken;
  bool _isRegistering = false;

  UserDevice? get currentDevice => _currentDevice;
  bool get isRegistered => _currentDevice != null && _currentDevice!.isActive;

  String get currentPlatform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  Future<UserDevice?> registerDeviceToken({String? token, String? appVersion = '1.0.0'}) async {
    _isRegistering = true;
    notifyListeners();

    final activeToken = token ?? _currentToken ?? 'fcm_tnt_\${currentPlatform}_\${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    _currentToken = activeToken;

    final device = UserDevice(
      id: 'dev-device-\${activeToken.hashCode.abs()}',
      userId: 'dev-user-id-001',
      deviceToken: activeToken,
      platform: currentPlatform,
      appVersion: appVersion,
      isActive: true,
      lastSeenAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentDevice = device;
    _isRegistering = false;
    notifyListeners();
    return device;
  }

  Future<void> deactivateOnLogout() async {
    if (_currentDevice != null) {
      _currentDevice = _currentDevice!.copyWith(isActive: false);
      notifyListeners();
    }
  }
}`,

  "lib/services/notification_service.dart": `import 'package:flutter/material.dart';
import '../models/tnt_models.dart';
import 'supabase_service.dart';
import 'device_service.dart';

enum NotificationPermissionStatus { notDetermined, granted, denied }

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DeviceService _deviceService = DeviceService();
  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.notDetermined;
  NotificationPreferences _preferences = const NotificationPreferences();
  final List<NotificationItem> _notifications = [];

  NotificationPermissionStatus get permissionStatus => _permissionStatus;
  NotificationPreferences get preferences => _preferences;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<bool> requestPermission() async {
    _permissionStatus = NotificationPermissionStatus.granted;
    await _deviceService.registerDeviceToken();
    _preferences = _preferences.copyWith(allNotifications: true);
    notifyListeners();
    return true;
  }

  void dismissPermission() {
    _permissionStatus = NotificationPermissionStatus.denied;
    notifyListeners();
  }

  Future<void> togglePreference(String key, bool value) async {
    switch (key) {
      case 'all': _preferences = _preferences.copyWith(allNotifications: value); break;
      case 'panchangam': _preferences = _preferences.copyWith(panchangamNotifications: value); break;
      case 'muhurtham': _preferences = _preferences.copyWith(muhurthamNotifications: value); break;
      case 'festivals': _preferences = _preferences.copyWith(festivalNotifications: value); break;
      case 'special_days': _preferences = _preferences.copyWith(specialDayNotifications: value); break;
      case 'reminders': _preferences = _preferences.copyWith(reminderNotifications: value); break;
      case 'important_updates': _preferences = _preferences.copyWith(importantUpdates: value); break;
      case 'marketing': _preferences = _preferences.copyWith(marketingNotifications: value); break;
    }
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true, openedAt: DateTime.now());
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true, openedAt: now);
    }
    notifyListeners();
  }
}`,

  "lib/notifications/screens/notifications_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/tnt_models.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../widgets/notification_card.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final ITNTApiService apiService;
  const NotificationsScreen({Key? key, required this.apiService}) : super(key: key);
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}`,

  "lib/notifications/screens/notification_settings_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/notification_service.dart';
import '../../services/device_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}`,

  "lib/notifications/widgets/notification_card.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/tnt_models.dart';

/// Accessible Notification Card displaying Title, Body, Sent time, Unread Badge, and Category icon.
class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final bool isTamil;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  const NotificationCard({
    Key? key,
    required this.item,
    required this.isTamil,
    required this.onTap,
    this.onMarkRead,
  }) : super(key: key);
}`,

  "lib/notifications/widgets/permission_dialog.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Notification Permission Dialog explaining value proposition in Tamil and English without aggressive prompts.
class NotificationPermissionDialog extends StatelessWidget {
  final bool isTamil;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const NotificationPermissionDialog({
    Key? key,
    required this.isTamil,
    required this.onAllow,
    required this.onDeny,
  }) : super(key: key);
}`,

  "supabase/functions/send-push-notifications/index.ts": `// Supabase Edge Function: Secure server-side FCM push delivery pipeline
// Architecture: Flutter App -> Supabase Database -> Edge Function Scheduler -> FCM v1 API -> Device
// NEVER store FCM server keys, service accounts or service-role keys in Flutter client.`,

  "lib/features/admin/content/admin_content_screen.dart": `import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Content & Poster Management with Status Workflow (Draft, Scheduled, Published, Archived)
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({Key? key}) : super(key: key);
  @override
  _AdminContentScreenState createState() => _AdminContentScreenState();
}`,

  "lib/features/admin/content/admin_content_form.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Bilingual Content Form with separate Tamil and English fields and live preview
class AdminContentFormScreen extends StatefulWidget {
  final ContentItem? initialItem;
  final VoidCallback onSaved;
  const AdminContentFormScreen({Key? key, this.initialItem, required this.onSaved}) : super(key: key);
}`,

  "lib/features/admin/media_management/admin_media_library_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Media Library with secure Supabase storage integration and metadata tracking
class AdminMediaLibraryScreen extends StatefulWidget {
  const AdminMediaLibraryScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/festivals_management/admin_festivals_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Festivals Management Screen (Bilingual names, descriptions, categories)
class AdminFestivalsScreen extends StatefulWidget {
  const AdminFestivalsScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/special_days_management/admin_special_days_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Special Days Management Screen (Pradosham, Amavasai, Pournami, Ekadasi, etc.)
class AdminSpecialDaysScreen extends StatefulWidget {
  const AdminSpecialDaysScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Muhurtham Management Screen (Marriage, Subha Horais, Lagnam, Nakshatra)
class AdminMuhurthamScreen extends StatefulWidget {
  const AdminMuhurthamScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/panchangam_management/admin_panchangam_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';

/// Admin Panchangam Management (Core Elements & Approved Timings)
class AdminPanchangamScreen extends StatefulWidget {
  const AdminPanchangamScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/calendar_management/admin_calendar_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';

/// Admin Calendar Metadata Management (Single source of truth)
class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/audit/admin_audit_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Audit Trail Screen (Strictly Admin only log of mutations)
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/bulk_import/admin_bulk_import_screen.dart": `import 'package:flutter/material.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Bulk Dataset Import Foundation (Pre-commit schema validation & preview)
class AdminBulkImportScreen extends StatefulWidget {
  const AdminBulkImportScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/notifications/repositories/admin_campaign_repository.dart": `import 'package:flutter/foundation.dart';
import '../../../../models/tnt_models.dart';
import '../../../../services/supabase_service.dart';

/// Admin Campaign Repository for Notification Campaigns & Push Dispatching
class AdminCampaignRepository {
  Future<List<NotificationCampaign>> getCampaigns({String? status, String? category});
  Future<Map<String, dynamic>> sendCampaignNow(String campaignId);
  Future<bool> cancelCampaign(String campaignId);
  Future<CampaignDeliveryAnalytics> getCampaignAnalytics();
}`,

  "lib/features/admin/notifications/screens/admin_campaigns_screen.dart": `import 'package:flutter/material.dart';
import '../../../../models/tnt_models.dart';
import '../repositories/admin_campaign_repository.dart';

/// Admin Notification Campaigns Hub (All, Scheduled, Sent, Drafts, Logs, Analytics)
class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({Key? key}) : super(key: key);
}`,

  "lib/features/admin/notifications/screens/admin_campaign_create_screen.dart": `import 'package:flutter/material.dart';
import '../../../../models/tnt_models.dart';
import '../repositories/admin_campaign_repository.dart';

/// Admin Campaign Creator & Editor (Bilingual, Categories, Audiences, Scheduling, Live Preview)
class AdminCampaignCreateScreen extends StatefulWidget {
  final NotificationCampaign? initialCampaign;
  final VoidCallback onSaved;
  const AdminCampaignCreateScreen({Key? key, this.initialCampaign, required this.onSaved}) : super(key: key);
}`,

  "lib/more/screens/about_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

/// About TNT Platform Screen with app release metadata, features, and direct legal links
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);
}`,

  "lib/more/screens/terms_conditions_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';

/// Terms & Conditions Legal Screen with astrological calculation disclaimers & IP protections
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);
}`,

  "lib/more/screens/privacy_policy_screen.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';

/// Privacy Policy Screen with PostgreSQL Row-Level Security, data sovereignty & encryption guarantees
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);
}`,

  "supabase/functions/navamsha-panchang/index.ts": `// Official Navamsha Panchang Edge Function Proxy
// Reads NAVAMSHA_API_KEY exclusively from Deno environment secrets.
// Provides cached astronomical calculations & observances to TNT applications.`,

  "lib/services/navamsha_panchang_service.dart": `import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tnt_models.dart';
import 'supabase_service.dart';

/// Central Service for Navamsha Panchang integration via Supabase Edge Function
/// CRITICAL: Flutter client NEVER stores or transmits NAVAMSHA_API_KEY directly.
class NavamshaPanchangService {
  static final NavamshaPanchangService _instance = NavamshaPanchangService._internal();
  factory NavamshaPanchangService() => _instance;
  NavamshaPanchangService._internal();

  Future<Map<String, dynamic>> getDailyBundle({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double timezone,
    String cityName = 'Selected City',
    bool forceRefresh = false,
  }) async {
    // Calls secure Edge Function: navamsha-panchang
    return {};
  }
}`,

  "lib/services/panchang_local_cache_service.dart": `import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tnt_models.dart';
import '../panchangam/models/panchangam_bundle.dart';

/// Production-grade Local Storage Cache Service for Daily Panchangam
/// Enables users to access today's essential timings (Nalla Neram,
/// Rahu Kalam, Yamagandam, Sunrise, Sunset, Tithi, Nakshatra) offline.
class PanchangLocalCacheService {
  static final PanchangLocalCacheService _instance = PanchangLocalCacheService._internal();
  factory PanchangLocalCacheService() => _instance;
  PanchangLocalCacheService._internal();

  static const String _keyPrefix = 'tnt_panchang_cache_v1_';

  Future<bool> cacheDailyPanchangam({
    required DateTime date,
    required String location,
    required PanchangamDailyBundle bundle,
  }) async {
    final key = _buildKey(location, date);
    final payload = {
      'schemaVersion': 1,
      'cachedAt': DateTime.now().toIso8601String(),
      'location': location,
      'data': bundle.toJson(),
    };
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(key, jsonEncode(payload));
  }

  Future<PanchangamDailyBundle?> getCachedDailyPanchangam({
    required DateTime date,
    required String location,
    Duration? maxAge,
  }) async {
    final key = _buildKey(location, date);
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    final decoded = jsonDecode(jsonStr);
    return PanchangamDailyBundle.fromJson(decoded['data']).copyWith(
      isFromOfflineCache: true,
      cachedAt: DateTime.tryParse(decoded['cachedAt'] ?? ''),
    );
  }

  String _buildKey(String location, DateTime date) {
    return '$_keyPrefix\${location.toLowerCase()}_\${date.year}_\${date.month}_\${date.day}';
  }
}`,

  "lib/repositories/panchang_repository.dart": `import '../models/tnt_models.dart';
import '../panchangam/models/panchangam_bundle.dart';
import '../services/navamsha_panchang_service.dart';
import '../services/panchang_local_cache_service.dart';

/// Single source of truth repository with offline local storage caching
class PanchangRepository {
  static final PanchangRepository _instance = PanchangRepository._internal();
  factory PanchangRepository() => _instance;
  PanchangRepository._internal();

  final PanchangLocalCacheService _localCache = PanchangLocalCacheService();

  Future<PanchangamDailyBundle> getDailyPanchangam({
    required DateTime date,
    required UserLocationItem location,
    bool forceRefresh = false,
  }) async {
    // 1. Check local storage offline cache first if not refreshing
    if (!forceRefresh) {
      final cached = await _localCache.getCachedDailyPanchangam(date: date, location: location.city);
      if (cached != null) return cached;
    }

    try {
      // 2. Fetch from Navamsha Panchang Service via Supabase Edge Function
      final remote = await _fetchFromEdgeFunction(date, location);
      // 3. Save into local storage cache for offline resilience
      await _localCache.cacheDailyPanchangam(date: date, location: location.city, bundle: remote);
      return remote;
    } catch (networkError) {
      // 4. Fallback to local storage if user is offline
      final cached = await _localCache.getCachedDailyPanchangam(date: date, location: location.city);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<bool> hasOfflineCache(DateTime date, String location) =>
      _localCache.hasCachedPanchangam(date: date, location: location);
}`,

  "lib/panchangam/widgets/panchangam_date_bar.dart": `import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import '../../models/tnt_models.dart';

class PanchangamDateBar extends StatelessWidget {
  final DateTime selectedDate;
  final CalendarDay? calendarDay;
  final VoidCallback onPreviousDate;
  final VoidCallback onToday;
  final VoidCallback onNextDate;
  final Function(DateTime) onDateSelected;

  const PanchangamDateBar({
    Key? key,
    required this.selectedDate,
    required this.calendarDay,
    required this.onPreviousDate,
    required this.onToday,
    required this.onNextDate,
    required this.onDateSelected,
  }) : super(key: key);

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  String _getDayName(int weekday, bool isTamil) {
    if (isTamil) {
      const days = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];
      return days[weekday - 1];
    } else {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[weekday - 1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;
    final translate = (String key) => localizations?.translate(key) ?? key;

    final tamilDateText = calendarDay != null
        ? '\${calendarDay!.tamilMonth} \${calendarDay!.tamilDay}'
        : (isTamil ? 'புரட்டாசி \${selectedDate.day}' : 'Purattasi \${selectedDate.day}');

    final dayName = _getDayName(selectedDate.weekday, isTamil);
    final englishDateText = '\${selectedDate.day} Sep \${selectedDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TNTColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: TNTColors.primary,
                tooltip: translate('previous_day'),
                onPressed: onPreviousDate,
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: TNTColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        englishDateText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  if (!_isToday)
                    TextButton(
                      onPressed: onToday,
                      child: Text(translate('today')),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: TNTColors.primary,
                    tooltip: translate('next_day'),
                    onPressed: onNextDate,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 12, color: TNTColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tamilDateText, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(dayName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}`,

  "lib/jathagam/models/horoscope_model.dart": `import 'package:flutter/foundation.dart';

class RasiItem {
  final String id;
  final String nameEn;
  final String nameTa;
  final String symbol;
  final String lordEn;
  final String lordTa;
  final String elementEn;
  final String elementTa;
  final List<NakshatraItem> nakshatras;

  const RasiItem({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.symbol,
    required this.lordEn,
    required this.lordTa,
    required this.elementEn,
    required this.elementTa,
    required this.nakshatras,
  });
}

class NakshatraItem {
  final String id;
  final String nameEn;
  final String nameTa;
  final List<int> padas;
  final String lordEn;
  final String lordTa;

  const NakshatraItem({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.padas,
    required this.lordEn,
    required this.lordTa,
  });
}

class DailyHoroscopeReading {
  final String rasiId;
  final String rasiNameTa;
  final String rasiNameEn;
  final String nakshatraId;
  final String nakshatraNameTa;
  final String nakshatraNameEn;
  final int pada;
  final DateTime date;
  final String tamilDateText;
  final double score;
  final int luckyPercentage;
  final String moodTa;
  final String moodEn;
  final String generalPredictionTa;
  final String generalPredictionEn;
  final String careerPredictionTa;
  final String careerPredictionEn;
  final String financePredictionTa;
  final String financePredictionEn;
  final String familyPredictionTa;
  final String familyPredictionEn;
  final String healthPredictionTa;
  final String healthPredictionEn;
  final int luckyNumber;
  final String luckyColorTa;
  final String luckyColorEn;
  final String luckyDirectionTa;
  final String luckyDirectionEn;
  final String luckyTimeTa;
  final String luckyTimeEn;
  final String pariharamDeityTa;
  final String pariharamDeityEn;
  final String pariharamRemedyTa;
  final String pariharamRemedyEn;
  final String mantraTa;
  final String mantraEn;

  const DailyHoroscopeReading({
    required this.rasiId,
    required this.rasiNameTa,
    required this.rasiNameEn,
    required this.nakshatraId,
    required this.nakshatraNameTa,
    required this.nakshatraNameEn,
    required this.pada,
    required this.date,
    required this.tamilDateText,
    required this.score,
    required this.luckyPercentage,
    required this.moodTa,
    required this.moodEn,
    required this.generalPredictionTa,
    required this.generalPredictionEn,
    required this.careerPredictionTa,
    required this.careerPredictionEn,
    required this.financePredictionTa,
    required this.financePredictionEn,
    required this.familyPredictionTa,
    required this.familyPredictionEn,
    required this.healthPredictionTa,
    required this.healthPredictionEn,
    required this.luckyNumber,
    required this.luckyColorTa,
    required this.luckyColorEn,
    required this.luckyDirectionTa,
    required this.luckyDirectionEn,
    required this.luckyTimeTa,
    required this.luckyTimeEn,
    required this.pariharamDeityTa,
    required this.pariharamDeityEn,
    required this.pariharamRemedyTa,
    required this.pariharamRemedyEn,
    required this.mantraTa,
    required this.mantraEn,
  });
}`,

  "lib/jathagam/screens/jathagam_screen.dart": `import 'package:flutter/material.dart';
import '../models/horoscope_model.dart';
import '../services/horoscope_service.dart';

class JathagamScreen extends StatefulWidget {
  final String initialRasiId;
  final String initialNakshatraId;
  final int initialPada;

  const JathagamScreen({
    Key? key,
    this.initialRasiId = 'mesham',
    this.initialNakshatraId = 'ashwini',
    this.initialPada = 1,
  }) : super(key: key);

  @override
  State<JathagamScreen> createState() => _JathagamScreenState();
}

class _JathagamScreenState extends State<JathagamScreen> {
  late String _selectedRasiId;
  late String _selectedNakshatraId;
  late int _selectedPada;
  DateTime _selectedDate = DateTime(2026, 9, 28);
  DailyHoroscopeReading? _reading;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRasiId = widget.initialRasiId;
    _selectedNakshatraId = widget.initialNakshatraId;
    _selectedPada = widget.initialPada;
    _fetchHoroscope();
  }

  Future<void> _fetchHoroscope() async {
    setState(() => _isLoading = true);
    final reading = await HoroscopeService.getDailyHoroscope(
      rasiId: _selectedRasiId,
      nakshatraId: _selectedNakshatraId,
      pada: _selectedPada,
      date: _selectedDate,
    );
    setState(() {
      _reading = reading;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ஜாதகம் & தினசரி ராசிபலன்'),
        backgroundColor: Colors.amber.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHoroscope,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Rasi and Nakshatra Pickers
            // Daily Horoscope Reading card
          ],
        ),
      ),
    );
  }
}`
};

