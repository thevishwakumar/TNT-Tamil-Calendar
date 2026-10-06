import os
import re

def main():
    lib_dir = r"c:\Users\Vishw\Downloads\TNT\lib"
    
    # 1. Create the brand header widget file (already done via default_api)
    
    # 2. Process all dart files
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if not file.endswith(".dart"):
                continue
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                
            if "AppBar(" not in content:
                continue
                
            print(f"Processing: {path}")
            
            # Need to add import
            import_statement = "import 'package:tnt_calendar/widgets/tnt_brand_header.dart';\n"
            if import_statement not in content and 'tnt_brand_header.dart' not in content:
                # Add import after the first import or at the top
                if "import " in content:
                    content = content.replace("import ", import_statement + "import ", 1)
                else:
                    content = import_statement + content
            
            # Find all AppBar( occurrences
            # This is tricky because we need to parse Dart code.
            # Alternatively, we can use a simpler approach:
            # Let's find "AppBar(" and inject actions.
            # But what if actions already exists?
            
            # To be safe, we'll look for "AppBar(" and if we find it, we'll try to find its closing or add to it.
            # Actually, Dart supports using a custom AppBar widget. If we replace AppBar( with TNTAppBar(, 
            # we can just write TNTAppBar which takes all AppBar properties and appends the logo to actions.
            
            new_content = content.replace("AppBar(", "TNTAppBar(")
            if new_content != content:
                import_appbar = "import 'package:tnt_calendar/widgets/tnt_app_bar.dart';\n"
                if import_appbar not in new_content:
                    new_content = new_content.replace("import ", import_appbar + "import ", 1)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)

if __name__ == "__main__":
    main()
