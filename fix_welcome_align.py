import re

with open(r'C:\Users\Vishw\Downloads\TNT\lib\features\auth\presentation\pages\auth_welcome_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix Align unclosed parenthesis
text = re.sub(
r'''              Align\(
                alignment: Alignment.topRight,
                child: Padding\(
              padding: const EdgeInsets.symmetric\(vertical: 8.0\),
              child: Image.asset\(
                'assets/images/tnt_logo.jpg',
                height: 120,
                fit: BoxFit.contain,
              \),
            \),
              const SizedBox\(height: 16\),''',
r'''              // Top Bar: Small Clean Language Selector
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: TNTColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TNTColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _toggleLanguage('ta'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isTamil ? TNTColors.primary.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('?????', style: TextStyle(
                            color: isTamil ? TNTColors.primary : TNTColors.textSecondary,
                            fontWeight: isTamil ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          )),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _toggleLanguage('en'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: !isTamil ? TNTColors.primary.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('English', style: TextStyle(
                            color: !isTamil ? TNTColors.primary : TNTColors.textSecondary,
                            fontWeight: !isTamil ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // TOP: Centered Single TNT Logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.asset(
                    'assets/images/tnt_logo.jpg',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),''', text)

with open(r'C:\Users\Vishw\Downloads\TNT\lib\features\auth\presentation\pages\auth_welcome_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)
