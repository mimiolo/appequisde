// Catálogo para usuarios NO admin. Ahora recibe el usuario para asociarlo al pedido.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import 'carrito_screen.dart';

class ProductosOnlineScreen extends StatefulWidget {
  final Usuario? usuario;
  const ProductosOnlineScreen({super.key, this.usuario});

  @override
  State<ProductosOnlineScreen> createState() => _ProductosOnlineScreenState();
}

class _ProductosOnlineScreenState extends State<ProductosOnlineScreen> {
  final _service = ProductoService();
  List<Producto> _productos = [];
  List<Producto> _filtrados = [];
  final _buscador = TextEditingController();
  List<Map<String, dynamic>> _cart = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarCarrito();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    final l = await _service.obtenerTodos();
    if (!mounted) return;
    setState(() {
      _productos = l;
      _filtrados = l;
      _cargando = false;
    });
  }

  Future<void> _cargarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_cart');
    if (saved != null && mounted) {
      setState(() {
        _cart = List<Map<String, dynamic>>.from(
            json.decode(saved) as List<dynamic>);
      });
    }
  }

  Future<void> _guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_cart', json.encode(_cart));
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

  Future<void> _agregarAlCarrito(Producto p, int cantidad) async {
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La cantidad debe ser mayor a 0'),
        backgroundColor: AppColores.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (cantidad > p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Solo hay ${p.stock} unidades disponibles'),
        backgroundColor: AppColores.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final idxExistente = _cart.indexWhere((i) => i['id'] == p.id);
    if (idxExistente != -1) {
      final enCarrito = _cart[idxExistente]['cantidad'] as int;
      if (enCarrito + cantidad > p.stock) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Ya tienes $enCarrito en el carrito. Solo puedes agregar ${p.stock - enCarrito} más.'),
          backgroundColor: AppColores.warning,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }

    setState(() {
      if (idxExistente != -1) {
        _cart[idxExistente]['cantidad'] += cantidad;
      } else {
        _cart.add({
          'id': p.id,
          'titulo': p.titulo,
          'precio': p.precio,
          'cantidad': cantidad,
          'imagen_url': p.imagenUrl,
        });
      }
    });

    await _guardarCarrito();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${p.titulo} agregado (x$cantidad)'),
      backgroundColor: AppColores.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  void _pedirCantidad(Producto p) {
    final ctrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cantidad (stock: ${p.stock})'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Unidades',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColores.primary),
            onPressed: () {
              final q = int.tryParse(ctrl.text) ?? 1;
              Navigator.pop(context);
              _agregarAlCarrito(p, q);
            },
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CarritoScreen(
                              carrito: _cart, usuario: widget.usuario)));
                  _cargarCarrito();
                },
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColores.error,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${_cart.fold<int>(0, (s, i) => s + (i['cantidad'] as int))}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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
                            Icon(Icons.shopping_bag_outlined,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay productos disponibles',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarProductos,
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
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 90,
                                        height: 90,
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
                                          Text(p.descripcion,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColores.textSecondary),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Text(p.precioFormateado,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColores.primary)),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.hayStock
                                                ? 'Disponibles: ${p.stock}'
                                                : 'Sin stock',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: p.hayStock
                                                    ? AppColores.textSecondary
                                                    : AppColores.error,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: p.hayStock
                                                ? AppColores.primary
                                                : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          onPressed: p.hayStock
                                              ? () => _pedirCantidad(p)
                                              : null,
                                          child: const Text('Comprar'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.share,
                                              color: AppColores.secondary),
                                          onPressed: () {
                                            Share.share(
                                              '¡Mira este producto!\n\n'
                                              '${p.titulo}\n'
                                              '${p.descripcion}\n'
                                              'Precio: ${p.precioFormateado}',
                                              subject: 'Producto recomendado',
                                            );
                                          },
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
    );
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }
}
