// Pantalla de ubicación con:
// 1. Ubicación actual (coords + dirección)
// 2. Rastreo en tiempo real (stream del GPS)
// 3. Recomendaciones cercanas
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/location_helper.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_theme.dart';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});
  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  Position? _posicionActual;
  String? _direccionActual;
  String? _error;
  bool _cargando = false;
  bool _rastreando = false;

  // Stream para rastreo en tiempo real
  StreamSubscription<Position>? _posStream;
  List<Position> _historialPosiciones = [];

  // Lugares cercanos (simulados con distancia calculada)
  final List<Map<String, dynamic>> _lugaresCercanos = [
    {
      'nombre': 'ITP - Instituto Tecnológico',
      'lat': 32.522499,
      'lng': -117.020103,
      'icono': Icons.school,
    },
    {
      'nombre': 'Hospital General',
      'lat': 32.525800,
      'lng': -117.018000,
      'icono': Icons.local_hospital,
    },
    {
      'nombre': 'Plaza Comercial',
      'lat': 32.529000,
      'lng': -117.023500,
      'icono': Icons.shopping_bag,
    },
    {
      'nombre': 'Parque Municipal',
      'lat': 32.520000,
      'lng': -117.025000,
      'icono': Icons.park,
    },
  ];

  @override
  void initState() {
    super.initState();
    _obtenerMiUbicacion();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    super.dispose();
  }

  // ============ UBICACIÓN ACTUAL ============
  Future<void> _obtenerMiUbicacion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final pos = await UbicacionService.obtenerUbicacion();

    if (pos == null) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error =
            'No se pudo obtener la ubicación.\n\n'
            'Verifica:\n'
            '• GPS encendido\n'
            '• Permiso de ubicación concedido\n'
            '• Emulador con ubicación asignada';
      });
      return;
    }

    final dir = await UbicacionService.obtenerDireccion(
      pos.latitude,
      pos.longitude,
    );

    if (!mounted) return;
    setState(() {
      _posicionActual = pos;
      _direccionActual = dir ?? 'Dirección desconocida';
      _cargando = false;
    });
  }

  // ============ RASTREO EN TIEMPO REAL ============
  void _toggleRastreo() {
    if (_rastreando) {
      // Detener
      _posStream?.cancel();
      _posStream = null;
      setState(() => _rastreando = false);
      return;
    }

    // Iniciar
    setState(() {
      _rastreando = true;
      _historialPosiciones.clear();
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Actualiza cada 5 metros de movimiento
    );

    _posStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (pos) {
            if (!mounted) return;
            setState(() {
              _posicionActual = pos;
              _historialPosiciones.add(pos);
              if (_historialPosiciones.length > 10) {
                _historialPosiciones.removeAt(0);
              }
            });
            // Actualizar dirección cada 5 puntos para no saturar
            if (_historialPosiciones.length % 5 == 0) {
              UbicacionService.obtenerDireccion(
                pos.latitude,
                pos.longitude,
              ).then((dir) {
                if (dir != null && mounted) {
                  setState(() => _direccionActual = dir);
                }
              });
            }
          },
          onError: (e) {
            print('⚠️ Error stream: $e');
            if (mounted) setState(() => _rastreando = false);
          },
        );
  }

  // ============ RECOMENDACIONES CERCANAS ============
  double _distanciaA(double lat, double lng) {
    if (_posicionActual == null) return 0;
    return Geolocator.distanceBetween(
      _posicionActual!.latitude,
      _posicionActual!.longitude,
      lat,
      lng,
    );
  }

  String _formatoDistancia(double metros) {
    if (metros < 1000) return '${metros.toStringAsFixed(0)} m';
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocalización'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ HEADER ============
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColores.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.my_location, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Mi ubicación actual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _rastreando
                        ? '🔴 Rastreo en vivo activo'
                        : 'Presiona para obtener coordenadas GPS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ============ BOTONES ============
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColores.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _cargando ? null : _obtenerMiUbicacion,
                      icon: _cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.gps_fixed, size: 20),
                      label: const Text(
                        'MI UBICACIÓN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rastreando
                            ? Colors.red.shade400
                            : AppColores.pastelPeachDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleRastreo,
                      icon: Icon(
                        _rastreando ? Icons.stop_circle : Icons.timeline,
                        size: 20,
                      ),
                      label: Text(
                        _rastreando ? 'DETENER' : 'RASTREAR',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ============ ERROR ============
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColores.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColores.error.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColores.error,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            // ============ RESULTADO GPS ============
            if (_posicionActual != null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _rastreando
                                ? Icons.radio_button_checked
                                : Icons.check_circle,
                            color: _rastreando
                                ? Colors.red.shade400
                                : AppColores.pastelMintDark,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _rastreando
                                ? 'Rastreando en tiempo real'
                                : '¡Ubicación obtenida!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _rastreando
                                  ? Colors.red.shade400
                                  : AppColores.pastelMintDark,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _filaInfo(
                        'Latitud',
                        _posicionActual!.latitude.toStringAsFixed(6),
                      ),
                      _filaInfo(
                        'Longitud',
                        _posicionActual!.longitude.toStringAsFixed(6),
                      ),
                      _filaInfo(
                        'Precisión',
                        '${_posicionActual!.accuracy.toStringAsFixed(1)} m',
                      ),
                      if (_direccionActual != null)
                        _filaInfo('Dirección', _direccionActual!),
                      if (_rastreando)
                        _filaInfo(
                          'Puntos rastreados',
                          '${_historialPosiciones.length}',
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColores.pastelBlueDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => LocationHelper.abrirMapa(
                            lat: _posicionActual!.latitude,
                            lng: _posicionActual!.longitude,
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text(
                            'VER EN GOOGLE MAPS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ============ RECOMENDACIONES CERCANAS ============
              Row(
                children: [
                  Icon(Icons.near_me, color: AppColores.primaryDark),
                  const SizedBox(width: 8),
                  const Text(
                    'Recomendaciones cercanas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Lugares de interés ordenados por distancia',
                style: TextStyle(fontSize: 12, color: AppColores.textSecondary),
              ),
              const SizedBox(height: 12),

              ..._lugaresCercanos.map((lugar) {
                final dist = _distanciaA(lugar['lat'], lugar['lng']);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColores.pastelLavender.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        lugar['icono'],
                        color: AppColores.primaryDark,
                      ),
                    ),
                    title: Text(
                      lugar['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _formatoDistancia(dist),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColores.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.directions,
                        color: AppColores.primaryDark,
                      ),
                      onPressed: () => LocationHelper.abrirMapa(
                        lat: lugar['lat'],
                        lng: lugar['lng'],
                      ),
                      tooltip: 'Cómo llegar',
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filaInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColores.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
