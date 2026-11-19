import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../models/usuario.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import 'mis_pedidos_screen.dart';
import 'ubicacion_screen.dart';
import 'producto_form_screen.dart';
import 'carrito_screen.dart';
import 'punto_red_historial_screen.dart';
import 'punto_red_screen.dart'; // ⚡ IMPORT PARA PUNTO RED

class UserScreen extends StatefulWidget {
  final Usuario usuario;
  const UserScreen({super.key, required this.usuario});
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _service = ProductoService();
  final _buscador = TextEditingController();
  List<Producto> _productos = [];
  List<Producto> _filtrados = [];
  List<Map<String, dynamic>> _cart = [];
  bool _cargando = true;

  bool get _esEditor => widget.usuario.roleId == 2;
  Color get _color =>
      _esEditor ? AppColores.pastelPeachDark : AppColores.pastelMintDark;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarCarrito();
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

  Future<void> _cargarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_cart');
    if (saved != null && mounted) {
      setState(() {
        _cart = List<Map<String, dynamic>>.from(
          json.decode(saved) as List<dynamic>,
        );
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
          .where(
            (p) =>
                p.titulo.toLowerCase().contains(q) ||
                p.descripcion.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  Future<void> _agregarAlCarrito(Producto p, int cantidad) async {
    if (cantidad <= 0) {
      _snack('La cantidad debe ser mayor a 0', AppColores.error);
      return;
    }
    if (cantidad > p.stock) {
      _snack('Solo hay ${p.stock} unidades disponibles', AppColores.error);
      return;
    }

    final idx = _cart.indexWhere((i) => i['id'] == p.id);
    if (idx != -1) {
      final actual = _cart[idx]['cantidad'] as int;
      if (actual + cantidad > p.stock) {
        _snack(
          'Ya tienes $actual en el carrito. Solo puedes agregar ${p.stock - actual} más.',
          AppColores.warning,
        );
        return;
      }
    }

    setState(() {
      if (idx != -1) {
        _cart[idx]['cantidad'] = (_cart[idx]['cantidad'] as int) + cantidad;
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
    _snack('${p.titulo} agregado (x$cantidad)', AppColores.success);
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
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Unidades',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColores.primary,
            ),
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

  void _abrirCarrito() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarritoScreen(carrito: _cart, usuario: widget.usuario),
      ),
    );
    _cargarCarrito();
  }

  Future<void> _abrirFormulario({Producto? producto}) async {
    if (!_esEditor) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: producto)),
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Producto p) async {
    if (!_esEditor) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColores.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.eliminar(p.id!);
      _cargar();
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCarrito = _cart.fold<int>(
      0,
      (s, i) => s + (i['cantidad'] as int),
    );

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _esEditor
                      ? [AppColores.pastelPeach, AppColores.pastelYellow]
                      : [AppColores.pastelMint, AppColores.pastelBlue],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.usuario.inicial,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.usuario.nombreCompleto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.usuario.rolNombre,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Catálogo'),
              selected: true,
              selectedTileColor: _color.withOpacity(0.15),
              onTap: () => Navigator.pop(context),
            ),
            // ⚡ PUNTO RED EN EL MENÚ DEL USUARIO
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Pagar servicios (Punto Red)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuntoRedScreen(usuario: widget.usuario),
                  ),
                );
              },
            ),
            // ⚡ HISTORIAL PUNTO RED EN EL MENÚ DEL USUARIO
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Mis pagos Punto Red'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PuntoRedHistorialScreen(usuarioId: widget.usuario.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Mi Carrito'),
              trailing: totalCarrito > 0
                  ? Chip(
                      label: Text(
                        '$totalCarrito',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: _color,
                      padding: EdgeInsets.zero,
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _abrirCarrito();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Mis Pedidos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MisPedidosScreen(usuario: widget.usuario),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Ubicación'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UbicacionScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificacionesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mi perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerfilScreen(usuario: widget.usuario),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(_esEditor ? 'Gestionar Productos' : 'Catálogo'),
        backgroundColor: _color,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _abrirCarrito,
                tooltip: 'Mi carrito',
              ),
              if (totalCarrito > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$totalCarrito',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilScreen(usuario: widget.usuario),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _esEditor
                    ? [AppColores.pastelPeach, AppColores.pastelYellow]
                    : [AppColores.pastelMint, AppColores.pastelBlue],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _esEditor ? Icons.edit_note : Icons.visibility,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${widget.usuario.nombre}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _esEditor
                            ? 'Puedes comprar y también gestionar productos'
                            : 'Explora el catálogo y compra lo que quieras',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_esEditor)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Presiona + para agregar uno',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) => _tarjetaProducto(_filtrados[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _esEditor
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              backgroundColor: _color,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto'),
            )
          : null,
    );
  }

  Widget _tarjetaProducto(Producto p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
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
                              color: Colors.grey,
                            ),
                          )
                        : Image.network(
                            p.imagenUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColores.background,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (p.descripcion.isNotEmpty)
                        Text(
                          p.descripcion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColores.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            p.precioFormateado,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColores.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _colorStock(p.stock).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.stock == 0 ? 'AGOTADO' : 'Stock: ${p.stock}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _colorStock(p.stock),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.hayStock
                          ? _color
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: p.hayStock ? () => _pedirCantidad(p) : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text(
                      'COMPRAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.share, color: AppColores.primaryDark),
                  tooltip: 'Compartir',
                  onPressed: () => Share.share(
                    '¡Mira este producto!\n\n${p.titulo}\n${p.descripcion}\nPrecio: ${p.precioFormateado}',
                    subject: 'Producto recomendado',
                  ),
                ),
                if (_esEditor)
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColores.primary),
                    tooltip: 'Editar',
                    onPressed: () => _abrirFormulario(producto: p),
                  ),
                if (_esEditor)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar',
                    onPressed: () => _eliminar(p),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorStock(int stock) {
    if (stock == 0) return AppColores.error;
    if (stock <= ProductoService.STOCK_BAJO) return AppColores.warning;
    return AppColores.success;
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }
}
