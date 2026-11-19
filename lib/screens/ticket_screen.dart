// Pantalla que muestra el ticket DESPUÉS de la compra.
// Tiene el mismo diseño que el correo que se envía.
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../theme/app_theme.dart';

class TicketScreen extends StatelessWidget {
  final Usuario usuario;
  final String folio;
  final List<Map<String, dynamic>> items;
  final double total;
  final DateTime fecha;

  const TicketScreen({
    super.key,
    required this.usuario,
    required this.folio,
    required this.items,
    required this.total,
    required this.fecha,
  });

  String get _fechaStr => '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.background,
      appBar: AppBar(
        title: const Text('Ticket de Compra'),
        backgroundColor: AppColores.success,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              // Header con gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppColores.primaryGradient,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 64),
                    SizedBox(height: 10),
                    Text('¡Compra exitosa!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Tu ticket fue enviado por correo',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),

              // Info general
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _fila('Cliente', usuario.nombreCompleto),
                    _fila('Correo', usuario.correo),
                    _fila('Folio', folio, resaltado: true),
                    _fila('Fecha', _fechaStr),
                  ],
                ),
              ),

              // Tabla de productos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('PRODUCTOS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColores.textSecondary)),
                    const SizedBox(height: 12),
                    ...items.map((it) {
                      final precio = (it['precio'] as num).toDouble();
                      final cant = it['cantidad'] as int;
                      final sub = precio * cant;
                      final img = (it['imagen_url'] ?? '') as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            if (img.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(img,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported,
                                        size: 30)),
                              )
                            else
                              const Icon(Icons.shopping_bag_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it['titulo'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text('$cant x \$${precio.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColores.textSecondary)),
                                ],
                              ),
                            ),
                            Text('\$${sub.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColores.primary)),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                  ],
                ),
              ),

              // Total
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${total.toStringAsFixed(2)} MXN',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColores.primary)),
                  ],
                ),
              ),

              // Botón volver
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColores.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.store),
                    label: const Text('VOLVER A LA TIENDA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(String label, String valor, {bool resaltado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColores.textSecondary)),
          Flexible(
            child: Text(valor,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: resaltado ? FontWeight.bold : FontWeight.normal,
                  color:
                      resaltado ? AppColores.primary : AppColores.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}
