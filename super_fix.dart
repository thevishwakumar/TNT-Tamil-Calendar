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

  void replaceRegex(String path, Map<RegExp, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
  }

  // 1. admin_special_days_screen.dart
  replaceRegex('lib/features/admin/special_days_management/admin_special_days_screen.dart', {
    RegExp(r'desc:\s*descEnCtrl\.text\.trim\(\)'): 'description: descEnCtrl.text.trim()',
  });

  // 2. admin_muhurtham_screen.dart
  replaceRegex('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart', {
    RegExp(r'MuhurthamDate\(\s*id:'): 'MuhurthamDate(startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\', id:',
    RegExp(r'MuhurthamDate\(\s*date:'): 'MuhurthamDate(startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\', date:',
  });

  // 3. admin_festivals_screen.dart
  replaceRegex('lib/features/admin/festivals_management/admin_festivals_screen.dart', {
    RegExp(r'name:\s*nameEnCtrl\.text\.trim\(\),'): 'name: nameEnCtrl.text.trim(), type: \'hindu\',',
  });

  // 4. reminders_screen.dart
  replaceAll('lib/reminders/screens/reminders_screen.dart', {
    'loc?.localeName == "ta"': 'Localizations.localeOf(context).languageCode == "ta"',
  });

  // 5. Auth pages
  final authPages = [
    'lib/auth/screens/login_screen.dart',
    'lib/auth/screens/signup_screen.dart',
    'lib/features/auth/presentation/pages/auth_welcome_page.dart',
    'lib/features/auth/presentation/pages/email_verification_page.dart',
    'lib/features/auth/presentation/pages/mobile_verification_page.dart',
    'lib/features/auth/presentation/pages/account_status_page.dart',
  ];
  for (final page in authPages) {
    replaceAll(page, {
      'localizations?.locale.languageCode': 'Localizations.localeOf(context).languageCode',
    });
  }

  // 6. calendar_screen.dart
  replaceAll('lib/calendar/screens/calendar_screen.dart', {
    'SizedBox(width: 40, height: 40, alignment: Alignment.center': 'Container(width: 40, height: 40, alignment: Alignment.center',
    'border: const Border(bottom: BorderSide(color: TNTColors.border, width: 0.5)),': 'decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TNTColors.border, width: 0.5))),',
    'padding: const EdgeInsets.symmetric(horizontal: 4, bottom: 8),': 'padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),',
  });

  print('Super fix done.');
}
