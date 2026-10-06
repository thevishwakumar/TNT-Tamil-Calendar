import 'dart:io'; 
import 'package:postgres/postgres.dart'; 

void main() async { 
  final sql = File('supabase/migrations/20261006184000_fix_muhurtham_category.sql').readAsStringSync(); 
  final conn = await Connection.open(Endpoint(host: 'db.pvtrjdfaosrxhrucebqu.supabase.co', database: 'postgres', username: 'postgres', password: 'Vishwa@8105', port: 5432), settings: ConnectionSettings(sslMode: SslMode.require)); 
  print('Connected! Executing...'); 
  try { 
    await conn.execute(sql); 
    print('Success!'); 
  } catch(e) { 
    print('Error: $e'); 
  } finally { 
    await conn.close(); 
  } 
}
