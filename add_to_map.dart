import 'dart:io';

void main() {
  final file = File('lib/models/tnt_models.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('Map<String, dynamic> toMap() {') && content.contains('class SpecialDay {')) {
    final specialDayEndIdx = content.indexOf('class Festival {');
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
    content = content.replaceFirst('}\n\nclass Festival {', '\$specialDayMap\nclass Festival {');

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
    // Insert into Festival (assuming it ends before class MuhurthamDate)
    content = content.replaceFirst('}\n\nclass MuhurthamDate {', '\$festivalMap\nclass MuhurthamDate {');
    
    file.writeAsStringSync(content);
    print('Added toMap() to models.');
  }
}
