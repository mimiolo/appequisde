// Servicio para parsear el XML de Punto Red y guardar/cargar de SQLite.
import 'package:xml/xml.dart';
import 'package:sqflite/sqflite.dart'; // ⚡ ESTA era la que faltaba

import '../db/db_helper.dart';
import '../models/punto_red_producto.dart';

class PuntoRedResponse {
  final String codigo;
  final String texto;
  final List<PuntoRedProducto> productos;

  PuntoRedResponse({
    required this.codigo,
    required this.texto,
    required this.productos,
  });
}

class PuntoRedService {
  /// Parsea el XML crudo y devuelve la respuesta completa.
  PuntoRedResponse parsearXml(String xmlString) {
    final doc = XmlDocument.parse(xmlString);

    // ---- MENSAJE ----
    final mensaje = doc.findAllElements('MENSAJE').first;
    final codigo = mensaje.findElements('CODIGO').first.innerText;
    final texto = mensaje.findElements('TEXTO').first.innerText;

    // ---- PRODUCTOS ----
    final productos = <PuntoRedProducto>[];
    for (final el in doc.findAllElements('producto')) {
      final legendEl = el.findElements('legend').isEmpty
          ? null
          : el.findElements('legend').first;

      productos.add(
        PuntoRedProducto(
          servicio: el.getAttribute('servicio') ?? '',
          producto: el.getAttribute('producto') ?? '',
          idServicio: el.getAttribute('idServicio') ?? '',
          idProducto: el.getAttribute('idProducto') ?? '',
          idCatTipoServicio: el.getAttribute('idCatTipoServicio') ?? '',
          tipoFront: el.getAttribute('tipoFront') ?? '',
          hasDigitoVerificador:
              (el.getAttribute('hasDigitoVerificador') ?? 'false') == 'true',
          precio: double.tryParse(el.getAttribute('precio') ?? '0') ?? 0.0,
          showAyuda: (el.getAttribute('showAyuda') ?? 'false') == 'true',
          tipoReferencia: el.getAttribute('tipoReferencia') ?? '',
          legend: legendEl?.innerText.trim() ?? '',
        ),
      );
    }

    return PuntoRedResponse(codigo: codigo, texto: texto, productos: productos);
  }

  /// Parsea, guarda todo en la BD y devuelve cuántos se insertaron.
  Future<int> parsearYGuardar(String xmlString) async {
    final respuesta = parsearXml(xmlString);
    return await guardarProductos(respuesta.productos);
  }

  /// Guarda la lista completa. Usa INSERT OR REPLACE (id_producto es UNIQUE).
  Future<int> guardarProductos(List<PuntoRedProducto> productos) async {
    final db = await DBHelper.instance.database;
    final batch = db.batch();
    for (final p in productos) {
      batch.insert(
        'punto_red_productos',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return productos.length;
  }

  /// Obtiene todos los productos guardados.
  Future<List<PuntoRedProducto>> obtenerTodos() async {
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'punto_red_productos',
      orderBy: 'servicio ASC, precio ASC',
    );
    return r.map((m) => PuntoRedProducto.fromMap(m)).toList();
  }

  /// Busca por nombre de producto o servicio.
  Future<List<PuntoRedProducto>> buscar(String query) async {
    if (query.trim().isEmpty) return obtenerTodos();
    final q = '%${query.trim()}%';
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'punto_red_productos',
      where: 'producto LIKE ? OR servicio LIKE ?',
      whereArgs: [q, q],
      orderBy: 'servicio ASC, precio ASC',
      limit: 200,
    );
    return r.map((m) => PuntoRedProducto.fromMap(m)).toList();
  }

  /// Obtiene todos los productos de un servicio específico.
  Future<List<PuntoRedProducto>> obtenerPorServicio(String servicio) async {
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'punto_red_productos',
      where: 'servicio = ?',
      whereArgs: [servicio],
      orderBy: 'precio ASC',
    );
    return r.map((m) => PuntoRedProducto.fromMap(m)).toList();
  }

  /// Devuelve la lista DISTINTA de servicios (para el menú lateral).
  Future<List<String>> obtenerServicios() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT DISTINCT servicio FROM punto_red_productos ORDER BY servicio ASC',
    );
    return r.map((m) => m['servicio'] as String).toList();
  }

  /// Cuenta cuántos productos hay guardados.
  Future<int> contarProductos() async {
    final db = await DBHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as total FROM punto_red_productos',
    );
    return (r.first['total'] as int?) ?? 0;
  }

  /// Limpia toda la tabla (útil para re-importar).
  Future<void> limpiar() async {
    final db = await DBHelper.instance.database;
    await db.delete('punto_red_productos');
  }
}
