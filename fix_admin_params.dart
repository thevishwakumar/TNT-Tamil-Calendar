import 'dart:io';

void main() {
  final createScreen = File('lib/features/admin/notifications/screens/admin_campaign_create_screen.dart');
  final detailScreen = File('lib/features/admin/notifications/screens/admin_campaign_detail_screen.dart');
  final repo = File('lib/features/admin/notifications/repositories/admin_campaign_repository.dart');
  final dateDetails = File('lib/features/admin/notifications/services/notification_deep_link_router.dart');

  if (createScreen.existsSync()) {
    var content = createScreen.readAsStringSync();
    content = content.replaceAll('isDestructive: false,', 'confirmColor: const Color(0xFFF44336),');
    content = content.replaceAll('selectedIndex: _selectedLanguageTab,', 'currentLang: _selectedLanguageTab,');
    content = content.replaceAll('required: true,', 'isRequired: true,');
    content = content.replaceAll('onDateChanged: ', 'onDateSelected: ');
    content = content.replaceAll('onTimeChanged: ', 'onTimeSelected: ');
    createScreen.writeAsStringSync(content);
    print('Fixed create screen');
  }

  if (detailScreen.existsSync()) {
    var content = detailScreen.readAsStringSync();
    content = content.replaceAll('isDestructive: true,', 'confirmColor: const Color(0xFFF44336),');
    content = content.replaceAll('isDestructive: false,', 'confirmColor: const Color(0xFF2196F3),');
    detailScreen.writeAsStringSync(content);
    print('Fixed detail screen');
  }

  if (dateDetails.existsSync()) {
    var content = dateDetails.readAsStringSync();
    content = content.replaceAll('day: todayDay', 'date: DateTime.now()');
    dateDetails.writeAsStringSync(content);
    print('Fixed deep link router');
  }
}
