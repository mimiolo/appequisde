// Pantalla con 3 pasos:
// 1. Pedir el correo (se envía OTP por Gmail)
// 2. El usuario ingresa el código recibido
// 3. Cambiar la contraseña
import 'package:flutter/material.dart';
import '../services/recuperacion_service.dart';
import '../theme/app_theme.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});
  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  int _paso = 1;
  final _correoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _cargando = false;

  final _service = RecuperacionService();

  // PASO 1: pedir código
  Future<void> _pedirCodigo() async {
    final correo = _correoCtrl.text.trim();
    if (correo.isEmpty) {
      _snack('Escribe tu correo', AppColores.warning);
      return;
    }
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(correo)) {
      _snack('Formato de correo inválido', AppColores.warning);
      return;
    }

    setState(() => _cargando = true);

    try {
      final enviado = await _service.solicitarCodigo(correo);
      if (!mounted) return;
      setState(() => _cargando = false);

      if (!enviado) {
        _snack('Ese correo no está registrado', AppColores.error);
        return;
      }

      _snack('Código enviado a $correo ✅', AppColores.success);
      setState(() => _paso = 2);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _snack('Error al enviar correo: $e', AppColores.error);
    }
  }

  // PASO 2: verificar código
  Future<void> _verificarCodigo() async {
    if (_codigoCtrl.text.trim().length != 6) {
      _snack('El código debe tener 6 dígitos', AppColores.warning);
      return;
    }
    setState(() => _cargando = true);
    final ok = await _service.verificarCodigo(
        _correoCtrl.text.trim(), _codigoCtrl.text.trim());
    if (!mounted) return;
    setState(() => _cargando = false);

    if (!ok) {
      _snack('Código incorrecto o expirado', AppColores.error);
      return;
    }
    setState(() => _paso = 3);
  }

  // PASO 3: cambiar contraseña
  Future<void> _cambiarPassword() async {
    if (_nuevaPassCtrl.text.length < 6) {
      _snack('Mínimo 6 caracteres', AppColores.warning);
      return;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(_nuevaPassCtrl.text)) {
      _snack('Debe tener al menos 1 letra', AppColores.warning);
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(_nuevaPassCtrl.text)) {
      _snack('Debe tener al menos 1 número', AppColores.warning);
      return;
    }
    if (_nuevaPassCtrl.text != _confirmarCtrl.text) {
      _snack('Las contraseñas no coinciden', AppColores.warning);
      return;
    }

    setState(() => _cargando = true);
    final ok = await _service.cambiarPassword(
        _correoCtrl.text.trim(), _codigoCtrl.text.trim(), _nuevaPassCtrl.text);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (ok) {
      _snack('Contraseña actualizada ✅', AppColores.success);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _snack('No se pudo actualizar', AppColores.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Indicador de pasos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pasoDot(1, 'Correo'),
                _pasoLinea(),
                _pasoDot(2, 'Código'),
                _pasoLinea(),
                _pasoDot(3, 'Nueva'),
              ],
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _paso == 1
                    ? _pasoUno()
                    : _paso == 2
                        ? _pasoDos()
                        : _pasoTres(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pasoUno() => Column(
        children: [
          const Icon(Icons.email_outlined,
              size: 60, color: AppColores.pastelLavenderDark),
          const SizedBox(height: 16),
          const Text('Ingresa tu correo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Te enviaremos un código de 6 dígitos por Gmail',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _cargando ? null : _pedirCodigo,
              child: _cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENVIAR CÓDIGO'),
            ),
          ),
        ],
      );

  Widget _pasoDos() => Column(
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 60, color: AppColores.pastelMintDark),
          const SizedBox(height: 16),
          const Text('Revisa tu correo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Enviamos un código a ${_correoCtrl.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColores.pastelBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: AppColores.pastelBlueDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Busca un correo de "Seguridad App" con asunto "Recuperación de contraseña". Revisa también SPAM.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codigoCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
              labelText: 'Código recibido',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _cargando ? null : _verificarCodigo,
              child: _cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('VERIFICAR CÓDIGO'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cargando ? null : () => setState(() => _paso = 1),
            child: const Text('¿No te llegó? Reenviar'),
          ),
        ],
      );

  Widget _pasoTres() => Column(
        children: [
          const Icon(Icons.lock_reset,
              size: 60, color: AppColores.pastelPeachDark),
          const SizedBox(height: 16),
          const Text('Nueva contraseña',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Mínimo 6 caracteres, al menos 1 letra y 1 número',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          TextField(
            controller: _nuevaPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmarCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _cargando ? null : _cambiarPassword,
              child: _cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CAMBIAR CONTRASEÑA'),
            ),
          ),
        ],
      );

  Widget _pasoDot(int paso, String label) {
    final activo = _paso >= paso;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                activo ? AppColores.pastelLavenderDark : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$paso',
                style: TextStyle(
                    color: activo ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: activo ? AppColores.pastelLavenderDark : Colors.grey)),
      ],
    );
  }

  Widget _pasoLinea() => Container(
        width: 40,
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: Colors.grey.shade300,
      );

  @override
  void dispose() {
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaPassCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }
}
