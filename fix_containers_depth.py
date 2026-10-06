import os

def find_conflicts(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    idx = 0
    while True:
        idx = content.find('Container(', idx)
        if idx == -1: break
        
        # Parse arguments
        start = idx + 10
        depth = 1
        args = []
        current_arg = ''
        i = start
        while i < len(content) and depth > 0:
            c = content[i]
            if c == '(': depth += 1
            elif c == ')': depth -= 1
            
            if depth == 1 and c == ',':
                args.append(current_arg.strip())
                current_arg = ''
            elif depth > 0:
                current_arg += c
            i += 1
            
        if current_arg:
            args.append(current_arg.strip())
            
        has_color = False
        has_dec = False
        color_arg = None
        for arg in args:
            if arg.startswith('color:'):
                has_color = True
                color_arg = arg
            if arg.startswith('decoration:'):
                has_dec = True
                
        if has_color and has_dec:
            print(f'Conflict in {filepath}')
            # Fix it by removing color arg
            old_container = content[idx:i]
            new_args = [a for a in args if not a.startswith('color:')]
            new_container = 'Container(' + ', '.join(new_args) + ')'
            content = content[:idx] + new_container + content[i:]
            idx = idx + len(new_container)
        else:
            idx = i

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(r'C:\Users\Vishw\Downloads\TNT\lib'):
    for f in files:
        if f.endswith('.dart'):
            find_conflicts(os.path.join(root, f))
