import re

path = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\schedules\repositories\admin_schedule_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace signature
code = re.sub(
    r'Future<List<AdminScheduleItem>> getSchedules\({\s*String\? category,\s*String\? status,\s*String\? search,\s*}\)',
    'Future<List<AdminScheduleItem>> getSchedules({String? category, String? status, String? search, int page = 0, int pageSize = 50})',
    code
)

# Replace the inner query body if we haven't already. I did a replace earlier, maybe it failed.
old_body = '''final res = await query.order('schedule_date', ascending: true);
      final list = (res as List?) ?? [];
      return list.map((item) => AdminScheduleItem.fromJson(item as Map<String, dynamic>)).toList();'''

new_body = '''final start = page * pageSize;
      final end = start + pageSize - 1;
      final res = await query.order('schedule_date', ascending: true).range(start, end);
      final list = (res as List?) ?? [];
      return list.map((item) => AdminScheduleItem.fromJson(item as Map<String, dynamic>)).toList();'''

if 'range(start, end)' not in code:
    code = code.replace(old_body, new_body)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed getSchedules signature")
