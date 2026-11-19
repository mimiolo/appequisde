import 'package:flutter/material.dart';
import '../helpers/mail_helper.dart';
import '../db/db_helper.dart';
import '../theme/app_theme.dart';

class RecuperarUsuarioScreen extends StatefulWidget {
  const RecuperarUsuarioScreen({super.key});
  @override
  State<RecuperarUsuarioScreen> createState() => _S();
}

class _S extends State<RecuperarUsuarioScreen> {
  final _correo = TextEditingController();
  bool _cargando = false;

  Future<void> _recuperar() async {
    if (_correo.text.trim().isEmpty) return;
    setState(() => _cargando = true);
    final db = await DBHelper.instance.database;
    final r = await db.query('user_app',
        where: 'correo = ?',
        whereArgs: [_correo.text.trim().toLowerCase()],
        limit: 1);
    if (r.isEmpty) {
      setState(() => _cargando = false);
      _snack('No existe una cuenta con ese correo', AppColores.error);
      return;
    }
    final u = r.first;
    try {
      await MailHelper.sendEmail(
        u['correo'] as String,
        'Recuperación de usuario',
        'Tu nombre de usuario es: ${u['nombre']} ${u['apellido_paterno'] ?? ""}',
        htmlContent:
            '''<html><body style="font-family:Arial;background:#FDFBFF;padding:20px;">
          <div style="max-width:500px;margin:auto;background:#fff;border-radius:20px;overflow:hidden;">
            <div style="background:linear-gradient(135deg,#9F94E3,#E8B4D0);padding:30px;text-align:center;color:white;">
              <div style="font-size:48px;">👤</div>
              <h1 style="margin:10px 0;">Recuperación de usuario</h1>
            </div>
            <div style="padding:30px;text-align:center;">
              <p>Tu nombre de usuario es:</p>
              <h2 style="color:#8B7FD9;">${u['nombre']} ${u['apellido_paterno'] ?? ""} ${u['apellido_materno'] ?? ""}</h2>
              <p style="font-size:12px;color:#8B88A0;">Ingresa con ese nombre y tu contraseña.</p>
            </div>
          </div></body></html>''',
      );
      setState(() => _cargando = false);
      _snack('Revisa tu correo ✅', AppColores.success);
    } catch (e) {
      setState(() => _cargando = false);
      _snack('Error: $e', AppColores.error);
    }
  }

  void _snack(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColores.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_search,
                        size: 70, color: AppColores.primary),
                    const SizedBox(height: 16),
                    const Text('Recuperar usuario',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Te enviaremos tu nombre de usuario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AppColores.textSecondary)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo registrado',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _recuperar,
                        child: _cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('ENVIAR USUARIO'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
