// Port en Dart del Java AesEncryption.
// Algoritmo: AES/CBC/PKCS5 (= PKCS7 en Dart) con IV y KEY en Base64.
import 'package:encrypt/encrypt.dart' as enc;

class AesHelper {
  static String cipher({
    required String mode,
    required String input,
    required String ivB64,
    required String keyB64,
  }) {
    final key = enc.Key.fromBase64(keyB64);
    final iv = enc.IV.fromBase64(ivB64);

    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    );

    final m = mode.toUpperCase();
    if (m == 'ENCRYPT') {
      return encrypter.encrypt(input, iv: iv).base64;
    }
    if (m == 'DECRYPT') {
      return encrypter.decrypt(enc.Encrypted.fromBase64(input), iv: iv);
    }
    throw ArgumentError('mode inválido: $mode (usa ENCRYPT o DECRYPT)');
  }

  static String encrypt(
    String input, {
    required String iv,
    required String key,
  }) => cipher(mode: 'ENCRYPT', input: input, ivB64: iv, keyB64: key);

  static String decrypt(
    String input, {
    required String iv,
    required String key,
  }) => cipher(mode: 'DECRYPT', input: input, ivB64: iv, keyB64: key);
}
