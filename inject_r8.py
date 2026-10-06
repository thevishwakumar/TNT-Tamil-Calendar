filepath = r'C:\Users\Vishw\Downloads\TNT\android\app\build.gradle.kts'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

target = 'signingConfig = signingConfigs.getByName("debug")'
replacement = 'signingConfig = signingConfigs.getByName("debug")\n            isMinifyEnabled = true\n            isShrinkResources = true'

if 'isMinifyEnabled' not in text:
    text = text.replace(target, replacement)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Injected R8 minification.")
