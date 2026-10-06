import 'dart:io';

void main() {
  void replaceAllInFile(String path, Map<String, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
  }

  // 1. admin_special_days_screen.dart
  replaceAllInFile('lib/features/admin/special_days_management/admin_special_days_screen.dart', {
    'desc:': 'description:',
  });

  // 2. admin_muhurtham_screen.dart
  replaceAllInFile('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart', {
    'MuhurthamDate(': 'MuhurthamDate(\nstartTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\',',
    'tamilDateStr: \'\',\ntamilDateStr: \'\',': 'tamilDateStr: \'\',',
    'startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\',\nstartTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\',': 'startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\',',
  });

  print('Final fix complete.');
}
