import '../db/db_helper.dart';

class LogService {
  Future<void> registrar(int? userId, String accion, [String? detalle]) async {
    final db = await DBHelper.instance.database;
    await db.insert('log_actividad',
        {'user_id': userId, 'accion': accion, 'detalle': detalle});
  }

  Future<List<Map<String, dynamic>>> obtenerUltimas({int limite = 50}) async {
    final db = await DBHelper.instance.database;
    return await db.rawQuery('''
      SELECT l.*, u.nombre AS usuario
      FROM log_actividad l
      LEFT JOIN user_app u ON u.id = l.user_id
      ORDER BY l.id DESC LIMIT ?
    ''', [limite]);
  }

  Future<void> limpiar() async {
    final db = await DBHelper.instance.database;
    await db.delete('log_actividad');
  }
}
