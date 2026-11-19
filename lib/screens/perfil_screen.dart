// Pantalla de perfil con saldo de PayPal actualizable.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/biometric_helper.dart';
import '../models/usuario.dart';
import '../services/paypal_service.dart';
import '../theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  const PerfilScreen({super.key, required this.usuario});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _notificacionesOn = true;
  bool _biometriaActiva = false;
  bool _biometriaDisponible = false;
  String _nombreBiometria = 'Biometría';
  Color _colorSeleccionado = AppColores.pastelLavender;

  double? _saldoPayPal;
  bool _cargandoSaldo = true;

  final List<Color> _coloresDisponibles = [
    AppColores.pastelLavender,
    AppColores.pastelPink,
    AppColores.pastelMint,
    AppColores.pastelPeach,
    AppColores.pastelBlue,
    AppColores.pastelYellow,
  ];

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
    _cargarSaldoPayPal();
  }

  Future<void> _cargarSaldoPayPal() async {
    setState(() => _cargandoSaldo = true); // ⚡ Mostramos spinner al recargar
    final saldo = await PayPalService.obtenerSaldoPayPal();
    if (mounted) {
      setState(() {
        _saldoPayPal = saldo;
        _cargandoSaldo = false;
      });
    }
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final disp = await BiometricHelper.disponible();
    final tipos = await BiometricHelper.obtenerTipos();

    if (!mounted) return;
    setState(() {
      _notificacionesOn = prefs.getBool('notificaciones') ?? true;
      _biometriaActiva = prefs.getBool('biometriaActivada') ?? false;
      _biometriaDisponible = disp;
      _nombreBiometria = BiometricHelper.nombreTipo(tipos);
      final colorIdx = prefs.getInt('colorAcento') ?? 0;
      if (colorIdx < _coloresDisponibles.length)
        _colorSeleccionado = _coloresDisponibles[colorIdx];
    });
  }

  Future<void> _guardarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificaciones', _notificacionesOn);
    await prefs.setInt(
      'colorAcento',
      _coloresDisponibles.indexOf(_colorSeleccionado),
    );
  }

  Future<void> _toggleBiometria(bool activar) async {
    if (activar) {
      final ok = await BiometricHelper.autenticar(
        razon: 'Confirma tu identidad para activar $_nombreBiometria',
      );
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo activar $_nombreBiometria'),
            backgroundColor: Colors.orange.shade300,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometriaActivada', activar);
    if (activar) {
      await prefs.setString('ultimoCorreo', widget.usuario.correo);
      await prefs.setString('ultimoPass', widget.usuario.pass);
    } else {
      await prefs.remove('ultimoPass');
    }

    if (!mounted) return;
    setState(() => _biometriaActiva = activar);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activar
              ? '$_nombreBiometria activada ✅'
              : '$_nombreBiometria desactivada',
        ),
        backgroundColor: activar ? AppColores.success : Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          // ⚡ BOTÓN PARA REFRESCAR EL SALDO
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar saldo',
            onPressed: _cargarSaldoPayPal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: _colorSeleccionado,
              child: Text(
                widget.usuario.inicial,
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.usuario.nombreCompleto,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ⚡ TARJETA DE SALDO PAYPAL
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Saldo disponible en PayPal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Moneda: MXN',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: _cargandoSaldo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _saldoPayPal == null
                    ? const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 28,
                      )
                    : Text(
                        '\$${_saldoPayPal!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _saldoPayPal! > 0 ? Colors.blue : Colors.red,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Notificaciones'),
                    subtitle: const Text('Recibir alertas de actividad'),
                    value: _notificacionesOn,
                    activeColor: _colorSeleccionado,
                    onChanged: (v) {
                      setState(() => _notificacionesOn = v);
                      _guardarPreferencias();
                    },
                  ),
                  if (_biometriaDisponible) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: Text('Inicio con $_nombreBiometria'),
                      subtitle: const Text('Usa huella o rostro para entrar'),
                      value: _biometriaActiva,
                      activeColor: _colorSeleccionado,
                      onChanged: _toggleBiometria,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Color de acento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _coloresDisponibles.map((c) {
                        final sel = c == _colorSeleccionado;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _colorSeleccionado = c);
                            _guardarPreferencias();
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: sel
                                  ? Border.all(color: Colors.black54, width: 3)
                                  : null,
                            ),
                            child: sel
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo'),
                subtitle: Text(widget.usuario.correo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
