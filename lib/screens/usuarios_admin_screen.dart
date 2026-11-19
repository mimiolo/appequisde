// Panel de GESTIÓN DE USUARIOS para el admin.
// Puede: Ver, Crear, Editar y Eliminar usuarios.
// Reglas: solo 1 admin, no eliminarse a sí mismo, no borrar el último admin.
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'editar_usuario_screen.dart';
import 'error_screen.dart';

class UsuariosAdminScreen extends StatefulWidget {
  final Usuario usuarioActual;
  const UsuariosAdminScreen({super.key, required this.usuarioActual});
  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
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

  // ============ CREAR USUARIO ============
  Future<void> _crear() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen(esAdmin: true)),
    );
    _cargar();
  }

  // ============ EDITAR USUARIO ============
  Future<void> _editar(Usuario u) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarUsuarioScreen(usuario: u)),
    );
    if (ok == true) _cargar();
  }

  // ============ ELIMINAR USUARIO ============
  Future<void> _eliminar(Usuario u) async {
    // Regla 1: no eliminarme a mí mismo
    if (u.id == widget.usuarioActual.id) {
      ErrorScreen.mostrar(
        context,
        titulo: 'Acción no permitida',
        mensaje: 'No puedes eliminarte a ti mismo mientras estás en sesión.',
        icono: Icons.block,
      );
      return;
    }

    // Regla 2: no eliminar al último admin
    final sePuede = await _service.sePuedeEliminar(u.id!);
    if (!sePuede) {
      if (!mounted) return;
      ErrorScreen.mostrar(
        context,
        titulo: 'Último administrador',
        mensaje:
            'No puedes eliminar a ${u.nombreCompleto} porque es el último administrador.',
        icono: Icons.admin_panel_settings_outlined,
      );
      return;
    }

    // Confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar usuario'),
          ],
        ),
        content: Text('¿Eliminar a ${u.nombreCompleto}? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColores.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.eliminar(u.id!);
      await LogService().registrar(
        widget.usuarioActual.id,
        'Eliminar usuario',
        'Se eliminó a ${u.nombreCompleto} (${u.correo})',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado ✅'),
          backgroundColor: AppColores.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cargar();
    }
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
    final admins = _usuarios.where((u) => u.roleId == 1).length;
    final editores = _usuarios.where((u) => u.roleId == 2).length;
    final lectores = _usuarios.where((u) => u.roleId == 3).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColores.pastelPinkDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ---- Estadísticas ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: AppColores.primaryGradient,
            ),
            child: Row(
              children: [
                _stat('Total', _usuarios.length, Colors.white),
                _stat('Admins', admins, Colors.white),
                _stat('Editores', editores, Colors.white),
                _stat('Lectores', lectores, Colors.white),
              ],
            ),
          ),

          // ---- Buscador ----
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscador,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o rol...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // ---- Lista ----
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay usuarios',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) => _tarjetaUsuario(_filtrados[i]),
                    ),
                  ),
          ),
        ],
      ),
      // ---- FAB para crear usuario ----
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        backgroundColor: AppColores.pastelPinkDark,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }

  // ---- Tarjeta individual ----
  Widget _tarjetaUsuario(Usuario u) {
    final esYo = u.id == widget.usuarioActual.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                u.nombreCompleto,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (esYo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColores.pastelBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TÚ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColores.pastelBlueDark,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.correo, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (v) {
            if (v == 'editar') _editar(u);
            if (v == 'eliminar') _eliminar(u);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit, color: AppColores.pastelLavenderDark),
                title: Text('Editar'),
              ),
            ),
            PopupMenuItem(
              value: 'eliminar',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar'),
              ),
            ),
          ],
        ),
        onTap: () => _editar(u),
      ),
    );
  }

  Widget _stat(String label, int valor, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$valor',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }
}
