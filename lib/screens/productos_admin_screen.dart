// Panel del admin para gestionar PRODUCTOS con tema nuevo.
import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import 'producto_form_screen.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});
  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  final _service = ProductoService();
  List<Producto> _productos = [];
  List<Producto> _filtrados = [];
  final _buscador = TextEditingController();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final l = await _service.obtenerTodos();
    if (!mounted) return;
    setState(() {
      _productos = l;
      _filtrados = l;
      _cargando = false;
    });
  }

  void _filtrar(String q) {
    q = q.toLowerCase();
    setState(() {
      _filtrados = _productos
          .where((p) =>
              p.titulo.toLowerCase().contains(q) ||
              p.descripcion.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _eliminar(Producto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber, color: AppColores.error),
          const SizedBox(width: 8),
          const Text('Eliminar producto'),
        ]),
        content: Text(
            '¿Seguro que quieres eliminar "${p.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColores.error),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.eliminar(p.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Producto eliminado'),
        backgroundColor: AppColores.success,
        behavior: SnackBarBehavior.floating,
      ));
      _cargar();
    }
  }

  Color _colorStock(int stock) {
    if (stock == 0) return AppColores.error;
    if (stock <= ProductoService.STOCK_BAJO) return AppColores.warning;
    return AppColores.success;
  }

  @override
  Widget build(BuildContext context) {
    final stockBajo = _productos
        .where((p) => p.stock > 0 && p.stock <= ProductoService.STOCK_BAJO)
        .length;
    final agotados = _productos.where((p) => p.stock == 0).length;
    final cercaDelLimite = _productos.length >= ProductoService.ALERTA_CATALOGO;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration:
                const BoxDecoration(gradient: AppColores.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.inventory_2, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Text(
                      '${_productos.length}/${ProductoService.MAX_PRODUCTOS} productos',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ]),
                if (agotados > 0 || stockBajo > 0) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    if (agotados > 0)
                      _chipContador('$agotados agotados', Colors.red.shade100),
                    if (agotados > 0 && stockBajo > 0) const SizedBox(width: 8),
                    if (stockBajo > 0)
                      _chipContador(
                          '$stockBajo con stock bajo', Colors.orange.shade100),
                  ]),
                ],
              ],
            ),
          ),
          if (cercaDelLimite)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColores.softGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber,
                      color: AppColores.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Te quedan ${ProductoService.MAX_PRODUCTOS - _productos.length} espacios antes de alcanzar el límite.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColores.primaryDark),
                    ),
                  ),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscador,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay productos',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Presiona + para agregar uno',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) {
                            final p = _filtrados[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: p.imagenUrl.isEmpty
                                            ? Container(
                                                color: AppColores.background,
                                                child: const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey),
                                              )
                                            : Image.network(
                                                p.imagenUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  color: AppColores.background,
                                                  child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.titulo,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          if (p.descripcion.isNotEmpty)
                                            Text(p.descripcion,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColores
                                                        .textSecondary),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            Text(p.precioFormateado,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColores.primary)),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _colorStock(p.stock)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (p.stock == 0)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 2),
                                                      child: Icon(Icons.block,
                                                          size: 10,
                                                          color: _colorStock(
                                                              p.stock)),
                                                    ),
                                                  Text(
                                                    p.stock == 0
                                                        ? 'AGOTADO'
                                                        : 'Stock: ${p.stock}',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: _colorStock(
                                                            p.stock),
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: AppColores.primary),
                                          onPressed: () async {
                                            final ok =
                                                await Navigator.push<bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProductoFormScreen(
                                                                producto: p)));
                                            if (ok == true) _cargar();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: AppColores.error),
                                          onPressed: () => _eliminar(p),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_productos.length >= ProductoService.MAX_PRODUCTOS) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Catálogo lleno (${ProductoService.MAX_PRODUCTOS} productos máximo)'),
              backgroundColor: AppColores.error,
              behavior: SnackBarBehavior.floating,
            ));
            return;
          }
          final ok = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const ProductoFormScreen()));
          if (ok == true) _cargar();
        },
        backgroundColor: AppColores.primary,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
      ),
    );
  }

  Widget _chipContador(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }
}
