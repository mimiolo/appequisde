// Servicio de códigos OTP de 6 dígitos para 2FA en login.
import 'dart:math';

import '../db/db_helper.dart';
import '../helpers/mail_helper.dart';

class OtpService {
  String generarCodigo() {
    final rnd = Random();
    return List.generate(6, (_) => rnd.nextInt(10)).join();
  }

  Future<void> guardar(int usuarioId, String codigo, String tipo) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'otp_codigos',
      {'usado': 1},
      where: 'usuario_id = ? AND tipo = ? AND usado = 0',
      whereArgs: [usuarioId, tipo],
    );

    final expira = DateTime.now().add(const Duration(minutes: 10));
    await db.insert('otp_codigos', {
      'usuario_id': usuarioId,
      'codigo': codigo,
      'tipo': tipo,
      'expira': expira.toIso8601String(),
      'usado': 0,
    });
  }

  // Genera + guarda + envía por correo
  Future<void> enviarOtp({
    required int usuarioId,
    required String correo,
    required String nombre,
    required String tipo,
  }) async {
    final codigo = generarCodigo();
    await guardar(usuarioId, codigo, tipo);
    await MailHelper.sendOtpEmail(
      destino: correo,
      nombre: nombre,
      codigo: codigo,
      tipo: tipo,
    );
  }

  Future<bool> validar(int usuarioId, String codigo, String tipo) async {
    final db = await DBHelper.instance.database;
    final r = await db.query(
      'otp_codigos',
      where: 'usuario_id = ? AND codigo = ? AND tipo = ? AND usado = 0',
      whereArgs: [usuarioId, codigo, tipo],
      limit: 1,
    );
    if (r.isEmpty) return false;

    final expira = DateTime.parse(r.first['expira'] as String);
    if (DateTime.now().isAfter(expira)) return false;

    await db.update(
      'otp_codigos',
      {'usado': 1},
      where: 'id = ?',
      whereArgs: [r.first['id']],
    );
    return true;
  }
}
