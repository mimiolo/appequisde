import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/preferencias_service.dart';
import '../theme/app_theme.dart';

class PreferenciasScreen extends StatefulWidget {
  final Usuario usuario;
  const PreferenciasScreen({super.key, required this.usuario});
  @override
  State<PreferenciasScreen> createState() => _S();
}

class _S extends State<PreferenciasScreen> {
  final _service = PreferenciasService();
  bool _temaOscuro = false;
  bool _notificaciones = true;
  String _idioma = 'es';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await _service.obtener(widget.usuario.id!);
    setState(() {
      _temaOscuro = (p['tema_oscuro'] ?? 0) == 1;
      _notificaciones = (p['notificaciones'] ?? 1) == 1;
      _idioma = (p['idioma'] ?? 'es') as String;
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    await _service.actualizar(widget.usuario.id!,
        temaOscuro: _temaOscuro,
        notificaciones: _notificaciones,
        idioma: _idioma);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preferencias guardadas ✅'),
          backgroundColor: AppColores.success,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
            child: SwitchListTile(
          title: const Text('Tema oscuro'),
          subtitle: const Text('Cambia el aspecto de la app'),
          secondary:
              const Icon(Icons.dark_mode_outlined, color: AppColores.primary),
          value: _temaOscuro,
          onChanged: (v) => setState(() => _temaOscuro = v),
        )),
        Card(
            child: SwitchListTile(
          title: const Text('Notificaciones'),
          subtitle: const Text('Alertas de eventos importantes'),
          secondary: const Icon(Icons.notifications_outlined,
              color: AppColores.primary),
          value: _notificaciones,
          onChanged: (v) => setState(() => _notificaciones = v),
        )),
        Card(
            child: ListTile(
          leading: const Icon(Icons.language, color: AppColores.primary),
          title: const Text('Idioma'),
          subtitle: Text(_idioma == 'es' ? 'Español' : 'English'),
          trailing: DropdownButton<String>(
            value: _idioma,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) => setState(() => _idioma = v!),
          ),
        )),
        const SizedBox(height: 24),
        SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save),
              label: const Text('GUARDAR PREFERENCIAS'),
            )),
      ]),
    );
  }
}
