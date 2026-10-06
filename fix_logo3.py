path = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\forgot_password_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re
pattern = r"Center\(\s*child: Container\(\s*height: 64,\s*width: 64,[\s\S]*?child: const Text\([\s\S]*?'TNT',[\s\S]*?\),\s*\),\s*\),"
replacement = '''Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.asset(
                  'assets/images/tnt_logo.jpg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),'''
content = re.sub(pattern, replacement, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
