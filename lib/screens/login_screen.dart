import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/biometric_helper.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'user_screen.dart';
import 'register_screen.dart';
import 'recuperar_password_screen.dart';
import 'two_factor_screen.dart'; // ⚡ IMPORT NUEVO

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
  }

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

    if (!mounted) return;
    setState(() => _cargando = false);

    // ⚡ MANDAMOS AL GOOGLE AUTHENTICATOR
    final autenticado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TwoFactorScreen(correo: user.correo)),
    );

    if (autenticado == true) {
      await LogService().registrar(
        user.id,
        'Login',
        '${user.correo} inició sesión con 2FA',
      );
      _irA(user);
    } else {
      _snack('Autenticación cancelada o incorrecta', Colors.red);
    }
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

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
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
                          const Icon(
                            Icons.security,
                            size: 60,
                            color: AppColores.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _correo,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'El correo es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pass,
                            obscureText: !_verPass,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _verPass
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _verPass = !_verPass),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'La contraseña es obligatoria'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _cargando ? null : _login,
                              child: _cargando
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecuperarPasswordScreen(),
                              ),
                            ),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
