import '../db/db_helper.dart';

class PreferenciasService {
  Future<Map<String, dynamic>> obtener(int userId) async {
    final db = await DBHelper.instance.database;
    final r = await db.query('preferencias',
        where: 'usuario_id = ?', whereArgs: [userId], limit: 1);
    if (r.isEmpty) {
      await db.insert('preferencias', {'usuario_id': userId});
      return {'tema_oscuro': 0, 'notificaciones': 1, 'idioma': 'es'};
    }
    return r.first;
  }

  Future<void> actualizar(int userId,
      {bool? temaOscuro, bool? notificaciones, String? idioma}) async {
    final db = await DBHelper.instance.database;
    await obtener(userId);
    await db.update(
        'preferencias',
        {
          if (temaOscuro != null) 'tema_oscuro': temaOscuro ? 1 : 0,
          if (notificaciones != null) 'notificaciones': notificaciones ? 1 : 0,
          if (idioma != null) 'idioma': idioma,
        },
        where: 'usuario_id = ?',
        whereArgs: [userId]);
  }
}
