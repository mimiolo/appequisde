// Pantalla de SOLO LECTURA para que el editor vea usuarios.
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';

class VerUsuariosScreen extends StatefulWidget {
  const VerUsuariosScreen({super.key});
  @override
  State<VerUsuariosScreen> createState() => _VerUsuariosScreenState();
}

class _VerUsuariosScreenState extends State<VerUsuariosScreen> {
  final _service = UsuarioService();
  List<Usuario> _usuarios = [];
  List<Usuario> _filtrados = [];
  final _buscador = TextEditingController();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final l = await _service.obtenerTodos();
    if (!mounted) return;
    setState(() {
      _usuarios = l;
      _filtrados = l;
      _cargando = false;
    });
  }

  void _filtrar(String q) {
    q = q.toLowerCase();
    setState(() {
      _filtrados = _usuarios
          .where(
            (u) =>
                u.nombre.toLowerCase().contains(q) ||
                u.apellidoPaterno.toLowerCase().contains(q) ||
                u.correo.toLowerCase().contains(q) ||
                u.rolNombre.contains(q),
          )
          .toList();
    });
  }

  Color _colorRol(int id) {
    switch (id) {
      case 1:
        return AppColores.adminColor;
      case 2:
        return AppColores.editorColor;
      default:
        return AppColores.lectorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios del sistema'),
        backgroundColor: AppColores.pastelPeachDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColores.pastelPeach.withOpacity(0.4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColores.pastelPeachDark,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Modo solo lectura. No puedes editar ni eliminar usuarios.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscador,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o rol...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                ? const Center(child: Text('No hay usuarios'))
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final u = _filtrados[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _colorRol(u.roleId),
                              child: Text(
                                u.inicial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              u.nombreCompleto,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.correo,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _colorRol(u.roleId).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    u.rolNombre,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _colorRol(u.roleId),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            // ⚡ NO hay trailing, editor SOLO puede ver
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }
}
