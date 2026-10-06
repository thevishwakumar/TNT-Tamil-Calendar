with open(r'C:\Users\Vishw\Downloads\TNT\lib\features\auth\presentation\pages\auth_welcome_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

import re
# Remove string literals and comments to count brackets safely
text = re.sub(r"'.*?'", '', text)
text = re.sub(r'".*?"', '', text)
text = re.sub(r'//.*', '', text)
text = re.sub(r'/\*[\s\S]*?\*/', '', text)

counts = {'(':0, '{':0, '[':0}
pairs = {'(': ')', '{': '}', '[': ']'}
stack = []
for i, line in enumerate(text.split('\n')):
    for char in line:
        if char in '({[':
            stack.append((char, i+1))
            counts[char] += 1
        elif char in ')}]':
            if not stack:
                print(f'Line {i+1}: Found {char} but stack is empty!')
            else:
                last, line_num = stack.pop()
                if pairs[last] != char:
                    print(f'Line {i+1}: Expected {pairs[last]} but found {char}. Opened at line {line_num}')
if stack:
    print('Unclosed brackets:')
    for char, line_num in stack:
        print(f'Opened {char} at line {line_num}')
