import 'dart:io';

void main() {
  void replaceAll(String path, Map<String, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
  }

  // 1. calendar_screen.dart
  replaceAll('lib/calendar/screens/calendar_screen.dart', {
    'SizedBox(\n            width: 44,\n            alignment: Alignment.center,': 'Container(\n            width: 44,\n            alignment: Alignment.center,',
    '}).toList(),': '}).toList().cast<Widget>(),',
  });

  // 2. admin_muhurtham_screen.dart
  replaceAll('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart', {
    'MuhurthamDate(\ntamilDateStr: \'\',\n        id: \'muh-001\',': 'MuhurthamDate(\n        startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\', id: \'muh-001\',',
    'MuhurthamDate(\ntamilDateStr: \'\',\n        id: \'muh-002\',': 'MuhurthamDate(\n        startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\', id: \'muh-002\',',
  });

  // 3. auth_upgrade_test.dart - comment out Supabase init exception temporarily so it passes if we want? No, let's leave runtime alone.

  print('compile_fix done.');
}
