import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  
  if (url.isEmpty || anonKey.isEmpty) {
    print('Please provide SUPABASE_URL and SUPABASE_ANON_KEY');
    exit(1);
  }

  final client = SupabaseClient(url, anonKey);
  
  final tablesToTest = ['countries', 'locations', 'cities', 'states', 'districts', 'location_data'];
  
  for (final table in tablesToTest) {
    try {
      await client.from(table).select().limit(1);
      print('Table EXISTS: $table');
    } catch (e) {
      print('Table NOT FOUND or error: $table - $e');
    }
  }
  exit(0);
}
