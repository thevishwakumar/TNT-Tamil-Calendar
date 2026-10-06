import os

filepath = r'C:\Users\Vishw\Downloads\TNT\android\app\src\main\AndroidManifest.xml'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('android:label="tnt_tamil_calendar"', 'android:label="TNT Tamil Calendar"')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
