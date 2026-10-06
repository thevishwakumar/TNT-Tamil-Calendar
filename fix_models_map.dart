import 'dart:io';

void main() {
  final file = File('lib/models/tnt_models.dart');
  var content = file.readAsStringSync();
  
  // Fix MuhurthamTimingItem missing bracket and literal $festivalMap
  const festivalMap = '''
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'tamil_date_str': tamilDateStr,
      'tamil_month': tamilMonth,
      'tamil_year': tamilYear,
      'day_of_week_en': dayOfWeekEn,
      'day_of_week_ta': dayOfWeekTa,
      'name': name,
      'name_ta': nameTa,
      'type': type,
      'type_ta': typeTa,
      'category': category,
      'category_ta': categoryTa,
      'description': description,
      'description_ta': descriptionTa,
      'rituals': rituals,
      'rituals_ta': ritualsTa,
      'deity': deity,
      'deity_ta': deityTa,
      'significance': significance,
      'significance_ta': significanceTa,
      'is_holiday': isHoliday,
      'image_url': imageUrl,
      'location': location,
      'is_published': isPublished,
      'status': status,
      'is_saved': isSaved,
      'has_reminder': hasReminder,
    };
  }
}
''';

  content = content.replaceAll('\$festivalMap\nclass MuhurthamDate {', '}\n\nclass MuhurthamDate {');

  // Fix literal $specialDayMap
  const specialDayMap = '''
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'tamil_date_str': tamilDateStr,
      'tamil_month': tamilMonth,
      'tamil_year': tamilYear,
      'day_of_week_en': dayOfWeekEn,
      'day_of_week_ta': dayOfWeekTa,
      'title': title,
      'title_ta': titleTa,
      'category': category,
      'category_ta': categoryTa,
      'is_holiday': isHoliday,
      'description': description,
      'description_ta': descriptionTa,
      'rituals': rituals,
      'rituals_ta': ritualsTa,
      'deity': deity,
      'deity_ta': deityTa,
      'significance': significance,
      'significance_ta': significanceTa,
      'timing_window': timingWindow,
      'image_url': imageUrl,
      'location': location,
      'is_published': isPublished,
      'status': status,
      'is_saved': isSaved,
      'has_reminder': hasReminder,
    };
  }
}
''';

  content = content.replaceAll('\$specialDayMap\nclass Festival {', '}\n\nclass Festival {');

  // Now properly add the maps to SpecialDay and Festival classes
  // The correct way is to insert them right before the closing brace of the class
  
  // Find where SpecialDay ends. It's right before `class Festival {`
  content = content.replaceFirst('}\n\nclass Festival {', '\$specialDayMap\n\nclass Festival {');

  // Find where Festival ends. It's right before `class MuhurthamDate {`
  content = content.replaceFirst('}\n\nclass MuhurthamDate {', '\$festivalMap\n\nclass MuhurthamDate {');

  file.writeAsStringSync(content);
  print('Fixed models maps');
}
