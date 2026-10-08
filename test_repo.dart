
import 'dart:io';
import 'package:tnt_tamil_calendar/models/tnt_models.dart';
import 'package:tnt_tamil_calendar/repositories/panchang_repository.dart';
import 'package:tnt_tamil_calendar/panchangam/models/panchangam_bundle.dart';

void main() async {
  final repo = PanchangRepository();
  final loc = UserLocationItem(
        id: 'loc-Chennai',
        userId: 'active-user',
        name: 'Chennai',
        city: 'Chennai',
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      );
  try {
    final bundle = await repo.getDailyPanchangam(date: DateTime.now(), location: loc);
    print('SUCCESS');
  } catch (e, stacktrace) {
    print('ERROR: ');
    print(stacktrace);
  }
}
