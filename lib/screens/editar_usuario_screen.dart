// Edición de usuario con las MISMAS validaciones que el registro.
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import 'error_screen.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final Usuario usuario;
  const EditarUsuarioScreen({super.key, required this.usuario});
  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombre;
  late TextEditingController _apP;
  late TextEditingController _apM;
  late TextEditingController _correo;
  late TextEditingController _pass;
  late int _roleId;
  bool _guardando = false;

  static const int MIN_NOMBRE = 5;
  static const int MAX_NOMBRE = 35;
  static const int MIN_PASS = 6;
  static const int MAX_PASS = 20;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.usuario.nombre);
    _apP = TextEditingController(text: widget.usuario.apellidoPaterno);
    _apM = TextEditingController(text: widget.usuario.apellidoMaterno);
    _correo = TextEditingController(text: widget.usuario.correo);
    _pass = TextEditingController(text: widget.usuario.pass);
    _roleId = widget.usuario.roleId;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final service = UsuarioService();

    // 1) Correo único
    final existe = await service.existeCorreo(
      _correo.text,
      exceptoId: widget.usuario.id,
    );
    if (existe) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ErrorScreen.mostrar(
        context,
        titulo: 'Correo ya en uso',
        mensaje: 'Otro usuario ya tiene ${_correo.text.trim()}.',
        icono: Icons.email_outlined,
      );
      return;
    }

    // 2) No degradar al último admin
    final eraAdmin = widget.usuario.roleId == 1;
    final quiereDejarDeSerAdmin = _roleId != 1;
    if (eraAdmin && quiereDejarDeSerAdmin) {
      final sePuede = await service.sePuedeQuitarAdmin(widget.usuario.id!);
      if (!sePuede) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ErrorScreen.mostrar(
          context,
          titulo: 'Último administrador',
          mensaje: 'No puedes cambiar el rol del último admin.',
          icono: Icons.admin_panel_settings_outlined,
        );
        return;
      }
    }

    // 3) Límite de admins al ascender
    final quiereAscender = widget.usuario.roleId != 1 && _roleId == 1;
    if (quiereAscender) {
      final sePuede = await service.sePuedeAgregarAdmin();
      if (!sePuede) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ErrorScreen.mostrar(
          context,
          titulo: 'Límite de administradores',
          mensaje: 'Ya hay ${UsuarioService.MAX_ADMINS} administradores.',
          icono: Icons.admin_panel_settings_outlined,
        );
        return;
      }
    }

    // 4) Guardar
    await service.actualizar(
      Usuario(
        id: widget.usuario.id,
        nombre: _nombre.text.trim(),
        apellidoPaterno: _apP.text.trim(),
        apellidoMaterno: _apM.text.trim(),
        correo: _correo.text.trim().toLowerCase(),
        pass: _pass.text,
        roleId: _roleId,
      ),
    );

    await LogService().registrar(
      null,
      'Editar usuario',
      'Se actualizó a ${_nombre.text.trim()}',
    );

    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados ✅'),
        backgroundColor: AppColores.pastelMintDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  // ---- Mismas validaciones que el registro ----
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
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
                backgroundColor: AppColores.pastelLavenderDark,
                child: Text(
                  widget.usuario.inicial,
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Los nombres deben tener entre $MIN_NOMBRE y $MAX_NOMBRE caracteres',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

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
                    return 'Formato inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pass,
                obscureText: true,
                maxLength: MAX_PASS,
                decoration: const InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText:
                      'Entre $MIN_PASS y $MAX_PASS caracteres, 1 letra y 1 número',
                ),
                validator: _validarPassword,
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                value: _roleId,
                decoration: const InputDecoration(
                  labelText: 'Rol *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('admin')),
                  DropdownMenuItem(value: 2, child: Text('editor')),
                  DropdownMenuItem(value: 3, child: Text('lector')),
                ],
                onChanged: (v) => setState(() => _roleId = v!),
              ),
              const SizedBox(height: 24),

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
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
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
    super.dispose();
  }
}
