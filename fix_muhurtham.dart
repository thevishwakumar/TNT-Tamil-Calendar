import 'dart:io';

void main() {
  final file = File('lib/features/admin/muhurtham_management/admin_muhurtham_screen.dart');
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  content = content.replaceAll('startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\',', 'startTime: \'06:00 AM\', endTime: \'07:30 AM\', duration: \'1h 30m\', isValarthirai: true, tamilDateStr: \'\',');
  file.writeAsStringSync(content);
  print('Fixed muhurtham date.');
}
