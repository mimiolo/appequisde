import '../db/db_helper.dart';
import '../models/usuario.dart';

class UsuarioService {
  // ⚡ Solo 1 admin permitido
  static const int MAX_ADMINS = 1;

  Future<List<Usuario>> obtenerTodos() async {
    final db = await DBHelper.instance.database;
    final r = await db.query('user_app', orderBy: 'id DESC');
    return r.map((m) => Usuario.fromMap(m)).toList();
  }

  Future<int> contarAdmins() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as total FROM user_app WHERE role_id = 1',
    );
    return (r.first['total'] as int?) ?? 0;
  }

  Future<int> contarPorRol(int roleId) async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as total FROM user_app WHERE role_id = ?',
      [roleId],
    );
    return (r.first['total'] as int?) ?? 0;
  }

  Future<bool> existeCorreo(String correo, {int? exceptoId}) async {
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'user_app',
      where: exceptoId == null ? 'correo = ?' : 'correo = ? AND id != ?',
      whereArgs: exceptoId == null
          ? [correo.trim().toLowerCase()]
          : [correo.trim().toLowerCase(), exceptoId],
    );
    return r.isNotEmpty;
  }

  Future<bool> sePuedeAgregarAdmin() async {
    return (await contarAdmins()) < MAX_ADMINS;
  }

  Future<bool> sePuedeQuitarAdmin(int userId) async {
    final admins = await contarAdmins();
    final db = await DBHelper.instance.database;
    final esAdmin = await db.query(
      'user_app',
      where: 'id = ? AND role_id = 1',
      whereArgs: [userId],
    );
    if (esAdmin.isEmpty) return true;
    return admins > 1;
  }

  Future<bool> sePuedeEliminar(int userId) async {
    return await sePuedeQuitarAdmin(userId);
  }

  Future<int> crear(Usuario u) async {
    final db = await DBHelper.instance.database;
    return await db.insert('user_app', u.toMap());
  }

  Future<int> actualizar(Usuario u) async {
    final db = await DBHelper.instance.database;
    return await db.update(
      'user_app',
      u.toMap(),
      where: 'id = ?',
      whereArgs: [u.id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await DBHelper.instance.database;
    return await db.delete('user_app', where: 'id = ?', whereArgs: [id]);
  }
}
