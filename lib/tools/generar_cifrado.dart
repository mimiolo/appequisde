import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;

void main() {
  final payload = jsonEncode({
    'idServicio': '1487',
    'idProducto': '10034',
    'telefono': '6634965464', // ⚡ Teléfono / Referencia
    'horaLocal': DateTime.now().millisecondsSinceEpoch.toString(),
    'montoPago': '30.00', // ⚡ Monto pago
    'idDistribuidor': '83', // ⚡ Distribuidor
  });

  const secretKey = 'HPo7OLqB4Fkk4E2yGOtwqw8H5fHR9kNx67OR4g4UdIA=';
  const iv = 'p5ldmBPdd/9pjC0bDC/nSg==';

  final key = enc.Key.fromBase64(secretKey);
  final ivObj = enc.IV.fromBase64(iv);
  final encrypter = enc.Encrypter(
    enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
  );

  final cifrado = encrypter.encrypt(payload, iv: ivObj).base64;

  print('CIFRADO NUEVO:');
  print(cifrado);
}
