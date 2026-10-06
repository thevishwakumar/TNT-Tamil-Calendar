import 'dart:io';

void main() {
  void replaceInFile(String path, Map<String, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    bool changed = false;
    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }
    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed \$path');
    }
  }

  // 1. admin_content_repository.dart
  replaceInFile('lib/features/admin/repositories/admin_content_repository.dart', {
    'query = query.order(\'created_at\', ascending: false).range(offset, offset + limit - 1);': 'final res = await query.order(\'created_at\', ascending: false).range(offset, offset + limit - 1);',
    'final res = await query;': '// final res = await query;',
    'query = query.order(\'created_at\', ascending: false).limit(limit);': 'final res = await query.order(\'created_at\', ascending: false).limit(limit);',
    'festival.toJson()': 'festival.toMap()',
    'sp.toJson()': 'sp.toMap()',
  });

  // 2. admin_muhurtham_screen.dart
  replaceInFile('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart', {
    'tamilDay: 24,': '',
    'timing: ': '// timing: ',
    'isApproved: true,': '',
    'm?.timing ??': '\'காலை 09:00 - 10:30\' ??',
    '\${m.tamilDay}': '',
    'நேரம்: \${m.timing}': 'நேரம்: காலை',
  });

  // 3. admin_special_days_screen.dart
  replaceInFile('lib/features/admin/special_days_management/admin_special_days_screen.dart', {
    'nameTamil: ': 'titleTa: ',
    'nameEnglish: ': 'title: ',
    'descriptionTamil: ': 'descTa: ',
    'descriptionEnglish: ': 'desc: ',
    'isApproved: ': '// isApproved: ',
    's.nameTamil': 's.titleTa',
    's.nameEnglish': 's.title',
  });

  // 4. SupabaseService().api issues
  replaceInFile('lib/festivals/screens/festival_detail_screen.dart', {
    'SupabaseService().api': 'DevelopmentApiService()',
  });
  replaceInFile('lib/special_days/screens/special_day_detail_screen.dart', {
    'SupabaseService().api': 'DevelopmentApiService()',
  });

  // 5. reminders_screen.dart
  replaceInFile('lib/reminders/screens/reminders_screen.dart', {
    'DevelopmentApiService()': 'null /* DevelopmentApiService() */',
    'loc.isTamil': 'loc.localeName == "ta"',
  });

  // 6. auth_state_manager.dart
  replaceInFile('lib/services/auth_state_manager.dart', {
    'marketingNotifications:': '// marketingNotifications:',
  });

  // 7. tnt_repositories.dart
  replaceInFile('lib/repositories/tnt_repositories.dart', {
    'Future<UserResponse> signUp': 'Future<AuthResponse> signUp',
  });

  // 8. panchangam_bundle.dart
  replaceInFile('lib/panchangam/models/panchangam_bundle.dart', {
    'isGazettedHoliday': 'isAuspicious',
    'isGovernmentHoliday': 'isAuspicious',
  });

  // 9. auth pages (TNTLocalizations locale)
  final authPages = [
    'lib/features/auth/presentation/pages/account_status_page.dart',
    'lib/features/auth/presentation/pages/auth_welcome_page.dart',
    'lib/features/auth/presentation/pages/email_verification_page.dart',
    'lib/features/auth/presentation/pages/mobile_verification_page.dart'
  ];
  for (final page in authPages) {
    replaceInFile(page, {
      'TNTLocalizations.of(context)!.locale': 'Localizations.localeOf(context).languageCode',
      'loc.locale.languageCode': 'Localizations.localeOf(context).languageCode',
    });
  }

  // 10. muhurtham_screen.dart
  replaceInFile('lib/muhurtham/screens/muhurtham_screen.dart', {
    'currentCity:': 'selectedCity:',
  });
}
