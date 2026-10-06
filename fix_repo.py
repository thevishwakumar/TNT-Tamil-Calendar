import os

path = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\analytics\repositories\admin_analytics_repository.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = "throw StateError('Failed to load daily trends: ');"
replacement = "throw StateError('No daily trends found for the selected date range.');"

# Find exactly where it says list.isEmpty and then throws the error with .
# But there might be another catch(e) that throws the same error. We ONLY want to replace the one inside the if block.
# Actually, the compiler error says "The getter 'e' isn't defined for the type 'AdminAnalyticsRepository'".
# It points specifically to line 139.

content = content.replace(target, replacement, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')
