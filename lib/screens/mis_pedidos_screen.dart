// Pantalla donde el usuario ve SUS pedidos anteriores.
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';
import '../theme/app_theme.dart';

class MisPedidosScreen extends StatefulWidget {
  final Usuario usuario;
  const MisPedidosScreen({super.key, required this.usuario});
  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  final _service = PedidoService();
  List<Pedido> _pedidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final l = await _service.obtenerPorUsuario(widget.usuario.id!);
    if (!mounted) return;
    setState(() {
      _pedidos = l;
      _cargando = false;
    });
  }

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
      child: Text(estado.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _colorEstado(estado))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: AppColores.secondaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: AppColores.darkGradient),
            child: Row(children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Text('${_pedidos.length} pedidos realizados',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _pedidos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aún no has hecho pedidos',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Ve al catálogo y compra algo',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pedidos.length,
                          itemBuilder: (_, i) {
                            final p = _pedidos[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient:
                                                AppColores.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.receipt_long,
                                              color: Colors.white, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Pedido #${p.id}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              Text(p.fechaCorta,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColores
                                                          .textSecondary)),
                                            ],
                                          ),
                                        ),
                                        _chipEstado(p.estado),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.shopping_bag_outlined,
                                            size: 14,
                                            color: AppColores.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('${p.cantidadTotal} productos',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColores.textSecondary)),
                                        const Spacer(),
                                        Text(p.totalFormateado,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColores.primary)),
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
}
