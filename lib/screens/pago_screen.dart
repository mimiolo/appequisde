import 'package:flutter/material.dart';

import '../helpers/mail_helper.dart';
import '../helpers/notification_helper.dart';
import '../models/pedido.dart';
import '../models/usuario.dart';
import '../services/paypal_service.dart';
import '../services/producto_service.dart';
import '../services/pedido_service.dart';
import '../services/actividad_service.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_theme.dart';
import 'ticket_screen.dart';
import 'paypal_checkout_screen.dart';

class PagoScreen extends StatefulWidget {
  final Usuario usuario;
  final List<Map<String, dynamic>> items;
  final double total;

  const PagoScreen({
    super.key,
    required this.usuario,
    required this.items,
    required this.total,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  String _metodo = 'tarjeta';
  bool _procesando = false;

  Future<void> _pagar() async {
    if (_metodo == 'paypal') {
      setState(() => _procesando = true);

      // ⚡ CONSULTAR SALDO
      final saldo = await PayPalService.obtenerSaldoPayPal();

      if (!mounted) return;

      // ⚡ RESTRICCIÓN 1: Error de conexión con PayPal
      if (saldo == null) {
        setState(() => _procesando = false);
        _mostrarAlerta(
          titulo: 'Error de conexión',
          mensaje: 'No se pudo consultar tu saldo de PayPal. Revisa tu conexión a internet o intenta más tarde.',
          icono: Icons.wifi_off,
        );
        return;
      }

      // ⚡ RESTRICCIÓN 2: Saldo en $0.00 (Sin fondos)
      if (saldo <= 0.0) {
        setState(() => _procesando = false);
        _mostrarAlerta(
          titulo: 'Cuenta sin fondos',
          mensaje: 'Tu saldo disponible en PayPal es de \$0.00 MXN.\n\nNo puedes realizar compras sin saldo. Por favor, agrega fondos o usa otro método de pago.',
          icono: Icons.account_balance_wallet_outlined,
        );
        return;
      }

      // ⚡ RESTRICCIÓN 3: Saldo menor al total de la compra
      if (saldo < widget.total) {
        setState(() => _procesando = false);
        _mostrarAlerta(
          titulo: 'Saldo insuficiente',
          mensaje:
              'Tu saldo actual es de \$${saldo.toStringAsFixed(2)} MXN.\n\nEl total a pagar es de \$${widget.total.toStringAsFixed(2)} MXN.\n\nTe faltan \$${(widget.total - saldo).toStringAsFixed(2)} MXN.',
          icono: Icons.warning_amber_rounded,
        );
        return;
      }
    }

    // Si pasa las restricciones, procedemos al pago
    setState(() => _procesando = true);

    if (_metodo == 'paypal') {
      final orden = await PayPalService.crearOrden(
        monto: widget.total,
        descripcion: 'Compra en Seguridad App',
      );
      if (!mounted) return;

      if (orden == null) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo generar la orden de PayPal'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final orderId = orden['orderId']!;
      final approvalUrl = orden['approvalUrl']!;

      final aprobado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PayPalCheckoutScreen(approvalUrl: approvalUrl, orderId: orderId),
        ),
      );
      if (!mounted) return;

      if (aprobado != true) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago cancelado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final capturado = await PayPalService.capturarOrden(orderId);
      if (!mounted) return;

      if (!capturado) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo capturar el pago'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      // Simulación para otros métodos
      await Future.delayed(const Duration(seconds: 2));
    }

    // ---- GUARDADO Y TICKET ----
    final productoService = ProductoService();
    final pedidoService = PedidoService();
    final fecha = DateTime.now();

    try {
      final ubicacion = await UbicacionService.obtenerUbicacion();
      for (var it in widget.items) {
        await productoService.descontarStock(
          it['id'] as int,
          it['cantidad'] as int,
        );
      }
      final pedidoId = await pedidoService.crear(
        Pedido(
          usuarioId: widget.usuario.id!,
          usuarioNombre: widget.usuario.nombreCompleto,
          usuarioCorreo: widget.usuario.correo,
          total: widget.total,
          estado: 'pendiente',
          items: widget.items,
          latitud: ubicacion?.latitude,
          longitud: ubicacion?.longitude,
        ),
      );
      final folio =
          'TKT-${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}-$pedidoId';
      await MailHelper.sendPurchaseSummaryEmail(
        destino: widget.usuario.correo,
        nombreCliente: widget.usuario.nombreCompleto,
        items: widget.items,
        total: widget.total,
        folio: folio,
        fecha: fecha,
      );
      await ActividadService().registrar(
        'compra',
        usuarioId: widget.usuario.id,
        correo: widget.usuario.correo,
        detalle: 'Pago con $_metodo por \$${widget.total.toStringAsFixed(2)}',
      );

      try {
        await NotificationHelper.mostrar(
          titulo: '✅ Pago confirmado',
          cuerpo:
              'Tu pago de \$${widget.total.toStringAsFixed(2)} fue procesado',
        );
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketScreen(
            usuario: widget.usuario,
            folio: folio,
            items: widget.items,
            total: widget.total,
            fecha: fecha,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ⚡ Función auxiliar para mostrar alertas bonitas
  void _mostrarAlerta({
    required String titulo,
    required String mensaje,
    required IconData icono,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icono, color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text(titulo)),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método de pago'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Selecciona tu método de pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _metodoTile(
              'tarjeta',
              Icons.credit_card,
              'Tarjeta de crédito/débito',
              'Simulado',
            ),
            _metodoTile(
              'paypal',
              Icons.account_balance_wallet,
              'PayPal',
              'Sandbox (pruebas reales)',
            ),
            _metodoTile(
              'google',
              Icons.g_mobiledata,
              'Google Wallet',
              'Simulado',
            ),
            _metodoTile('apple', Icons.apple, 'Apple Pay', 'Simulado'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColores.accentLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a pagar', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${widget.total.toStringAsFixed(2)} MXN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColores.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _metodo == 'paypal'
                      ? Colors.blue.shade700
                      : AppColores.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _procesando ? null : _pagar,
                icon: _procesando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _metodo == 'paypal'
                            ? Icons.account_balance_wallet
                            : Icons.lock,
                      ),
                label: Text(
                  _procesando
                      ? 'PROCESANDO...'
                      : (_metodo == 'paypal'
                            ? 'PAGAR CON PAYPAL'
                            : 'PAGAR AHORA'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _metodo == 'paypal'
                  ? '🔒 Serás redirigido a PayPal Sandbox'
                  : '🔒 Este es un pago simulado',
              style: TextStyle(fontSize: 11, color: AppColores.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metodoTile(String id, IconData ico, String label, String subtitulo) {
    final seleccionado = _metodo == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: seleccionado
            ? BorderSide(color: AppColores.primary, width: 2)
            : BorderSide.none,
      ),
      child: RadioListTile<String>(
        value: id,
        groupValue: _metodo,
        onChanged: (v) => setState(() => _metodo = v!),
        secondary: Icon(
          ico,
          color: id == 'paypal' ? Colors.blue.shade700 : AppColores.primary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(fontSize: 11, color: AppColores.textSecondary),
        ),
        activeColor: AppColores.primary,
      ),
    );
  }
}
