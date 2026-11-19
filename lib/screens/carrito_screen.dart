// Carrito de compras.
// Al confirmar → va a PANTALLA DE PAGO (PayPal, tarjeta, etc.)
// Solo después de pagar se crea el pedido y se envía el correo.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../theme/app_theme.dart';
import 'pago_screen.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final Usuario? usuario;
  const CarritoScreen({super.key, required this.carrito, this.usuario});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> _carrito;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carrito = widget.carrito.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  double get _total => _carrito.fold(
    0.0,
    (s, i) => s + ((i['precio'] as num).toDouble() * (i['cantidad'] as int)),
  );

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_cart', json.encode(_carrito));
  }

  // ============ IR A PAGAR ============
  Future<void> _irAPagar() async {
    if (_carrito.isEmpty || _enviando) return;

    if (widget.usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para comprar'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final total = _total;

    // ⚡ Abre la pantalla de pago
    final pagado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PagoScreen(usuario: widget.usuario!, items: _carrito, total: total),
      ),
    );

    // Si pagó, vacío el carrito
    if (pagado == true) {
      setState(() => _carrito.clear());
      await _guardar();
    }
  }

  void _cambiarCantidad(int index, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      setState(() => _carrito.removeAt(index));
    } else {
      setState(() => _carrito[index]['cantidad'] = nuevaCantidad);
    }
    await _guardar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          if (_carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text('¿Quitar todos los productos?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Vaciar',
                          style: TextStyle(color: AppColores.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  setState(() => _carrito.clear());
                  await _guardar();
                }
              },
            ),
        ],
      ),
      body: _carrito.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tu carrito está vacío',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _carrito.length,
                    itemBuilder: (_, i) {
                      final item = _carrito[i];
                      final subtotal =
                          (item['precio'] as num).toDouble() *
                          (item['cantidad'] as int);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: (item['imagen_url'] ?? '').isEmpty
                                      ? Container(
                                          color: AppColores.background,
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Image.network(
                                          item['imagen_url'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: AppColores.background,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['titulo'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${(item['precio'] as num).toStringAsFixed(2)} c/u',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColores.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColores.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: AppColores.success,
                                    ),
                                    onPressed: () => _cambiarCantidad(
                                      i,
                                      (item['cantidad'] as int) + 1,
                                    ),
                                  ),
                                  Text(
                                    '${item['cantidad']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: AppColores.warning,
                                    ),
                                    onPressed: () => _cambiarCantidad(
                                      i,
                                      (item['cantidad'] as int) - 1,
                                    ),
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
                  child: Column(
                    children: [
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
                            '\$${_total.toStringAsFixed(2)} MXN',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColores.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColores.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _enviando ? null : _irAPagar,
                          icon: const Icon(Icons.payment),
                          label: const Text(
                            'CONTINUAR AL PAGO',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💰 Elige tu método de pago en el siguiente paso',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColores.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
