import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/punto_red_producto.dart';
import '../services/punto_red_pago_service.dart';
import '../services/punto_red_auth_service.dart';
import '../services/paypal_service.dart';
import '../theme/app_theme.dart';
import 'punto_red_ticket_screen.dart';
import 'paypal_checkout_screen.dart';

class PuntoRedPagoScreen extends StatefulWidget {
  final PuntoRedProducto producto;
  final int? usuarioId;
  final String? usuarioCorreo;

  const PuntoRedPagoScreen({
    super.key,
    required this.producto,
    this.usuarioId,
    this.usuarioCorreo,
  });

  @override
  State<PuntoRedPagoScreen> createState() => _PuntoRedPagoScreenState();
}

class _PuntoRedPagoScreenState extends State<PuntoRedPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificadorCtrl = TextEditingController();
  bool _procesando = false;
  String? _error;

  static const Color _morado = Color(0xFF9575CD);
  static const Color _moradoOscuro = Color(0xFF7451A8);
  static const Color _fondo = Color(0xFFF8F7FC);

  bool get _esRecarga {
    final nombre = widget.producto.servicio.toLowerCase();
    final prod = widget.producto.producto.toLowerCase();
    return nombre.contains('recarga') ||
        nombre.contains('tiempo aire') ||
        nombre.contains('paquete') ||
        nombre.contains('telcel') ||
        nombre.contains('att') ||
        nombre.contains('movistar') ||
        nombre.contains('bait') ||
        nombre.contains('unefon') ||
        prod.contains('recarga');
  }

  // ⚡ Botón para forzar el token de 24 hrs
  Future<void> _renovarToken() async {
    setState(() => _procesando = true);
    try {
      await PuntoRedAuthService.forzarNuevoToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Token generado exitosamente por 24 hrs'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al generar token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _procesando = true;
      _error = null;
    });

    try {
      // 1. Validar Saldo
      final saldo = await PayPalService.obtenerSaldoPayPal();
      if (!mounted) return;
      if (saldo == null)
        throw Exception('Error de conexión con PayPal. Intenta más tarde.');
      if (saldo < widget.producto.precio)
        throw Exception(
          'Saldo insuficiente en PayPal (\$${saldo.toStringAsFixed(2)}).',
        );

      // 2. Crear Orden y Capturar
      final orden = await PayPalService.crearOrden(
        monto: widget.producto.precio,
        descripcion: 'Recarga Punto Red: ${widget.producto.producto}',
      );
      if (!mounted) return;
      if (orden == null)
        throw Exception('No se pudo generar la orden en PayPal.');

      final aprobado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayPalCheckoutScreen(
            approvalUrl: orden['approvalUrl']!,
            orderId: orden['orderId']!,
          ),
        ),
      );
      if (!mounted) return;
      if (aprobado != true) throw Exception('Pago cancelado en PayPal.');

      final capturado = await PayPalService.capturarOrden(orden['orderId']!);
      if (!mounted) return;
      if (!capturado) throw Exception('No se pudo cobrar en PayPal.');

      // 3. Descontar saldo
      PayPalService.descontarSaldoLocal(widget.producto.precio);

      // 4. Mandar a Punto Red (Petición REAL con token de 24 hrs)
      final tx = await PuntoRedPagoService.sendTx(
        producto: widget.producto,
        identificador: _identificadorCtrl.text.trim(),
        usuarioId: widget.usuarioId,
        usuarioCorreo: widget.usuarioCorreo,
      );
      if (!mounted) return;

      // 5. Mostrar Ticket
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PuntoRedTicketScreen(
            tx: tx,
            servicio: widget.producto.servicio,
            producto: widget.producto.producto,
            telefono: _identificadorCtrl.text.trim(),
            saldoPayPal: (saldo - widget.producto.precio),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Confirmar pago',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key, color: _moradoOscuro),
            tooltip: 'Generar nuevo token (24h)',
            onPressed: _procesando ? null : _renovarToken,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _morado.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: _moradoOscuro,
                      size: 45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.producto.producto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.producto.servicio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _morado.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _morado.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total a pagar',
                        style: TextStyle(
                          fontSize: 13,
                          color: _moradoOscuro,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.producto.precioFormateado,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _moradoOscuro,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _esRecarga
                      ? 'Ingresa el número de teléfono'
                      : 'Ingresa el número de referencia',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identificadorCtrl,
                  keyboardType: _esRecarga
                      ? TextInputType.phone
                      : TextInputType.text,
                  inputFormatters: _esRecarga
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\-_]'),
                          ),
                          LengthLimitingTextInputFormatter(45),
                        ],
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: _esRecarga ? '10 dígitos' : 'Ej. 1234567890',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(
                      _esRecarga ? Icons.phone_rounded : Icons.receipt_long,
                      color: _moradoOscuro,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: _moradoOscuro,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return _esRecarga
                          ? 'El teléfono es obligatorio'
                          : 'La referencia es obligatoria';
                    if (_esRecarga && v.trim().length != 10)
                      return 'Deben ser exactamente 10 dígitos';
                    if (!_esRecarga && v.trim().length < 4)
                      return 'La referencia es demasiado corta';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moradoOscuro,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _procesando ? null : _pagar,
                    child: _procesando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'PAGAR AHORA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identificadorCtrl.dispose();
    super.dispose();
  }
}
