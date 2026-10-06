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

  // 1. panchangam_bundle.dart
  replaceAllInFile('lib/panchangam/models/panchangam_bundle.dart', {
    'f.isAuspicious': 'f.isHoliday',
  });

  // 2. reminders_screen.dart
  replaceAllInFile('lib/reminders/screens/reminders_screen.dart', {
    'loc?.isTamil': 'loc?.localeName == "ta"',
  });

  print('Almost done fix complete.');
}
