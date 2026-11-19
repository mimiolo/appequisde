import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PuntoRedLogoService {
  static const String _baseUrl = 'https://gestopago.portalventas.net';

  static const String _token = 'PEGA_AQUI_TU_TOKEN_COMPLETO';
  static const String _apiKey = 'PEGA_AQUI_TU_API_KEY_COMPLETA';

  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> obtenerLogo(String idServicio) async {
    if (_cache.containsKey(idServicio)) {
      return _cache[idServicio];
    }

    final url = Uri.parse(
      '$_baseUrl/sistema/images/gestopago/servicios/$idServicio.png',
    );

    try {
      final resp = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $_token',
              'X-API-Key': _apiKey,
              'Accept': 'image/png',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('LOGO ID: $idServicio');
      debugPrint('LOGO STATUS: ${resp.statusCode}');
      debugPrint('LOGO CONTENT-TYPE: ${resp.headers['content-type']}');

      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
        debugPrint('ERROR LOGO: ${resp.statusCode}');
        return null;
      }

      _cache[idServicio] = resp.bodyBytes;
      return resp.bodyBytes;
    } catch (e) {
      debugPrint('ERROR DESCARGANDO LOGO $idServicio: $e');
      return null;
    }
  }

  static void limpiarCache() {
    _cache.clear();
  }
}
