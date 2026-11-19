import '../db/db_helper.dart';

class ActividadService {
  Future<void> registrar(String accion,
      {int? usuarioId, String? correo, String? detalle}) async {
    final db = await DBHelper.instance.database;
    await db.insert('actividad', {
      'usuario_id': usuarioId,
      'usuario_correo': correo,
      'accion': accion,
      'detalle': detalle,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerTodas({int limit = 100}) async {
    final db = await DBHelper.instance.database;
    return await db.query('actividad', orderBy: 'id DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> obtenerPorUsuario(int userId) async {
    final db = await DBHelper.instance.database;
    return await db.query('actividad',
        where: 'usuario_id = ?', whereArgs: [userId], orderBy: 'id DESC');
  }
}
