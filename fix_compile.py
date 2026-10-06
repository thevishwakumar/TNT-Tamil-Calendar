import os

path_main = r'C:\Users\Vishw\Downloads\TNT\lib\main.dart'
with open(path_main, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('MainScreen(apiService: widget.apiService)', 'MainScreen(apiService: widget.apiService, authStateManager: widget.authStateManager)')
with open(path_main, 'w', encoding='utf-8') as f:
    f.write(text)

path_mainscreen = r'C:\Users\Vishw\Downloads\TNT\lib\main_screen.dart'
with open(path_mainscreen, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("import 'services/tnt_api_service.dart';", "import 'services/supabase_service.dart';\nimport 'services/auth_state_manager.dart';")
text = text.replace("class MainScreen extends StatefulWidget {", "class MainScreen extends StatefulWidget {\n  final AuthStateManager authStateManager;")
text = text.replace("const MainScreen({super.key, required this.apiService});", "const MainScreen({super.key, required this.apiService, required this.authStateManager});")
text = text.replace("MoreScreen(apiService: widget.apiService),", "MoreScreen(apiService: widget.apiService, authStateManager: widget.authStateManager),")

with open(path_mainscreen, 'w', encoding='utf-8') as f:
    f.write(text)
    
path_admin = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\analytics\screens\admin_analytics_screen.dart'
with open(path_admin, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("children: [\n                  ^", "")
# Wait, the error for admin_analytics_screen: 
# lib/features/admin/analytics/screens/admin_analytics_screen.dart:506:19: Error: Can't find ']' to match '['.
