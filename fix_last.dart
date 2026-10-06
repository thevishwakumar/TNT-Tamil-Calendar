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

  // 1. admin_content_repository.dart
  replaceAllInFile('lib/features/admin/repositories/admin_content_repository.dart', {
    'festival.toMap()': 'festival.toJson()',
    'sp.toMap()': 'sp.toJson()',
  });

  // 2. admin_special_days_screen.dart
  replaceAllInFile('lib/features/admin/special_days_management/admin_special_days_screen.dart', {
    'sp?.nameTamil': 'sp?.titleTa',
    'sp?.nameEnglish': 'sp?.title',
    'sp?.descriptionTamil': 'sp?.descriptionTa',
    'sp?.descriptionEnglish': 'sp?.description',
    'sp.nameTamil': 'sp.titleTa',
    'sp.nameEnglish': 'sp.title',
    'sp.descriptionTamil': 'sp.descriptionTa',
    'sp.descriptionEnglish': 'sp.description',
    'nameTamil:': 'titleTa:',
    'nameEnglish:': 'title:',
    'descriptionTamil:': 'descriptionTa:',
    'descriptionEnglish:': 'description:',
    'descTa: descTaCtrl.text.trim(),': 'descriptionTa: descTaCtrl.text.trim(),',
  });

  // 3. admin_muhurtham_screen.dart
  replaceAllInFile('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart', {
    'tamilDay: 12,': 'tamilDateStr: \'\',',
    'MuhurthamDate(': 'MuhurthamDate(\ntamilDateStr: \'\',',
  });

  // Also remove redundant tamilDateStr we just accidentally duplicated if any
  final muhurthamFile = File('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart');
  var mContent = muhurthamFile.readAsStringSync();
  mContent = mContent.replaceAll('tamilDateStr: \'\',\n          tamilDateStr: \'\',', 'tamilDateStr: \'\',');
  muhurthamFile.writeAsStringSync(mContent);

  // 4. festivals_screen.dart and related missing nameEnglish
  replaceAllInFile('lib/festivals/screens/festivals_screen.dart', {
    'fest.nameEnglish': 'fest.name',
  });

  print('Done fixing last errors');
}
