import os
import re

def fix_container(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find Container( ... color: X, ... decoration: BoxDecoration(...) ... )
    # This is tricky with regex. Let's look for simple cases:
    # color: <something>,\n  decoration:
    
    # We can match: color: ([^,]+),(\s*)decoration: (const )?BoxDecoration\(
    # And replace with: \2decoration: \3BoxDecoration(\n  color: \1,
    
    # Pattern 1: color comes before decoration
    pat1 = re.compile(r'color:\s*([^,]+?)\s*,\s*decoration:\s*(const\s+)?BoxDecoration\s*\(', re.DOTALL)
    
    # Pattern 2: decoration comes before color
    pat2 = re.compile(r'decoration:\s*(const\s+)?BoxDecoration\s*\((.*?)\)\s*,\s*color:\s*([^,]+?)\s*(?=[,)])', re.DOTALL)

    new_content = content
    
    def repl1(m):
        color_val = m.group(1).strip()
        const_str = m.group(2) or ''
        return f'decoration: {const_str}BoxDecoration(\n      color: {color_val},'
        
    def repl2(m):
        const_str = m.group(1) or ''
        box_inner = m.group(2)
        color_val = m.group(3).strip()
        return f'decoration: {const_str}BoxDecoration(\n      color: {color_val},\n      {box_inner})'

    new_content = pat1.sub(repl1, new_content)
    # Actually, pat2 is too risky with DOTALL. 

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Fixed {filepath}')

for root, _, files in os.walk(r'C:\Users\Vishw\Downloads\TNT\lib'):
    for f in files:
        if f.endswith('.dart'):
            fix_container(os.path.join(root, f))
