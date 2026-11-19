// Centro de notificaciones / historial de actividad.
// Muestra las últimas acciones de los usuarios del sistema.
import 'package:flutter/material.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});
  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _service = LogService();
  List<Map<String, dynamic>> _logs = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final l = await _service.obtenerUltimas();
    if (!mounted) return;
    setState(() {
      _logs = l;
      _cargando = false;
    });
  }

  Future<void> _limpiar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Seguro que quieres borrar todo el historial?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar')),
        ],
      ),
    );
    if (ok == true) {
      await _service.limpiar();
      _cargar();
    }
  }

  // Icono según el tipo de acción
  IconData _icono(String accion) {
    final a = accion.toLowerCase();
    if (a.contains('login')) return Icons.login;
    if (a.contains('crear')) return Icons.person_add;
    if (a.contains('editar')) return Icons.edit;
    if (a.contains('eliminar')) return Icons.delete;
    if (a.contains('recuperar')) return Icons.lock_reset;
    return Icons.info_outline;
  }

  Color _color(String accion) {
    final a = accion.toLowerCase();
    if (a.contains('login')) return AppColores.pastelMintDark;
    if (a.contains('crear')) return AppColores.pastelLavenderDark;
    if (a.contains('editar')) return AppColores.pastelPeachDark;
    if (a.contains('eliminar')) return Colors.red.shade300;
    return AppColores.pastelBlueDark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _logs.isEmpty ? null : _limpiar,
            tooltip: 'Limpiar historial',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 90, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No hay notificaciones',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      final accion = log['accion'] as String? ?? '';
                      final color = _color(accion);
                      final fecha =
                          (log['fecha'] as String? ?? '').split('.').first;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(_icono(accion), color: color),
                          ),
                          title: Text(accion,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (log['detalle'] != null)
                                Text(log['detalle'] as String,
                                    style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                '${log['usuario'] ?? 'Sistema'} • $fecha',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          isThreeLine: log['detalle'] != null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
