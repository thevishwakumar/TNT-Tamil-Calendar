import 'package:supabase_flutter/supabase_flutter.dart';

class SystemSetting {
  final String key;
  final dynamic value;
  final String? description;
  final DateTime updatedAt;

  SystemSetting({
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      key: json['key'] as String,
      value: json['value'],
      description: json['description'] as String?,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class SystemSettingsRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<SystemSetting>> getAllSettings() async {
    try {
      final response = await _supabase
          .from('system_settings')
          .select('*')
          .order('key');
      
      final list = (response as List).map((e) => SystemSetting.fromJson(e)).toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      print('Warning: system_settings table not found or empty. Using fallbacks. Error: $e');
    }
    
    // Return fallback settings if table fails or is empty
    return [
      SystemSetting(key: 'maintenance_mode', value: false, description: 'Turn on to show maintenance screen to users', updatedAt: DateTime.now()),
      SystemSetting(key: 'enable_push_notifications', value: true, description: 'Global toggle for push notifications', updatedAt: DateTime.now()),
      SystemSetting(key: 'support_email', value: 'support@tntcalendar.com', description: 'Contact email for support', updatedAt: DateTime.now()),
      SystemSetting(key: 'app_version', value: '1.0.0', description: 'Current minimum required app version', updatedAt: DateTime.now()),
    ];
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _supabase.from('system_settings').update({
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('key', key);
  }
}
