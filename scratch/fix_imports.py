import os

files = [
    r'c:\Users\Vishw\Downloads\TNT\lib\home\screens\home_screen.dart',
    r'c:\Users\Vishw\Downloads\TNT\lib\calendar\screens\calendar_screen.dart',
    r'c:\Users\Vishw\Downloads\TNT\lib\muhurtham\screens\muhurtham_screen.dart',
    r'c:\Users\Vishw\Downloads\TNT\lib\calendar\screens\date_details_screen.dart'
]

import_statement = "import 'package:tnt_tamil_calendar/repositories/tnt_repositories.dart';\n"

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'tnt_repositories.dart' not in content:
        # find the last import
        import_index = content.rfind('import ')
        if import_index != -1:
            end_of_line = content.find('\n', import_index)
            new_content = content[:end_of_line+1] + import_statement + content[end_of_line+1:]
            with open(file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Fixed {file}')
        else:
            print(f'Could not find import section in {file}')
    else:
        print(f'Already imported in {file}')
