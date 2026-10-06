import os
import re

def main():
    lib_dir = r"c:\Users\Vishw\Downloads\TNT\lib"
    count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Find ", actions: const [TNTBrandHeader()],)" which might have whitespaces/newlines.
                # Actually, the exact string injected was ", actions: const [TNTBrandHeader()],"
                # And it was placed right before ")".
                # If there was a trailing comma in the previous argument, it looks like:
                # "),\n      , actions: const [TNTBrandHeader()],)"
                
                # regex to find:
                # , actions: const [TNTBrandHeader()],)
                # optionally with spaces around the comma.
                
                # We can replace:
                # ",\n      , actions" -> ",\n        actions"
                # ",\n    , actions" -> ",\n      actions"
                
                # A safer regex: find any occurrence of a comma followed by whitespaces then ", actions: const [TNTBrandHeader()],)"
                
                # Wait, the injection was exactly appbar_content + ", actions: const [TNTBrandHeader()],"
                # So if appbar_content ended with "),\n      ", it became "),\n      , actions: const [TNTBrandHeader()],"
                
                # We can do a string replacement:
                new_content = content.replace("      , actions: const [TNTBrandHeader()],)", "      actions: const [TNTBrandHeader()],\n      )")
                new_content = new_content.replace("    , actions: const [TNTBrandHeader()],)", "    actions: const [TNTBrandHeader()],\n    )")
                new_content = new_content.replace("  , actions: const [TNTBrandHeader()],)", "  actions: const [TNTBrandHeader()],\n  )")
                
                # What if it was ",\n          , actions: const [TNTBrandHeader()],)"?
                # A regex is better:
                new_content = re.sub(
                    r",\s*, actions: const \[TNTBrandHeader\(\)\],",
                    r", actions: const [TNTBrandHeader()],",
                    new_content
                )
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    count += 1
                    print(f"Fixed {path}")
    print(f"Total files fixed: {count}")

if __name__ == '__main__':
    main()
