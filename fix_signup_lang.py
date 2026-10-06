path = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\signup_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Fix isTamil definition to use TNTLocalizationsProvider
content = re.sub(
    r"final isTamil = Localizations.localeOf\(context\)\.languageCode == 'ta';",
    r"final currentLang = TNTLocalizationsProvider.of(context)?.localizations.language ?? AppLanguage.tamil;\n    final isTamil = currentLang == AppLanguage.tamil;",
    content
)

# Add actions to AppBar
# We look for 	itle: Text( to insert ctions: [...] right after its closing parenthesis.
# Let's just find 	itle: Text( ... ),
pattern_appbar = r"(title:\s*Text\([\s\S]*?\),)"
replacement_appbar = r"\1\n        actions: [\n          TextButton(\n            onPressed: () {\n              final provider = TNTLocalizationsProvider.of(context);\n              if (currentLang == AppLanguage.english) {\n                provider?.onLanguageChanged(AppLanguage.tamil);\n              } else {\n                provider?.onLanguageChanged(AppLanguage.english);\n              }\n            },\n            child: Text(\n              currentLang == AppLanguage.english ? '?????' : 'English',\n              style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold),\n            ),\n          ),\n          const SizedBox(width: 8),\n        ],"
content = re.sub(pattern_appbar, replacement_appbar, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
