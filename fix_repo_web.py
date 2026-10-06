path = r'C:\Users\Vishw\Downloads\TNT\lib\repositories\tnt_repositories.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'import \'package:flutter/foundation.dart\';' not in content:
    content = "import 'package:flutter/foundation.dart';\n" + content

# Fix the redirectTo line in signInWithGoogle
import re
content = re.sub(
    r"redirectTo:\s*'tntcalendar://login-callback',",
    r"redirectTo: kIsWeb ? null : 'tntcalendar://login-callback',",
    content
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
