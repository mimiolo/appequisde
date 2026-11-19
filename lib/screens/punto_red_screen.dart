import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/punto_red_producto.dart';
import '../models/usuario.dart';
import '../services/punto_red_service.dart';
import '../services/punto_red_logo_service.dart';
import '../theme/app_theme.dart';
import 'punto_red_pago_screen.dart';

class PuntoRedScreen extends StatefulWidget {
  final Usuario? usuario;
  const PuntoRedScreen({super.key, this.usuario});

  @override
  State<PuntoRedScreen> createState() => _PuntoRedScreenState();
}

class _PuntoRedScreenState extends State<PuntoRedScreen> {
  final PuntoRedService _service = PuntoRedService();
  final TextEditingController _buscador = TextEditingController();

  List<PuntoRedProducto> _productos = [];
  final Set<String> _serviciosAbiertos = {};

  bool _cargando = true;
  String _busqueda = '';

  static const Color _fondo = Color(0xFFF8F7FC);
  static const Color _morado = Color(0xFF9575CD);
  static const Color _moradoOscuro = Color(0xFF7451A8);
  static const Color _texto = Color(0xFF2E2E2E);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);
    try {
      final productos = await _service.obtenerTodos();
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el catálogo: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<PuntoRedProducto> get _productosFiltrados {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _productos;
    return _productos.where((p) {
      return p.servicio.toLowerCase().contains(q) ||
          p.producto.toLowerCase().contains(q) ||
          p.idServicio.toLowerCase().contains(q) ||
          p.idProducto.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<PuntoRedProducto>> get _grupos {
    final Map<String, List<PuntoRedProducto>> grupos = {};
    for (final producto in _productosFiltrados) {
      grupos.putIfAbsent(producto.servicio, () => []);
      grupos[producto.servicio]!.add(producto);
    }
    return grupos;
  }

  void _alternarServicio(String servicio) {
    setState(() {
      if (_serviciosAbiertos.contains(servicio)) {
        _serviciosAbiertos.remove(servicio);
      } else {
        _serviciosAbiertos.add(servicio);
      }
    });
  }

  void _alternarTodos() {
    final servicios = _grupos.keys.toSet();
    setState(() {
      if (_serviciosAbiertos.containsAll(servicios) && servicios.isNotEmpty) {
        _serviciosAbiertos.clear();
      } else {
        _serviciosAbiertos
          ..clear()
          ..addAll(servicios);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos;
    final cantidad = _productosFiltrados.length;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _moradoOscuro,
        title: const Text(
          'Catálogo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Qué vas a pagar hoy?',
                    style: TextStyle(
                      color: Colors.black87, // ⚡ Negro
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: _fondo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ), // Borde más visible
                    ),
                    child: TextField(
                      controller: _buscador,
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (valor) {
                        setState(() {
                          _busqueda = valor;
                          if (valor.trim().isNotEmpty) {
                            _serviciosAbiertos
                              ..clear()
                              ..addAll(_grupos.keys);
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar servicio...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade700,
                        ), // ⚡ Más oscuro
                        prefixIcon: const Icon(
                          Icons.search,
                          color: _moradoOscuro,
                        ),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _buscador.clear();
                                  setState(() {
                                    _busqueda = '';
                                    _serviciosAbiertos.clear();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$cantidad resultados',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // ⚡ Más oscuro
                    ),
                  ),
                  TextButton.icon(
                    onPressed: grupos.isEmpty ? null : _alternarTodos,
                    icon: Icon(
                      _serviciosAbiertos.containsAll(grupos.keys) &&
                              grupos.isNotEmpty
                          ? Icons.unfold_less
                          : Icons.unfold_more,
                      size: 18,
                    ),
                    label: Text(
                      _serviciosAbiertos.containsAll(grupos.keys) &&
                              grupos.isNotEmpty
                          ? 'Contraer todo'
                          : 'Abrir todo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(foregroundColor: _moradoOscuro),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _morado),
                    )
                  : grupos.isEmpty
                  ? _estadoVacio()
                  : RefreshIndicator(
                      color: _morado,
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: grupos.length,
                        itemBuilder: (context, index) {
                          final servicio = grupos.keys.elementAt(index);
                          final productos = grupos[servicio]!;
                          return _tarjetaServicio(servicio, productos);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaServicio(String servicio, List<PuntoRedProducto> productos) {
    final abierto = _serviciosAbiertos.contains(servicio);
    final primerProducto = productos.first;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: abierto ? _morado.withOpacity(0.4) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _alternarServicio(servicio),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _fondo,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _logo(primerProducto.idServicio),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87, // ⚡ Negro
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${productos.length} productos disponibles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800, // ⚡ Más oscuro
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: abierto ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _fondo,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _moradoOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: abierto
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade200),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: productos.length,
                    itemBuilder: (_, i) => _tarjetaProducto(productos[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaProducto(PuntoRedProducto producto) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _morado.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _morado.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            // Quita la palabra "const" de BoxDecoration
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_morado, _moradoOscuro],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Text(
              producto.precioFormateado,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    producto.producto,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // ⚡ Negro
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  if (producto.legend.isNotEmpty)
                    Text(
                      producto.legend,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700, // ⚡ Más oscuro
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _moradoOscuro,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuntoRedPagoScreen(
                      producto: producto,
                      usuarioId: widget.usuario?.id,
                      usuarioCorreo: widget.usuario?.correo,
                    ),
                  ),
                ),
                child: const Text(
                  'PAGAR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo(String idServicio) {
    return FutureBuilder<Uint8List?>(
      future: PuntoRedLogoService.obtenerLogo(idServicio),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _iconoServicio(),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _morado),
            ),
          );
        }
        return _iconoServicio();
      },
    );
  }

  Widget _iconoServicio() {
    return const Icon(Icons.storefront_rounded, color: _moradoOscuro, size: 30);
  }

  Widget _estadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 70, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            _busqueda.isEmpty ? 'No hay servicios' : 'Sin resultados',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // ⚡ Negro
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
