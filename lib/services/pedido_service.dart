import '../db/db_helper.dart';
import '../models/pedido.dart';

class PedidoService {
  Future<int> crear(Pedido p) async {
    final db = await DBHelper.instance.database;
    return await db.insert('pedidos', p.toMap());
  }

  Future<List<Pedido>> obtenerTodos() async {
    final db = await DBHelper.instance.database;
    final r = await db.query('pedidos', orderBy: 'id DESC');
    return r.map((m) => Pedido.fromMap(m)).toList();
  }

  Future<List<Pedido>> obtenerPorUsuario(int usuarioId) async {
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'pedidos',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id DESC',
    );
    return r.map((m) => Pedido.fromMap(m)).toList();
  }

  Future<int> cambiarEstado(int pedidoId, String nuevoEstado) async {
    final db = await DBHelper.instance.database;
    return await db.update(
      'pedidos',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [pedidoId],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await DBHelper.instance.database;
    return await db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
  }
}
