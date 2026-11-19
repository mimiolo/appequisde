// Pantalla de verificación OTP después del login correcto.
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/otp_service.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'user_screen.dart';

class VerificarOtpScreen extends StatefulWidget {
  final Usuario usuario;
  const VerificarOtpScreen({super.key, required this.usuario});
  @override
  State<VerificarOtpScreen> createState() => _VerificarOtpScreenState();
}

class _VerificarOtpScreenState extends State<VerificarOtpScreen> {
  final _codigoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _cargando = false;
  bool _reenviando = false;

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final ok = await OtpService().validar(
      widget.usuario.id!,
      _codigoCtrl.text.trim(),
      'login',
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código incorrecto o expirado'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await LogService().registrar(
      widget.usuario.id,
      'Login 2FA',
      '${widget.usuario.correo} verificó OTP',
    );

    if (!mounted) return;
    if (widget.usuario.roleId == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminScreen(usuario: widget.usuario)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserScreen(usuario: widget.usuario)),
      );
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    try {
      await OtpService().enviarOtp(
        usuarioId: widget.usuario.id!,
        correo: widget.usuario.correo,
        nombre: widget.usuario.nombre,
        tipo: 'login',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado ✅'),
          backgroundColor: AppColores.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _reenviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación 2FA'),
        backgroundColor: AppColores.pastelLavenderDark,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColores.pastelLavender, AppColores.pastelPink],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          size: 70,
                          color: AppColores.pastelLavenderDark,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Verificación en 2 pasos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enviamos un código a ${widget.usuario.correo}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColores.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Revisa tu bandeja o SPAM',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _codigoCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: '000000',
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.length != 6)
                              return 'Ingresa 6 dígitos';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColores.pastelLavenderDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _cargando ? null : _verificar,
                            child: _cargando
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'VERIFICAR CÓDIGO',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _reenviando ? null : _reenviar,
                          child: Text(
                            _reenviando
                                ? 'Reenviando...'
                                : '¿No llegó? Reenviar código',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }
}
