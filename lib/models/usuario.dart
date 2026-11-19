class Usuario {
  final int? id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String correo;
  final String pass;
  final int roleId;

  Usuario({
    this.id,
    required this.nombre,
    this.apellidoPaterno = '',
    this.apellidoMaterno = '',
    required this.correo,
    required this.pass,
    required this.roleId,
  });

  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno'
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  String get rolNombre {
    switch (roleId) {
      case 1:
        return 'admin';
      case 2:
        return 'editor';
      case 3:
        return 'lector';
      default:
        return 'desconocido';
    }
  }

  String get inicial => nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'correo': correo,
        'pass': pass,
        'role_id': roleId,
      };

  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
        id: m['id'] as int?,
        nombre: (m['nombre'] ?? '') as String,
        apellidoPaterno: (m['apellido_paterno'] ?? '') as String,
        apellidoMaterno: (m['apellido_materno'] ?? '') as String,
        correo: (m['correo'] ?? '') as String,
        pass: (m['pass'] ?? '') as String,
        roleId: (m['role_id'] ?? 3) as int,
      );
}
