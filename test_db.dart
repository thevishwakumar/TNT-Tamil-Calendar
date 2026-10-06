import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  dotenv.testLoad(fileInput: File('.env.staging').readAsStringSync());
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  final client = SupabaseClient(url, key);

  final tables = [
    'calendar_days',
    'muhurtham_dates',
    'muhurtham_timings',
    'festivals',
    'special_days',
    'important_timings',
    'locations',
    'notification_logs',
    'user_reminders',
    'personal_events',
    'user_saved_items',
    'profiles',
  ];

  for (final t in tables) {
    try {
      final res = await client.from(t).select().limit(1);
      print('$t: EXISTS');
    } catch (e) {
      if (e.toString().contains('does not exist')) {
        print('$t: MISSING');
      } else {
        print('$t: EXISTS (RLS or error: $e)');
      }
    }
  }
}
