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
    final response = await _supabase
        .from('system_settings')
        .select('*')
        .order('key');
    
    return (response as List).map((e) => SystemSetting.fromJson(e)).toList();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _supabase.from('system_settings').update({
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('key', key);
  }
}
