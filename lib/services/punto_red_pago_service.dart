import 'dart:math';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⚡ IMPORTANTE

import '../models/punto_red_producto.dart';
import '../models/punto_red_transaccion.dart';
import 'punto_red_auth_service.dart';
import 'punto_red_transaccion_service.dart';

class PuntoRedPagoService {
  static const String _url =
      'https://gestopago.portalventas.net/sistema/service/sendTx.do';

  // ⚡ TU URL DE RAILWAY
  static const String railwayUrl =
      'https://backend-puntored-production.up.railway.app';

  static Future<PuntoRedTransaccion> sendTx({
    required PuntoRedProducto producto,
    required String identificador,
    int? usuarioId,
    String? usuarioCorreo,
  }) async {
    try {
      return await _ejecutar(
        producto: producto,
        identificador: identificador,
        usuarioId: usuarioId,
        usuarioCorreo: usuarioCorreo,
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('token') || msg.contains('401') || msg.contains('403')) {
        await PuntoRedAuthService.limpiarJwt();
        return await _ejecutar(
          producto: producto,
          identificador: identificador,
          usuarioId: usuarioId,
          usuarioCorreo: usuarioCorreo,
        );
      }
      rethrow;
    }
  }

  static Future<PuntoRedTransaccion> _ejecutar({
    required PuntoRedProducto producto,
    required String identificador,
    int? usuarioId,
    String? usuarioCorreo,
  }) async {
    final horaLocal = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final randomStr = List.generate(
      6,
      (_) => String.fromCharCode(97 + Random().nextInt(26)),
    ).join();
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

    // ⚡ 1. Armamos el Payload Dinámico Original
    final Map<String, dynamic> payload = {
      'idProducto':
          int.tryParse(producto.idProducto) ??
          205, // Si falla, usa el de prueba
      'idServicio': int.tryParse(producto.idServicio) ?? 76,
      'telefono': identificador,
      'horaLocal': horaLocal,
      'referencia': identificador,
      'montoPago': producto.precio,
      'upc': 'UPC_$uniqueId',
      'unidad': '083',
    };

    final headers = await PuntoRedAuthService.headers();
    http.Response resp;

    // ⚡ 2. ¿Es Web o Móvil?
    if (kIsWeb) {
      // EN WEB: Mandamos el JSON a Railway para que él lo cifre y lo envíe
      final token = headers['Authorization']?.replaceAll('Bearer ', '') ?? '';

      resp = await http.post(
        Uri.parse('$railwayUrl/api/payment/sendTx'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payload': payload, 'token': token}),
      );
    } else {
      // EN MÓVIL: Hacemos tu flujo original (cifrado local y petición directa)
      final signed = PuntoRedAuthService.cifrarPayload(payload);
      final bodyData = {'random': randomStr, 'signed': signed};

      resp = await http.post(
        Uri.parse(_url),
        headers: {
          ...headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyData,
      );
    }

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }

    final mapa = parsearXml(resp.body);
    var tx = PuntoRedTransaccion.fromMap(mapa);

    if (!tx.exitosa) {
      throw Exception(tx.mensajeAmigable);
    }

    // Ajustamos el monto visual para el ticket
    tx = PuntoRedTransaccion(
      idTx: tx.idTx,
      numAutorizacion: tx.numAutorizacion,
      saldo: tx.saldo,
      comision: tx.comision,
      monto: producto.precio,
      fecha: tx.fecha,
      mensaje: tx.mensaje,
      codigoMensaje: tx.codigoMensaje,
      pin: tx.pin,
      legend: tx.legend,
      raw: tx.raw,
    );

    await PuntoRedTransaccionService.guardar(
      tx: tx,
      idServicio: producto.idServicio,
      idProducto: producto.idProducto,
      servicio: producto.servicio,
      producto: producto.producto,
      telefono: identificador,
      usuarioId: usuarioId,
      usuarioCorreo: usuarioCorreo,
    );

    return tx;
  }

  static Map<String, String> parsearXml(String xml) {
    final doc = XmlDocument.parse(xml);
    final raiz = doc.findAllElements('RESPONSE').isNotEmpty
        ? doc.findAllElements('RESPONSE').first
        : doc.rootElement;
    final out = <String, String>{};

    for (final el in raiz.childElements) {
      if (el.name.local != 'MENSAJE') out[el.name.local] = el.innerText.trim();
    }
    final mensajeNode = raiz.findElements('MENSAJE').isNotEmpty
        ? raiz.findElements('MENSAJE').first
        : null;
    if (mensajeNode != null) {
      for (final el in mensajeNode.childElements) {
        out[el.name.local] = el.innerText.trim();
      }
    }
    return out;
  }
}
