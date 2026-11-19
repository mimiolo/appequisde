import 'dart:math';
import '../db/db_helper.dart';
import '../helpers/mail_helper.dart';

class RecuperacionService {
  String _generarCodigo() {
    final r = Random();
    return (100000 + r.nextInt(900000)).toString();
  }

  Future<bool> solicitarCodigo(String correo) async {
    final db = await DBHelper.instance.database;
    final existe = await db.query('user_app',
        where: 'correo = ?',
        whereArgs: [correo.trim().toLowerCase()],
        limit: 1);
    if (existe.isEmpty) return false;

    final usuario = existe.first;
    final nombre = usuario['nombre'] as String? ?? 'usuario';
    final codigo = _generarCodigo();
    final expira = DateTime.now().add(const Duration(minutes: 5));

    await db.insert('recuperacion_otp', {
      'correo': correo.trim().toLowerCase(),
      'codigo': codigo,
      'expira': expira.toIso8601String(),
      'usado': 0,
    });

    await MailHelper.sendOtpEmail(
      destino: correo.trim().toLowerCase(),
      nombre: nombre,
      codigo: codigo,
      tipo: 'recuperacion',
    );
    return true;
  }

  Future<bool> verificarCodigo(String correo, String codigo) async {
    final db = await DBHelper.instance.database;
    final r = await db.query('recuperacion_otp',
        where: 'correo = ? AND codigo = ? AND usado = 0',
        whereArgs: [correo.trim().toLowerCase(), codigo.trim()],
        orderBy: 'id DESC',
        limit: 1);
    if (r.isEmpty) return false;
    final expira = DateTime.parse(r.first['expira'] as String);
    return !DateTime.now().isAfter(expira);
  }

  Future<bool> cambiarPassword(
      String correo, String codigo, String nuevaPass) async {
    final db = await DBHelper.instance.database;
    final ok = await verificarCodigo(correo, codigo);
    if (!ok) return false;

    await db.update('user_app', {'pass': nuevaPass},
        where: 'correo = ?', whereArgs: [correo.trim().toLowerCase()]);
    await db.update('recuperacion_otp', {'usado': 1},
        where: 'correo = ? AND codigo = ?',
        whereArgs: [correo.trim().toLowerCase(), codigo.trim()]);
    return true;
  }
}
