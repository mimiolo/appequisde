import 'dart:convert';

import 'package:http/http.dart' as http;

class PayPalService {
  static const String _clientId =
      'Aa6Zc6bLu43PEEvMTAQZm4r_5YBFvOuIwi0Dw6-QQEvyRfri05nn-zRO0MiUXXAcDO6wRjfCwGC7ZEz4';
  static const String _secret =
      'EArU8HxBllA2JA__9CoIrGqeehrqpqFuQhPlsMY7DouVZNWZVsbbx2P5-3bsLJ7A90OhiAjkUBvP1C2w';
  static const String _api = 'https://api-m.sandbox.paypal.com';

  static const String returnUrl = 'https://example.com/paypal/return';
  static const String cancelUrl = 'https://example.com/paypal/cancel';

  // ⚡ Caché local para que el saldo se actualice visualmente al instante
  static double? _saldoCache;

  static Future<String?> _getToken() async {
    try {
      final auth = base64Encode(utf8.encode('$_clientId:$_secret'));
      final res = await http.post(
        Uri.parse('$_api/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      return data['access_token'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<double?> obtenerSaldoPayPal({
    bool forzarRecarga = false,
  }) async {
    // Si ya tenemos un saldo en caché y NO forzamos recarga, lo devolvemos de inmediato
    if (!forzarRecarga && _saldoCache != null) {
      return _saldoCache;
    }

    final token = await _getToken();
    if (token == null) return _saldoCache;

    try {
      final res = await http.get(
        Uri.parse('$_api/v1/reporting/balances?currency_code=MXN'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final balances = data['balances'] as List<dynamic>?;

        if (balances != null && balances.isNotEmpty) {
          for (var balance in balances) {
            // ⚡ Busca 'currency' o 'currency_code'
            if (balance['currency'] == 'MXN' ||
                balance['available_balance']['currency_code'] == 'MXN') {
              final available = balance['available_balance']['value'];
              _saldoCache = double.tryParse(available.toString()) ?? 0.0;
              return _saldoCache;
            }
          }
        }
      }
      return _saldoCache ?? 0.0;
    } catch (e) {
      return _saldoCache;
    }
  }

  // ⚡ Descuenta el monto de la caché local inmediatamente
  static void descontarSaldoLocal(double monto) {
    if (_saldoCache != null) {
      _saldoCache = _saldoCache! - monto;
      if (_saldoCache! < 0) _saldoCache = 0;
    }
  }

  static Future<Map<String, String>?> crearOrden({
    required double monto,
    required String descripcion,
  }) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse('$_api/v2/checkout/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {
                'currency_code': 'MXN',
                'value': monto.toStringAsFixed(2),
              },
              'description': descripcion,
            },
          ],
          'application_context': {
            'brand_name': 'Seguridad App',
            'landing_page': 'LOGIN',
            'user_action': 'PAY_NOW',
            'return_url': returnUrl,
            'cancel_url': cancelUrl,
          },
        }),
      );
      if (res.statusCode != 201 && res.statusCode != 200) return null;
      final data = json.decode(res.body);
      final orderId = data['id'] as String?;
      final links = data['links'] as List<dynamic>?;
      String? approvalUrl;
      if (links != null) {
        for (var link in links) {
          if (link['rel'] == 'approve') {
            approvalUrl = link['href'] as String?;
            break;
          }
        }
      }
      if (orderId == null || approvalUrl == null) return null;
      return {'orderId': orderId, 'approvalUrl': approvalUrl};
    } catch (e) {
      return null;
    }
  }

  static Future<bool> capturarOrden(String orderId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_api/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200 && res.statusCode != 201) return false;
      final data = json.decode(res.body);
      return data['status'] == 'COMPLETED';
    } catch (e) {
      return false;
    }
  }
}
