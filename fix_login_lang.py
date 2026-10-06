path = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\login_screen.dart'
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
appbar_pattern = r"appBar: AppBar\([\s\S]*?leading: IconButton\([\s\S]*?onPressed: \(\) => Navigator.pop\(context\),\s*\),\s*\),"
replacement_appbar = '''appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TNTColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final provider = TNTLocalizationsProvider.of(context);
              if (currentLang == AppLanguage.english) {
                provider?.onLanguageChanged(AppLanguage.tamil);
              } else {
                provider?.onLanguageChanged(AppLanguage.english);
              }
            },
            child: Text(
              currentLang == AppLanguage.english ? '?????' : 'English',
              style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),'''
content = re.sub(appbar_pattern, replacement_appbar, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
