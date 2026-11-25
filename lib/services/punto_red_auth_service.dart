import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⚡ IMPORTANTE

import '../helpers/aes_helper.dart';

class PuntoRedAuthService {
  static const String server = 'https://gestopago.portalventas.net';
  static const String authEndpoint = 'sistema/app/jwt-gp/authenticate/';

  static const String idDistribuidor = '83';
  static const String codigoDispositivo = 'GPS83-TPV-17';
  static const String password = '12345678';
  static const String apiKey = 'YSX1HpAFum4TpCecyFBxs4eIjAlbhKqK6fpcSQp8';

  static const String secretKey =
      'HPo7OLqB4Fkk4E2yGOtwqw8H5fHR9kNx67OR4g4UdlA=';
  static const String iv = 'p5ldmBPdd/9pjC0bDC/nSg==';

  static const String _prefJwt = 'puntored_jwt';
  static const String _prefJwtFecha = 'puntored_jwt_fecha';

  static String cifrarPayload(Map<String, dynamic> payload) {
    return AesHelper.encrypt(jsonEncode(payload), iv: iv, key: secretKey);
  }

  static Future<String> obtenerJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_prefJwt);
    final fecha = prefs.getString(_prefJwtFecha);
    final hoy = DateTime.now().toIso8601String().substring(0, 10);

    if (guardado != null && fecha == hoy) {
      return guardado;
    }

    return await forzarNuevoToken();
  }

  static Future<String> forzarNuevoToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefJwt);
    await prefs.remove(_prefJwtFecha);

    // ⚡ SI ES WEB, SALTAMOS LA PETICIÓN POR EL BLOQUEO DE CORS
    if (kIsWeb) {
      print(
        '🌐 Modo Web detectado: Generando Token local por bloqueo de CORS...',
      );
      const dummyToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy.token.para.web';
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString(_prefJwt, dummyToken);
      await prefs.setString(_prefJwtFecha, hoy);
      return dummyToken;
    }

    // FLUJO NORMAL PARA MÓVIL
    final url = Uri.parse(
      '$server/$authEndpoint'
      '?idDistribuidor=$idDistribuidor'
      '&codigoDispositivo=$codigoDispositivo'
      '&password=$password',
    );

    final resp = await http.post(
      url,
      headers: {
        'X-API-Key': apiKey,
        'Accept': 'application/xml, text/xml, application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Error HTTP ${resp.statusCode} al generar token');
    }

    final jwt = _extraerJwt(resp.body);
    if (jwt == null) {
      throw Exception('No se encontró JWT en: ${resp.body}');
    }

    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefJwt, jwt);
    await prefs.setString(_prefJwtFecha, hoy);

    return jwt;
  }

  static String? _extraerJwt(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map) {
        for (final k in ['token', 'jwt', 'access_token', 'id_token', 'TOKEN']) {
          final v = j[k];
          if (v is String && v.isNotEmpty) return v;
        }
      }
    } catch (_) {}

    try {
      final doc = XmlDocument.parse(body);
      for (final tag in ['TOKEN', 'JWT', 'ID_TOKEN', 'ACCESS_TOKEN']) {
        final el = doc.findAllElements(tag);
        if (el.isNotEmpty && el.first.innerText.trim().isNotEmpty) {
          return el.first.innerText.trim();
        }
      }
    } catch (_) {}

    final limpio = body.trim();
    if (limpio.split('.').length == 3 && limpio.length > 50) return limpio;

    return null;
  }

  static Future<Map<String, String>> headers() async {
    final jwt = await obtenerJwt();
    return {'Authorization': 'Bearer $jwt', 'X-API-Key': apiKey};
  }

  static Future<void> limpiarJwt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefJwt);
    await prefs.remove(_prefJwtFecha);
  }
}
