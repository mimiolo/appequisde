import 'package:flutter/material.dart';

import '../services/punto_red_transaccion_service.dart';
import 'punto_red_ticket_screen.dart';
import '../models/punto_red_transaccion.dart';

class PuntoRedHistorialScreen extends StatefulWidget {
  final int? usuarioId;
  const PuntoRedHistorialScreen({super.key, this.usuarioId});

  @override
  State<PuntoRedHistorialScreen> createState() =>
      _PuntoRedHistorialScreenState();
}

class _PuntoRedHistorialScreenState extends State<PuntoRedHistorialScreen> {
  List<Map<String, dynamic>> _transacciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final data = widget.usuarioId != null
        ? await PuntoRedTransaccionService.obtenerPorUsuario(widget.usuarioId!)
        : await PuntoRedTransaccionService.obtenerTodas();
    if (mounted) {
      setState(() {
        _transacciones = data;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: Text(
          widget.usuarioId != null ? 'Mis pagos' : 'Historial Punto Red',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _transacciones.isEmpty
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
                    'No hay pagos exitosos registrados',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _transacciones.length,
                itemBuilder: (context, index) {
                  final t = _transacciones[index];
                  final fecha = (t['createdAT'] as String? ?? '')
                      .split('.')
                      .first;
                  final monto = (t['monto'] as num?)?.toDouble() ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9575CD).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Color(0xFF7451A8),
                        ),
                      ),
                      title: Text(
                        t['producto'] ?? 'Producto',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['servicio'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fecha,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${monto.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7451A8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Exitoso',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        final tx = PuntoRedTransaccion(
                          idTx: t['id_tx'] ?? '',
                          numAutorizacion: t['num_autorizacion'] ?? '',
                          saldo: (t['saldo'] as num?)?.toDouble() ?? 0,
                          comision: (t['comision'] as num?)?.toDouble() ?? 0,
                          monto: monto,
                          fecha: t['fecha'] ?? '',
                          mensaje: '',
                          codigoMensaje: '01',
                          raw: {},
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PuntoRedTicketScreen(
                              tx: tx,
                              servicio: t['servicio'] ?? '',
                              producto: t['producto'] ?? '',
                              telefono: t['telefono'] ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
