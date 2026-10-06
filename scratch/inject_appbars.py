import os

def process_dart_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If AppBar is not in the file, skip
    if 'AppBar(' not in content:
        return False

    # Also we need to check if there is SliverAppBar - prompt says all pages, so we might need to handle SliverAppBar too.
    # We found no SliverAppBar earlier.
    
    # We will find every occurrence of "AppBar(" and inject the brand header.
    new_content = ""
    idx = 0
    modified = False

    while True:
        pos = content.find('AppBar(', idx)
        if pos == -1:
            new_content += content[idx:]
            break

        # Append everything up to "AppBar("
        new_content += content[idx:pos + 7] # include "AppBar("
        idx = pos + 7

        # Find the matching closing parenthesis
        paren_count = 1
        curr = idx
        while curr < len(content) and paren_count > 0:
            if content[curr] == '(':
                paren_count += 1
            elif content[curr] == ')':
                paren_count -= 1
            curr += 1
        
        end_pos = curr - 1 # position of the matching ')'

        appbar_content = content[idx:end_pos]
        
        # Check if actions already exists
        # Basic check: look for "actions:" not inside nested structures? It's tricky.
        # But Dart formatter usually puts "actions: ["
        if 'actions:' in appbar_content:
            # Find the bracket [ after actions:
            actions_pos = appbar_content.find('actions:')
            bracket_pos = appbar_content.find('[', actions_pos)
            if bracket_pos != -1:
                # insert const TNTBrandHeader(), after [
                appbar_content = appbar_content[:bracket_pos+1] + " const TNTBrandHeader(), " + appbar_content[bracket_pos+1:]
                modified = True
            else:
                # maybe it's not a list literal but a variable? rare for AppBars, usually it's `actions: [ ... ]`
                pass
        else:
            # no actions, inject it before the closing parenthesis
            appbar_content = appbar_content + ", actions: const [TNTBrandHeader()],"
            modified = True

        new_content += appbar_content
        new_content += ')'
        idx = end_pos + 1

    if modified:
        # Add import
        import_stmt = "import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';\n"
        if import_stmt not in new_content and 'tnt_brand_header.dart' not in new_content:
            if 'import ' in new_content:
                new_content = new_content.replace('import ', import_stmt + 'import ', 1)
            else:
                new_content = import_stmt + new_content
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    lib_dir = r"c:\Users\Vishw\Downloads\TNT\lib"
    count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                if process_dart_file(path):
                    count += 1
                    print(f"Updated {path}")
    print(f"Total files updated: {count}")

if __name__ == '__main__':
    main()
