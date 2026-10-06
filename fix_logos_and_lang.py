import re

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Fix the logo (remove ClipOval, change to BoxFit.contain, remove hardcoded sizes if restricting)
    # The pattern in auth_welcome_page:
    # Container( ... child: ClipOval( child: Image.asset('assets/images/tnt_logo.jpg', fit: BoxFit.cover,),), )
    pattern_logo = r"Container\([\s\S]*?child:\s*ClipOval\([\s\S]*?child:\s*Image\.asset\([\s\S]*?'assets/images/tnt_logo\.jpg'[\s\S]*?fit:\s*BoxFit\.cover,[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),"
    replacement_logo = '''Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.asset(
                'assets/images/tnt_logo.jpg',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),'''
    content = re.sub(pattern_logo, replacement_logo, content)
    
    # Also if the Text logo is present:
    pattern_text_logo = r"Center\(\s*child: Container\(\s*height: 64,\s*width: 64,[\s\S]*?child: const Text\([\s\S]*?'TNT',[\s\S]*?\),\s*\),\s*\),"
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
    
    # 2. Fix the language toggle in auth_welcome_page.dart
    pattern_toggle = r"void _toggleLanguage\(String langCode\) \{[\s\S]*?\}"
    replacement_toggle = '''void _toggleLanguage(String langCode) {
    widget.authStateManager.setLanguage(langCode);
    final provider = TNTLocalizationsProvider.of(context);
    provider?.onLanguageChanged(langCode == 'ta' ? AppLanguage.tamil : AppLanguage.english);
  }'''
    if 'TNTLocalizationsProvider.of(context)' not in content and '_toggleLanguage' in content:
        content = re.sub(pattern_toggle, replacement_toggle, content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(r'C:\Users\Vishw\Downloads\TNT\lib'):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))
