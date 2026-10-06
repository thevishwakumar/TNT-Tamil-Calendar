path = r'C:\Users\Vishw\Downloads\TNT\lib\models\tnt_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove 'is_guest': isGuest, from toJson()
import re
content = re.sub(r"\s*'is_guest': isGuest,", "", content)

# Also check for 'guest' in case it's actually written as 'guest' somewhere.
content = re.sub(r"\s*'guest': isGuest,", "", content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
