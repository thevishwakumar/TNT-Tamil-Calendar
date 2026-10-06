import os
for root, _, files in os.walk(r'C:\Users\Vishw\Downloads\TNT\lib'):
    for f in files:
        if f.endswith('.dart'):
            with open(os.path.join(root, f), 'r', encoding='utf-8') as file:
                try:
                    for i, line in enumerate(file):
                        if "'guest'" in line or '"guest"' in line or "guest" in line:
                            print(f'{f}:{i+1} -> {line.strip()}')
                except Exception as e:
                    pass
