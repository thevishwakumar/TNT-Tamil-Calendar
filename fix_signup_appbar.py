path = r'C:\Users\Vishw\Downloads\TNT\lib\auth\screens\signup_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Reconstruct the file around the broken AppBar
new_lines = []
skip = False
for i, line in enumerate(lines):
    if i == 174: # line 175 is title: Text(
        new_lines.append("        title: Text(\n")
        new_lines.append("          isTamil ? '????? ??????' : 'Create Account',\n")
        new_lines.append("          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),\n")
        new_lines.append("        ),\n")
        new_lines.append("        actions: [\n")
        new_lines.append("          TextButton(\n")
        new_lines.append("            onPressed: () {\n")
        new_lines.append("              final provider = TNTLocalizationsProvider.of(context);\n")
        new_lines.append("              if (currentLang == AppLanguage.english) {\n")
        new_lines.append("                provider?.onLanguageChanged(AppLanguage.tamil);\n")
        new_lines.append("              } else {\n")
        new_lines.append("                provider?.onLanguageChanged(AppLanguage.english);\n")
        new_lines.append("              }\n")
        new_lines.append("            },\n")
        new_lines.append("            child: Text(\n")
        new_lines.append("              currentLang == AppLanguage.english ? '?????' : 'English',\n")
        new_lines.append("              style: const TextStyle(color: TNTColors.primary, fontWeight: FontWeight.bold),\n")
        new_lines.append("            ),\n")
        new_lines.append("          ),\n")
        new_lines.append("          const SizedBox(width: 8),\n")
        new_lines.append("        ],\n")
        skip = True
    elif skip and i >= 194: # line 195: const SizedBox(width: 8), 196: ], 197: ), 198: bottom:
        # We stop skipping at line 195 (which is the bottom:)
        if 'bottom:' in line:
            skip = False
            new_lines.append(line)
    elif not skip:
        new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
