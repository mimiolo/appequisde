// Guarda y consulta las transacciones Punto Red exitosas.
import '../db/db_helper.dart';
import '../models/punto_red_transaccion.dart';

class PuntoRedTransaccionService {
  /// Guarda una transacción exitosa en la BD.
  static Future<int> guardar({
    required PuntoRedTransaccion tx,
    required String idServicio,
    required String idProducto,
    required String servicio,
    required String producto,
    required String telefono,
    int? usuarioId,
    String? usuarioCorreo,
  }) async {
    final db = await DBHelper.instance.database;
    return await db.insert('punto_red_transacciones', {
      'id_tx': tx.idTx,
      'num_autorizacion': tx.numAutorizacion,
      'id_servicio': idServicio,
      'id_producto': idProducto,
      'servicio': servicio,
      'producto': producto,
      'telefono': telefono,
      'monto': tx.monto,
      'comision': tx.comision,
      'saldo': tx.saldo,
      'fecha': tx.fecha,
      'mensaje': tx.mensaje,
      'codigo_mensaje': tx.codigoMensaje,
      'usuario_id': usuarioId,
      'usuario_correo': usuarioCorreo,
    });
  }

  /// Todas las transacciones (para admin).
  static Future<List<Map<String, dynamic>>> obtenerTodas({
    int limit = 200,
  }) async {
    final db = await DBHelper.instance.database;
    return await db.query(
      'punto_red_transacciones',
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  /// Transacciones de un usuario específico.
  static Future<List<Map<String, dynamic>>> obtenerPorUsuario(
    int usuarioId,
  ) async {
    final db = await DBHelper.instance.database;
    return await db.query(
      'punto_red_transacciones',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id DESC',
    );
  }

  /// Cuenta total.
  static Future<int> contar() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as total FROM punto_red_transacciones',
    );
    return (r.first['total'] as int?) ?? 0;
  }

  /// Suma total de montos.
  static Future<double> totalMonto() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT SUM(monto) as total FROM punto_red_transacciones',
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Suma total de comisiones.
  static Future<double> totalComision() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT SUM(comision) as total FROM punto_red_transacciones',
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
