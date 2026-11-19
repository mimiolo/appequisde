import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorScreen extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final IconData icono;

  const ErrorScreen({
    super.key,
    this.titulo = '¡Ups! Algo salió mal',
    required this.mensaje,
    this.icono = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColores.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: AppColores.error.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Icon(icono, size: 70, color: AppColores.error),
                      ),
                      const SizedBox(height: 20),
                      Text(titulo,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColores.textPrimary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      Text(mensaje,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, color: AppColores.textSecondary)),
                      const SizedBox(height: 30),
                      SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColores.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('VOLVER',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void mostrar(BuildContext context,
      {String? titulo, required String mensaje, IconData? icono}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ErrorScreen(
                  titulo: titulo ?? '¡Ups! Algo salió mal',
                  mensaje: mensaje,
                  icono: icono ?? Icons.error_outline,
                )));
  }
}
