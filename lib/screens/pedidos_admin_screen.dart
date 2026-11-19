// Panel del admin para gestionar TODOS los pedidos.
// Incluye: ubicación GPS con mapa, botón "cómo llegar" con ruta real,
// cambio de estado, filtros por estado y eliminar.
import 'package:flutter/material.dart';

import '../models/pedido.dart';
import '../services/pedido_service.dart';
import '../helpers/location_helper.dart';
import '../theme/app_theme.dart';

class PedidosAdminScreen extends StatefulWidget {
  const PedidosAdminScreen({super.key});
  @override
  State<PedidosAdminScreen> createState() => _PedidosAdminScreenState();
}

class _PedidosAdminScreenState extends State<PedidosAdminScreen> {
  final _service = PedidoService();
  List<Pedido> _pedidos = [];
  List<Pedido> _filtrados = [];
  String _filtroEstado = 'todos';
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
      _pedidos = l;
      _aplicarFiltro();
      _cargando = false;
    });
  }

  void _aplicarFiltro() {
    if (_filtroEstado == 'todos') {
      _filtrados = _pedidos;
    } else {
      _filtrados = _pedidos.where((p) => p.estado == _filtroEstado).toList();
    }
  }

  Future<void> _cambiarEstado(Pedido p, String nuevoEstado) async {
    await _service.cambiarEstado(p.id!, nuevoEstado);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido marcado como "$nuevoEstado"'),
        backgroundColor: AppColores.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _cargar();
  }

  Future<void> _eliminar(Pedido p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar pedido'),
        content: Text(
          '¿Eliminar el pedido #${p.id}? Esta acción no se puede deshacer.',
        ),
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

  // ============ MODAL DE DETALLE ============
  void _verDetalle(Pedido p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ---- Barra de arrastre ----
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ---- Header con folio y estado ----
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColores.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${p.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          p.fechaCorta,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColores.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _chipEstado(p.estado),
                ],
              ),
            ),
            const Divider(height: 1),

            // ---- Contenido scrolleable ----
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ============ CLIENTE ============
                  const Text(
                    'Cliente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColores.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.usuarioNombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    p.usuarioCorreo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColores.textSecondary,
                    ),
                  ),

                  // ============ UBICACIÓN GPS ============
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColores.primaryDark,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Ubicación de la compra',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColores.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (p.tieneUbicacion)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColores.pastelBlue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColores.pastelBlueDark.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                color: AppColores.pastelBlueDark,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Coordenadas GPS',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Latitud
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Text(
                              'Latitud:  ${p.latitud!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Longitud
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Text(
                              'Longitud: ${p.longitud!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),

                          // Dirección (si existe)
                          if (p.direccion != null &&
                              p.direccion!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 18,
                                  color: AppColores.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.direccion!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 14),

                          // ⚡ 2 BOTONES: Ver mapa y Cómo llegar (con ruta real)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColores.pastelBlueDark,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final ok = await LocationHelper.abrirMapa(
                                      lat: p.latitud,
                                      lng: p.longitud,
                                    );
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No se pudo abrir el mapa. Verifica que el emulador tenga navegador.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                    }
                                  },
                                  icon: const Icon(Icons.map, size: 16),
                                  label: const Text(
                                    'VER MAPA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColores.pastelPeachDark,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final ok = await LocationHelper.abrirRuta(
                                      destinoLat: p.latitud!,
                                      destinoLng: p.longitud!,
                                    );
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No se pudo abrir la ruta. Verifica que el emulador tenga navegador.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                    }
                                  },
                                  icon: const Icon(Icons.directions, size: 16),
                                  label: const Text(
                                    'CÓMO LLEGAR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Sin ubicación registrada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ============ PRODUCTOS ============
                  const SizedBox(height: 24),
                  const Text(
                    'Productos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColores.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...p.items.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColores.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: (it['imagen_url'] ?? '').isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      it['imagen_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it['titulo'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${it['cantidad']} x \$${(it['precio'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColores.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${((it['precio'] as num) * (it['cantidad'] as int)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColores.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        p.totalFormateado,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColores.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ============ BOTONES DE ACCIÓN ============
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColores.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: p.estado == 'entregado'
                          ? null
                          : () {
                              Navigator.pop(context);
                              _cambiarEstado(p, 'entregado');
                            },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Entregar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColores.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: p.estado == 'cancelado'
                          ? null
                          : () {
                              Navigator.pop(context);
                              _cambiarEstado(p, 'cancelado');
                            },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ COLORES Y CHIPS ============
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppColores.pedidoPendiente;
      case 'entregado':
        return AppColores.pedidoEntregado;
      case 'cancelado':
        return AppColores.pedidoCancelado;
      default:
        return AppColores.textSecondary;
    }
  }

  Widget _chipEstado(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _colorEstado(estado).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _colorEstado(estado),
        ),
      ),
    );
  }

  Widget _statChip(String label, int valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $valor',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _filtroChip(String label, String valor) {
    final sel = _filtroEstado == valor;
    return InkWell(
      onTap: () {
        setState(() {
          _filtroEstado = valor;
          _aplicarFiltro();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: sel ? AppColores.primaryGradient : null,
          color: sel ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : AppColores.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============ BUILD PRINCIPAL ============
  @override
  Widget build(BuildContext context) {
    final pendientes = _pedidos.where((p) => p.estado == 'pendiente').length;
    final entregados = _pedidos.where((p) => p.estado == 'entregado').length;
    final cancelados = _pedidos.where((p) => p.estado == 'cancelado').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ---- Header con estadísticas ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppColores.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_checkout,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_pedidos.length} pedidos en total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statChip('Pendientes', pendientes, Colors.orange.shade200),
                    const SizedBox(width: 8),
                    _statChip('Entregados', entregados, Colors.green.shade200),
                    const SizedBox(width: 8),
                    _statChip('Cancelados', cancelados, Colors.red.shade200),
                  ],
                ),
              ],
            ),
          ),

          // ---- Filtros ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filtroChip('Todos', 'todos'),
                  const SizedBox(width: 8),
                  _filtroChip('Pendientes', 'pendiente'),
                  const SizedBox(width: 8),
                  _filtroChip('Entregados', 'entregado'),
                  const SizedBox(width: 8),
                  _filtroChip('Cancelados', 'cancelado'),
                ],
              ),
            ),
          ),

          // ---- Lista de pedidos ----
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay pedidos',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            onTap: () => _verDetalle(p),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  // Fila superior: icono, folio, nombre, chip
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: AppColores.primaryGradient,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pedido #${p.id}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              p.usuarioNombre,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColores.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _chipEstado(p.estado),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Fila: productos y total
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 14,
                                        color: AppColores.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.cantidadTotal} productos',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColores.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        p.totalFormateado,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColores.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Fila: fecha, GPS, eliminar
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        p.fechaCorta,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (p.tieneUbicacion) ...[
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: AppColores.pastelBlueDark,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'GPS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColores.pastelBlueDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _eliminar(p),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Eliminar pedido',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
}
