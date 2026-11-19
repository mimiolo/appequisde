// Servicio de ubicación GPS.
// Usa geolocator para lat/lng, y Nominatim (OpenStreetMap) para dirección.
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UbicacionService {
  static Future<Position?> obtenerUbicacion() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        print('⚠️ El GPS está apagado');
        return null;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          print('⚠️ Permiso denegado');
          return null;
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        print('⚠️ Permiso denegado permanentemente');
        return null;
      }

      print('📍 Solicitando ubicación...');
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      print('📍 Ubicación obtenida: ${pos.latitude}, ${pos.longitude}');
      return pos;
    } catch (e) {
      print('⚠️ Error GPS: $e');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
      } catch (_) {}
      return null;
    }
  }

  // Convierte lat/lng en dirección usando Nominatim (OpenStreetMap)
  static Future<String?> obtenerDireccion(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final resp = await http
          .get(url, headers: {'User-Agent': 'SeguridadApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        print('⚠️ Nominatim error: ${resp.statusCode}');
        return null;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final dir = data['display_name'] as String?;
      if (dir != null && dir.isNotEmpty) {
        print('📍 Dirección: $dir');
        return dir;
      }
      return null;
    } catch (e) {
      print('⚠️ Error dirección: $e');
      return null;
    }
  }
}
