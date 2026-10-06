path = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\analytics\repositories\admin_analytics_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("throw StateError('Failed to load daily trends: ');", "throw StateError('Failed to load daily trends');")

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
