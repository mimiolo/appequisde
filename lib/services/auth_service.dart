import '../db/db_helper.dart';
import '../models/usuario.dart';

class AuthService {
  Future<Usuario?> login(String correo, String pass) async {
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'user_app',
      where: 'correo = ? AND pass = ?',
      whereArgs: [correo.trim().toLowerCase(), pass],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return Usuario.fromMap(r.first);
  }
}
