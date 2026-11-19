import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  static final _auth = LocalAuthentication();

  static Future<bool> disponible() async {
    if (kIsWeb) return false; // ⚡ Evitar crash en Web
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      print('⚠️ Error al verificar biometría: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> obtenerTipos() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> autenticar({
    String razon = 'Confirma tu identidad para continuar',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: razon,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static String nombreTipo(List<BiometricType> tipos) {
    if (tipos.contains(BiometricType.face)) return 'Reconocimiento facial';
    if (tipos.contains(BiometricType.fingerprint)) return 'Huella digital';
    if (tipos.contains(BiometricType.iris)) return 'Iris';
    if (tipos.contains(BiometricType.strong)) return 'Biometría fuerte';
    return 'Biometría';
  }
}
