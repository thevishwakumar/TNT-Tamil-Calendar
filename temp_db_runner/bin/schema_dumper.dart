import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'db.pvtrjdfaosrxhrucebqu.supabase.co',
      database: 'postgres',
      username: 'postgres',
      password: 'Vishwa@8105',
      port: 5432,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  final tables = [
    'profiles', 'analytics_events', 'calendar_days', 'muhurtham_dates',
    'muhurtham_timings', 'festivals', 'special_days', 'important_timings',
    'locations', 'countries', 'states', 'districts', 'cities',
    'user_preferences', 'user_saved_items', 'user_reminders',
    'personal_events', 'notification_logs'
  ];

  for (var table in tables) {
    print('--- Table: $table ---');
    final result = await conn.execute('''
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = '$table'
      ORDER BY ordinal_position;
    ''');
    
    if (result.isEmpty) {
      print('Table does not exist.');
      continue;
    }

    for (final row in result) {
      print('${row[0]} | ${row[1]} | Nullable: ${row[2]} | Default: ${row[3]}');
    }

    // Constraints
    final constraints = await conn.execute('''
      SELECT
          tc.constraint_type, tc.constraint_name, kcu.column_name, 
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name 
      FROM 
          information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          LEFT JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
      WHERE tc.table_name = '$table' AND tc.table_schema = 'public';
    ''');
    for (final row in constraints) {
      print('Constraint: ${row[0]} (${row[1]}) on ${row[2]} -> ${row[3]}(${row[4]})');
    }
    
    print('');
  }

  await conn.close();
}
