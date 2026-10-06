import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/colors.dart';
import 'home/screens/home_screen.dart';
import 'calendar/screens/calendar_screen.dart';
import 'panchangam/screens/panchangam_screen.dart';
import 'muhurtham/screens/muhurtham_screen.dart';
import 'more/screens/more_screen.dart';
import 'services/production_api_service.dart';
import 'services/supabase_service.dart';
import 'services/auth_state_manager.dart';
import 'core/localization/tnt_localizations.dart';

class MainScreen extends StatefulWidget {
  final AuthStateManager authStateManager;
  final ITNTApiService apiService;

  const MainScreen({super.key, required this.apiService, required this.authStateManager});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(apiService: widget.apiService),
      CalendarScreen(apiService: widget.apiService),
      PanchangamScreen(apiService: widget.apiService),
      MuhurthamScreen(apiService: widget.apiService),
      MoreScreen(apiService: widget.apiService, authStateManager: widget.authStateManager),
    ];
  }

  Future<bool> _onWillPop() async {
    // If not on Home tab, go to Home tab
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // Do not pop
    }

    // If on Home tab, require double back press to exit
    final now = DateTime.now();
    if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      _lastPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TNTLocalizationsProvider.of(context)?.localizations.translate('press_back_again_exit') ?? 'Press back again to exit',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return false; // Do not pop
    }

    return true; // Pop and exit
  }

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    String translate(String key) => localizations?.translate(key) ?? key;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: TNTColors.surface,
          selectedItemColor: TNTColors.primary,
          unselectedItemColor: TNTColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: translate('home') != 'home' ? translate('home') : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month),
              label: translate('calendar') != 'calendar' ? translate('calendar') : 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.book_outlined),
              activeIcon: const Icon(Icons.book),
              label: translate('panchangam') != 'panchangam' ? translate('panchangam') : 'Panchangam',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.event_available_outlined),
              activeIcon: const Icon(Icons.event_available),
              label: translate('muhurtham_dates') != 'muhurtham_dates' ? translate('muhurtham_dates') : 'Muhurtham',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              activeIcon: const Icon(Icons.more_horiz),
              label: translate('more') != 'more' ? translate('more') : 'More',
            ),
          ],
        ),
      ),
    );
  }
}
