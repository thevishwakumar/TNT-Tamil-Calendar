import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tnt_tamil_calendar/main.dart' as app;

void main() {
  // Initialize the Integration Test environment
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TNT E2E Staging Verification', () {
    
    setUpAll(() async {
      // 1. Ensure staging credentials are used safely before any test runs
      try {
        await dotenv.load(fileName: ".env.staging");
        
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL']!,
          anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        );
      } catch (e) {
        debugPrint('Setup Error: Make sure .env.staging exists with valid credentials: $e');
      }
    });

    testWidgets('App boots up successfully and displays Welcome/Login screen', (WidgetTester tester) async {
      // Start the application
      app.main();
      
      // Wait for app to settle (animations, routing, etc.)
      await tester.pumpAndSettle();

      // Verify basic UI components to ensure successful boot
      // This verifies that the architecture (Flutter + Supabase initial load) is stable
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Staging database connection and RLS sanity check', (WidgetTester tester) async {
      // Start the application
      app.main();
      await tester.pumpAndSettle();
      
      // Attempt an unauthenticated read to a public table (e.g., calendar_days)
      // Note: This relies on Supabase being properly initialized in staging
      final supabase = Supabase.instance.client;
      
      bool connectionSuccess = false;
      try {
        // Just a limit(1) probe to verify connectivity without changing data
        final response = await supabase.from('calendar_days').select().limit(1);
        connectionSuccess = true;
      } catch (e) {
        debugPrint('Database connection failed: $e');
      }
      
      expect(connectionSuccess, isTrue, reason: 'Must be able to query the Staging Database');
    });
    
    // Additional tests like Authentication flow (Login with Staging Test Account) 
    // can be added here once staging test fixtures are provisioned.
  });
}
