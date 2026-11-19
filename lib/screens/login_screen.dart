import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/biometric_helper.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../services/otp_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'user_screen.dart';
import 'register_screen.dart';
import 'recuperar_password_screen.dart';
import 'verificar_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  bool _verPass = false;
  bool _cargando = false;

  bool _biometriaDisponible = false;
  bool _biometriaActivada = false;
  String _nombreBiometria = 'Biometría';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final disp = await BiometricHelper.disponible();
    final tipos = await BiometricHelper.obtenerTipos();

    final prefs = await SharedPreferences.getInstance();
    final biometriaActiva = prefs.getBool('biometriaActivada') ?? false;
    final ultimoCorreo = prefs.getString('ultimoCorreo') ?? '';

    if (!mounted) return;
    setState(() {
      _biometriaDisponible = disp;
      _biometriaActivada = biometriaActiva && disp;
      _nombreBiometria = BiometricHelper.nombreTipo(tipos);
      if (ultimoCorreo.isNotEmpty) _correo.text = ultimoCorreo;
    });

    if (_biometriaActivada && ultimoCorreo.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _loginConBiometria();
    }
  }

  // ⚡ Verifica si es el admin de prueba (no requiere OTP)
  bool _esAdminDePrueba(String correo) {
    final c = correo.trim().toLowerCase();
    return c.endsWith('@test.com') || c == 'admin@test.com';
  }

  // LOGIN NORMAL
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final user = await AuthService().login(_correo.text, _pass.text);
    if (!mounted) return;

    if (user == null) {
      setState(() => _cargando = false);
      _snack('Correo o contraseña incorrectos', Colors.red.shade300);
      return;
    }

    // ⚡ Si es admin de prueba (@test.com), OMITO el OTP y entro directo
    if (_esAdminDePrueba(user.correo)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ultimoCorreo', user.correo);
      await prefs.setString('ultimoPass', _pass.text);

      await LogService().registrar(
        user.id,
        'Login',
        '${user.correo} inició sesión (sin 2FA)',
      );

      if (!mounted) return;
      setState(() => _cargando = false);

      _snack('Bienvenido (modo prueba)', AppColores.success);
      _irA(user);
      return;
    }

    // ⚡ Para correos reales, SÍ envía OTP
    try {
      await OtpService().enviarOtp(
        usuarioId: user.id!,
        correo: user.correo,
        nombre: user.nombre,
        tipo: 'login',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ultimoCorreo', user.correo);
      await prefs.setString('ultimoPass', _pass.text);

      await LogService().registrar(
        user.id,
        'Login',
        '${user.correo} inició sesión (2FA enviado)',
      );

      if (!mounted) return;
      setState(() => _cargando = false);

      _snack('Código enviado a ${user.correo}', AppColores.success);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerificarOtpScreen(usuario: user)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _snack('Error al enviar código: $e', Colors.red);
    }
  }

  // LOGIN BIOMÉTRICO → omite OTP siempre
  Future<void> _loginConBiometria() async {
    final ok = await BiometricHelper.autenticar(
      razon: 'Autentícate para iniciar sesión',
    );

    if (!ok) {
      if (!mounted) return;
      _snack('Autenticación cancelada', Colors.orange.shade300);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final correoGuardado = prefs.getString('ultimoCorreo') ?? '';
    final passGuardada = prefs.getString('ultimoPass') ?? '';

    if (correoGuardado.isEmpty || passGuardada.isEmpty) {
      _snack('Ingresa con contraseña primero', Colors.orange.shade300);
      return;
    }

    setState(() => _cargando = true);
    final user = await AuthService().login(correoGuardado, passGuardada);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (user == null) {
      _snack('Sesión expirada. Inicia con contraseña.', Colors.red.shade300);
      return;
    }

    await LogService().registrar(
      user.id,
      'Login biométrico',
      '${user.correo} entró con huella',
    );

    if (!mounted) return;
    _irA(user);
  }

  void _irA(user) {
    if (user.roleId == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminScreen(usuario: user)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserScreen(usuario: user)),
      );
    }
  }

  Future<void> _toggleBiometria(bool activar) async {
    if (activar) {
      final ok = await BiometricHelper.autenticar(
        razon: 'Confirma tu identidad para activar $_nombreBiometria',
      );
      if (!ok) {
        _snack('No se pudo activar $_nombreBiometria', Colors.orange.shade300);
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometriaActivada', activar);

    if (activar && _correo.text.isNotEmpty && _pass.text.isNotEmpty) {
      await prefs.setString('ultimoCorreo', _correo.text.trim().toLowerCase());
      await prefs.setString('ultimoPass', _pass.text);
    } else if (!activar) {
      await prefs.remove('ultimoPass');
    }

    setState(() => _biometriaActivada = activar);
    _snack(
      activar
          ? '$_nombreBiometria activada ✅'
          : '$_nombreBiometria desactivada',
      activar ? AppColores.success : Colors.grey,
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColores.pastelLavender,
              AppColores.pastelPink,
              AppColores.pastelPeach,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final anchoMax = constraints.maxWidth > 500
                  ? 420.0
                  : double.infinity;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: anchoMax),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Seguridad App',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sistema de Gestión de Usuarios',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Correos reales reciben 2FA por email',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _correo,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo electrónico',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'El correo es obligatorio';
                                      if (!RegExp(
                                        r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$',
                                      ).hasMatch(v.trim()))
                                        return 'Formato de correo inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _pass,
                                    obscureText: !_verPass,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _verPass
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () => setState(
                                          () => _verPass = !_verPass,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'La contraseña es obligatoria';
                                      if (v.length < 6)
                                        return 'Mínimo 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RecuperarPasswordScreen(),
                                        ),
                                      ),
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                      ),
                                    ),
                                  ),
                                  if (_biometriaDisponible)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColores.pastelMint
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.fingerprint,
                                            color: AppColores.pastelMintDark,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Usar $_nombreBiometria',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Switch(
                                            value: _biometriaActivada,
                                            activeColor:
                                                AppColores.pastelMintDark,
                                            onChanged: _toggleBiometria,
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _cargando ? null : _login,
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
                                              'INICIAR SESIÓN',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (_biometriaActivada) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColores.pastelMintDark,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: _cargando
                                            ? null
                                            : _loginConBiometria,
                                        icon: Icon(
                                          Icons.fingerprint,
                                          color: AppColores.pastelMintDark,
                                          size: 24,
                                        ),
                                        label: Text(
                                          'ENTRAR CON ${_nombreBiometria.toUpperCase()}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColores.pastelMintDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      '¿No tienes cuenta? Regístrate aquí',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }
}
