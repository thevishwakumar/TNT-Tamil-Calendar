with open(r'C:\Users\Vishw\Downloads\TNT\lib\repositories\tnt_repositories.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = "await _db.client.from('profiles').upsert(profile.toJson());"
new_text = "await _db.client.from('profiles').update(profile.toJson()).eq('id', profile.id);"

if target in text:
    with open(r'C:\Users\Vishw\Downloads\TNT\lib\repositories\tnt_repositories.dart', 'w', encoding='utf-8') as f:
        f.write(text.replace(target, new_text))
    print('Replaced successfully')
else:
    print('Target not found')
