// Formulario de registro con validaciones estrictas.
// - Si esAdmin=true → muestra el dropdown de roles
// - Si esAdmin=false (registro público) → asigna automáticamente "lector"
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import 'error_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool esAdmin;
  const RegisterScreen({super.key, this.esAdmin = false});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apP = TextEditingController();
  final _apM = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  // ⚡ Si no es admin, se asigna lector por defecto
  int _roleId = 3;
  bool _verPass = false;
  bool _guardando = false;

  // ====== VALIDACIONES ======
  static const int MIN_NOMBRE = 5;
  static const int MAX_NOMBRE = 35;
  static const int MIN_PASS = 6;
  static const int MAX_PASS = 20;

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final service = UsuarioService();

    // 1) Correo único
    final existeCorreo = await service.existeCorreo(_correo.text);
    if (existeCorreo) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ErrorScreen.mostrar(
        context,
        titulo: 'Correo ya registrado',
        mensaje: 'El correo ${_correo.text.trim()} ya está en uso.',
        icono: Icons.email_outlined,
      );
      return;
    }

    // 2) Solo validar límite de admin si realmente puede elegir rol
    if (widget.esAdmin && _roleId == 1) {
      final sePuede = await service.sePuedeAgregarAdmin();
      if (!sePuede) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ErrorScreen.mostrar(
          context,
          titulo: 'Límite de administradores',
          mensaje: 'Ya existe 1 administrador. No puedes crear más.',
          icono: Icons.admin_panel_settings_outlined,
        );
        return;
      }
    }

    // 3) Crear usuario
    await service.crear(
      Usuario(
        nombre: _nombre.text.trim(),
        apellidoPaterno: _apP.text.trim(),
        apellidoMaterno: _apM.text.trim(),
        correo: _correo.text.trim().toLowerCase(),
        pass: _pass.text,
        roleId: widget.esAdmin ? _roleId : 3, // ⚡ público = lector
      ),
    );

    await LogService().registrar(
      null,
      'Crear usuario',
      'Se creó a ${_nombre.text.trim()} como ${widget.esAdmin ? _nombreRol(_roleId) : "lector"}',
    );

    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.esAdmin
              ? 'Usuario registrado ✅'
              : '¡Cuenta creada! Ya puedes iniciar sesión ✅',
        ),
        backgroundColor: AppColores.pastelMintDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  String _nombreRol(int id) {
    switch (id) {
      case 1:
        return 'admin';
      case 2:
        return 'editor';
      default:
        return 'lector';
    }
  }

  String? _validarNombre(String? v, String campo, {bool obligatorio = true}) {
    if (v == null || v.trim().isEmpty) {
      return obligatorio ? 'El $campo es obligatorio' : null;
    }
    final len = v.trim().length;
    if (len < MIN_NOMBRE) return 'Mínimo $MIN_NOMBRE caracteres (tienes $len)';
    if (len > MAX_NOMBRE) return 'Máximo $MAX_NOMBRE caracteres (tienes $len)';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v.trim())) {
      return 'El $campo solo puede tener letras';
    }
    return null;
  }

  String? _validarPassword(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < MIN_PASS) return 'Mínimo $MIN_PASS caracteres';
    if (v.length > MAX_PASS) return 'Máximo $MAX_PASS caracteres';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Debe tener al menos 1 letra';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe tener al menos 1 número';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = widget.esAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(esAdmin ? 'Crear Usuario' : 'Registrarse'),
        backgroundColor: AppColores.pastelLavenderDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColores.pastelLavender,
                child: Icon(
                  esAdmin ? Icons.person_add : Icons.person,
                  size: 40,
                  color: AppColores.pastelLavenderDark,
                ),
              ),
              const SizedBox(height: 8),
              // Aviso: si es registro público, no puede elegir rol
              if (!esAdmin)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColores.pastelMint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColores.pastelMintDark.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColores.pastelMintDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Te registrarás como LECTOR. Un administrador podrá cambiarte el rol después.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                'Los nombres deben tener entre $MIN_NOMBRE y $MAX_NOMBRE caracteres',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombre,
                maxLength: MAX_NOMBRE,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => _validarNombre(v, 'nombre'),
              ),
              const SizedBox(height: 8),

              // Apellido paterno
              TextFormField(
                controller: _apP,
                maxLength: MAX_NOMBRE,
                decoration: const InputDecoration(
                  labelText: 'Apellido Paterno *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => _validarNombre(v, 'apellido paterno'),
              ),
              const SizedBox(height: 8),

              // Apellido materno (opcional)
              TextFormField(
                controller: _apM,
                maxLength: MAX_NOMBRE,
                decoration: const InputDecoration(
                  labelText: 'Apellido Materno (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    _validarNombre(v, 'apellido materno', obligatorio: false),
              ),
              const SizedBox(height: 8),

              // Correo
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El correo es obligatorio';
                  if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                      .hasMatch(v.trim()))
                    return 'Formato de correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _pass,
                obscureText: !_verPass,
                maxLength: MAX_PASS,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText:
                      'Entre $MIN_PASS y $MAX_PASS caracteres, 1 letra y 1 número',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verPass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _verPass = !_verPass),
                  ),
                ),
                validator: _validarPassword,
              ),
              const SizedBox(height: 8),

              // Confirmar contraseña
              TextFormField(
                controller: _pass2,
                obscureText: !_verPass,
                maxLength: MAX_PASS,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma la contraseña';
                  if (v != _pass.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ⚡ DROPDOWN DE ROLES: solo si viene del admin
              if (esAdmin) ...[
                DropdownButtonFormField<int>(
                  value: _roleId,
                  decoration: const InputDecoration(
                    labelText: 'Rol *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('admin - Control total'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('editor - Puede editar'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('lector - Solo consulta'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _roleId = v!),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColores.pastelYellow.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColores.pastelYellowDark.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColores.pastelYellowDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solo puede existir ${UsuarioService.MAX_ADMINS} administrador.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Botón
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
                  onPressed: _guardando ? null : _registrar,
                  child: _guardando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          esAdmin ? 'REGISTRAR USUARIO' : 'CREAR CUENTA',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apP.dispose();
    _apM.dispose();
    _correo.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }
}
