import re

def patch_file(path, old, new):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            code = f.read()
        if old in code:
            code = code.replace(old, new)
            with open(path, 'w', encoding='utf-8') as f:
                f.write(code)
            print(f"Patched {path}")
    except Exception as e:
        print(f"Failed to patch {path}: {e}")

# 1. AdminAnalyticsRepository
p1 = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\analytics\repositories\admin_analytics_repository.dart'
patch_file(p1, 
    "await client.from('user_saved_items').select('id', const FetchOptions(count: CountOption.exact, forceResponse: true));", 
    "await client.from('user_saved_items').select('id').count(CountOption.exact);")
patch_file(p1,
    "await client.from('user_reminders').select('id', const FetchOptions(count: CountOption.exact, forceResponse: true)).eq('is_enabled', true);",
    "await client.from('user_reminders').select('id').eq('is_enabled', true).count(CountOption.exact);")
patch_file(p1,
    "throw StateError('Failed to load daily trends: ');",
    "throw StateError('Failed to load daily trends');")

# 2. AdminContentRepository
p2 = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\repositories\admin_content_repository.dart'
# It seems this class still has _devContentItems usage somewhere.
# I'll let python replace the methods entirely.
with open(p2, 'r', encoding='utf-8') as f:
    code = f.read()
code = re.sub(r'final index = _devContentItems.indexWhere[^\n]+\n[^\n]+\n[^\n]+\n[^\n]+\n[^\n]+_devContentItems\[index\] = updated;', '', code)
with open(p2, 'w', encoding='utf-8') as f:
    f.write(code)

# 3. location_selector_modal.dart
p3 = r'C:\Users\Vishw\Downloads\TNT\lib\core\widgets\location_selector_modal.dart'
patch_file(p3, "color: TNTColors.background", "color: const Color(0xFFFFFDF9)")
patch_file(p3, "border: Border(bottom: BorderSide(color: TNTColors.border))", "border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))")
patch_file(p3, "const Divider(height: 1, color: TNTColors.border)", "Divider(height: 1, color: TNTColors.border)")

# 4. notification_deep_link_router.dart
p4 = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\notifications\services\notification_deep_link_router.dart'
patch_file(p4, "SupabaseApiService()", "SupabaseApiService()") # Wait, maybe it just needs import
with open(p4, 'r', encoding='utf-8') as f:
    code = f.read()
if 'import \'package:tnt_tamil_calendar/services/production_api_service.dart\';' not in code:
    code = "import 'package:tnt_tamil_calendar/services/production_api_service.dart';\n" + code
    with open(p4, 'w', encoding='utf-8') as f:
        f.write(code)
print("Fixes applied.")
