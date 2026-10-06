path = r'C:\Users\Vishw\Downloads\TNT\android\app\src\main\AndroidManifest.xml'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

intent_filter = '''            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <!-- Deep linking intent filter for Supabase OAuth -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="tntcalendar" android:host="login-callback" />
            </intent-filter>'''

content = content.replace('''            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>''', intent_filter)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
