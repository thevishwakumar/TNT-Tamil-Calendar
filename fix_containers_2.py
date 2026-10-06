import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find color: <val>, that is directly inside a Container( that also has a decoration: (const)? BoxDecoration(
    # This is complex for regex. A robust way is to just find Container(
    # and if we see color: X and decoration: in the same indentation level...
    
    # Alternatively, just search for color: and decoration: within a few lines.
    # Let's replace color: (.*?),\n(.*?)decoration: (const )?BoxDecoration\(
    # with \2decoration: \3BoxDecoration(\ncolor: \1,
    
    pat1 = re.compile(r'color:\s*([^,]+),\s*(.*?)\s*decoration:\s*(const\s+)?BoxDecoration\s*\(', re.DOTALL)
    
    # Wait, the above pat1 is too greedy and will match across different containers.
    # We can match up to 200 characters to prevent crossing boundaries.
    
    def replacer(match):
        color_val = match.group(1).strip()
        in_between = match.group(2)
        const_str = match.group(3) or ''
        return f'{in_between} decoration: {const_str}BoxDecoration(\n      color: {color_val},'
        
    # We need a non-greedy match that doesn't include 'Container' or 'decoration' or 'color' inside the in-between.
    pat_strict = re.compile(r'color:\s*([^,]+),\s*([^c]*?)\s*decoration:\s*(const\s+)?BoxDecoration\s*\(', re.DOTALL)
    
    new_content = pat_strict.sub(replacer, content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Fixed pat1 in {filepath}')

for root, _, files in os.walk(r'C:\Users\Vishw\Downloads\TNT\lib'):
    for f in files:
        if f.endswith('.dart'):
            fix_file(os.path.join(root, f))
