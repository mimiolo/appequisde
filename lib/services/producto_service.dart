import '../db/db_helper.dart';
import '../models/producto.dart';

class ProductoService {
  static const int MAX_PRODUCTOS = 100;
  static const int MIN_STOCK = 0;
  static const int MAX_STOCK = 1000;
  static const int STOCK_BAJO = 5;
  static const double MIN_PRECIO = 0.01;
  static const double MAX_PRECIO = 3000.00;
  static const int MIN_TITULO = 3;
  static const int MAX_TITULO = 100;
  static const int MIN_DESCRIPCION = 5;
  static const int MAX_DESCRIPCION = 500;
  static const int ALERTA_CATALOGO = 80;

  Future<List<Producto>> obtenerTodos() async {
    final db = await DBHelper.instance.database;
    final r = await db.query('productos', orderBy: 'id DESC');
    return r.map((m) => Producto.fromMap(m)).toList();
  }

  Future<int> contarProductos() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) as total FROM productos');
    return (r.first['total'] as int?) ?? 0;
  }

  Future<bool> sePuedeCrearProducto() async {
    final total = await contarProductos();
    return total < MAX_PRODUCTOS;
  }

  Future<Producto?> obtenerPorId(int id) async {
    final db = await DBHelper.instance.database;
    final r =
        await db.query('productos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (r.isEmpty) return null;
    return Producto.fromMap(r.first);
  }

  Future<bool> existeTitulo(String titulo, {int? exceptoId}) async {
    final db = await DBHelper.instance.database;
    final r = await db.query('productos',
        where: exceptoId == null ? 'titulo = ?' : 'titulo = ? AND id != ?',
        whereArgs:
            exceptoId == null ? [titulo.trim()] : [titulo.trim(), exceptoId]);
    return r.isNotEmpty;
  }

  Future<int> crear(Producto p) async {
    final db = await DBHelper.instance.database;
    return await db.insert('productos', p.toMap());
  }

  Future<int> actualizar(Producto p) async {
    final db = await DBHelper.instance.database;
    return await db
        .update('productos', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> eliminar(int id) async {
    final db = await DBHelper.instance.database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> descontarStock(int id, int cantidad) async {
    final db = await DBHelper.instance.database;
    await db.rawUpdate(
      'UPDATE productos SET stock = stock - ? WHERE id = ? AND stock >= ?',
      [cantidad, id, cantidad],
    );
  }

  String? validarTitulo(String? v) {
    if (v == null || v.trim().isEmpty) return 'El título es obligatorio';
    if (v.trim().length < MIN_TITULO) return 'Mínimo $MIN_TITULO caracteres';
    if (v.trim().length > MAX_TITULO) return 'Máximo $MAX_TITULO caracteres';
    return null;
  }

  String? validarDescripcion(String? v) {
    if (v == null || v.trim().isEmpty) return 'La descripción es obligatoria';
    if (v.trim().length < MIN_DESCRIPCION)
      return 'Mínimo $MIN_DESCRIPCION caracteres';
    if (v.trim().length > MAX_DESCRIPCION)
      return 'Máximo $MAX_DESCRIPCION caracteres';
    return null;
  }

  String? validarPrecio(String? v) {
    if (v == null || v.trim().isEmpty) return 'El precio es obligatorio';
    final p = double.tryParse(v.replaceAll(',', '.'));
    if (p == null) return 'Ingresa un número válido';
    if (p < MIN_PRECIO) return 'Mínimo \$$MIN_PRECIO';
    if (p > MAX_PRECIO) return 'Máximo \$$MAX_PRECIO';
    return null;
  }

  String? validarStock(String? v) {
    if (v == null || v.trim().isEmpty) return 'El stock es obligatorio';
    final s = int.tryParse(v);
    if (s == null) return 'Ingresa un número entero';
    if (s < MIN_STOCK) return 'No puede ser negativo';
    if (s > MAX_STOCK) return 'Máximo $MAX_STOCK unidades';
    return null;
  }

  String? validarImagenUrl(String? v) {
    if (v == null || v.trim().isEmpty)
      return 'La URL de la imagen es obligatoria';
    final url = v.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'Debe empezar con http:// o https://';
    }
    if (!RegExp(r'^https?://[\w\-\.]+\.[a-zA-Z]{2,}').hasMatch(url)) {
      return 'URL no válida';
    }
    return null;
  }
}
