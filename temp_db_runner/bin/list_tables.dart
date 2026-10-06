import 'package:postgres/postgres.dart';
void main() async {
  final conn = await Connection.open(Endpoint(host: 'db.pvtrjdfaosrxhrucebqu.supabase.co', database: 'postgres', username: 'postgres', password: 'Vishwa@8105', port: 5432), settings: ConnectionSettings(sslMode: SslMode.require));
  final res = await conn.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';");
  for(var r in res) print(r[0]);
  await conn.close();
}
