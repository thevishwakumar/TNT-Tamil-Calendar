import psycopg2

DB_URL = 'postgresql://postgres:Vishwa%408105@db.pvtrjdfaosrxhrucebqu.supabase.co:5432/postgres'

try:
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    cur.execute("SELECT id FROM auth.users WHERE email = 'zinointech@gmail.com'")
    row = cur.fetchone()
    
    if row:
        real_id = row[0]
        print(f'Real ID from auth.users: {real_id}')
        
        cur.execute('SELECT role FROM public.profiles WHERE id = %s', (real_id,))
        p_row = cur.fetchone()
        
        if p_row:
            cur.execute('UPDATE public.profiles SET role = %s, account_status = %s WHERE id = %s', ('ADMIN', 'ACTIVE', real_id))
            print('Updated existing profile to ADMIN')
        else:
            cur.execute('''
                INSERT INTO public.profiles (id, email, full_name, role, account_status, language, created_at, updated_at) 
                VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())
            ''', (real_id, 'zinointech@gmail.com', 'Admin', 'ADMIN', 'ACTIVE', 'ta'))
            print('Inserted new profile as ADMIN')
            
        conn.commit()
    else:
        print('User not found in auth.users!')
    
    cur.close()
    conn.close()
except Exception as e:
    print(f'Error: {e}')
