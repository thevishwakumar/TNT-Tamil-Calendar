import re

path_signup = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\signup_screen.dart'
with open(path_signup, 'r', encoding='utf-8') as f:
    content = f.read()

pattern_text_logo = r"Center\([\s]*child:\s*Container\([\s]*height:\s*64,[\s]*width:\s*64,[\s\S]*?child:\s*const\s*Text\([\s]*'TNT',[\s\S]*?\),[\s]*\),[\s]*\),"
replacement_text_logo = '''Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.asset(
                  'assets/images/tnt_logo.jpg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),'''
content = re.sub(pattern_text_logo, replacement_text_logo, content)
with open(path_signup, 'w', encoding='utf-8') as f:
    f.write(content)

path_welcome = r'C:\Users\Vishw\Downloads\TNT\lib\features\auth\presentation\pages\auth_welcome_page.dart'
with open(path_welcome, 'r', encoding='utf-8') as f:
    content = f.read()

pattern_logo = r"Container\([\s]*width:\s*84,[\s]*height:\s*84,[\s\S]*?child:\s*ClipOval\([\s]*child:\s*Image\.asset\([\s]*'assets/images/tnt_logo\.jpg',[\s]*fit:\s*BoxFit\.cover,[\s]*\),[\s]*\),[\s]*\),"
content = re.sub(pattern_logo, replacement_text_logo, content)

pattern_text_logo2 = r"Center\([\s]*child:\s*Container\([\s]*height:\s*64,[\s]*width:\s*64,[\s\S]*?child:\s*const\s*Text\([\s]*'TNT',[\s\S]*?\),[\s]*\),[\s]*\),"
content = re.sub(pattern_text_logo2, replacement_text_logo, content)

with open(path_welcome, 'w', encoding='utf-8') as f:
    f.write(content)
