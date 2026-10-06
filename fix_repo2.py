path = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\analytics\repositories\admin_analytics_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'Failed to load daily trends' in line and i < 142:
        lines[i] = "        throw StateError('No daily trends found for the selected date range.');\n"

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
