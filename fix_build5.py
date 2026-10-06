import re

p1 = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\signup_screen.dart'
with open(p1, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace the TNTLocationSelection block completely
code = re.sub(
    r'TNTLocationSelection _selectedLocation = TNTLocationSelection\([\s\S]*?\);',
    'String _selectedLocation = "";',
    code
)

with open(p1, 'w', encoding='utf-8') as f:
    f.write(code)

p2 = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\analytics\repositories\admin_analytics_repository.dart'
with open(p2, 'r', encoding='utf-8') as f:
    code2 = f.read()

code2 = code2.replace("throw StateError('Failed to load daily trends: ');", "throw StateError('Failed to load daily trends');")

with open(p2, 'w', encoding='utf-8') as f:
    f.write(code2)

print("Fixed")
