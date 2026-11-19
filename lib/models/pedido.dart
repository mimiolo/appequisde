// Modelo Pedido con ubicación GPS (lat/lng) + dirección legible.
import 'dart:convert';

class Pedido {
  final int? id;
  final int usuarioId;
  final String usuarioNombre;
  final String usuarioCorreo;
  final double total;
  final String estado;
  final List<Map<String, dynamic>> items;
  final double? latitud;
  final double? longitud;
  final String? direccion; // ⚡ NUEVO campo
  final String? createdAt;

  Pedido({
    this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.total,
    this.estado = 'pendiente',
    required this.items,
    this.latitud,
    this.longitud,
    this.direccion,
    this.createdAt,
  });

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  bool get tieneUbicacion => latitud != null && longitud != null;

  int get cantidadTotal =>
      items.fold<int>(0, (s, i) => s + ((i['cantidad'] ?? 0) as int));

  String get totalFormateado => '\$${total.toStringAsFixed(2)} MXN';

  String get fechaCorta {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt!;
    }
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'usuario_id': usuarioId,
    'usuario_nombre': usuarioNombre,
    'usuario_correo': usuarioCorreo,
    'total': total,
    'estado': estado,
    'items': json.encode(items),
    'latitud': latitud,
    'longitud': longitud,
    'direccion': direccion,
  };

  factory Pedido.fromMap(Map<String, dynamic> m) => Pedido(
    id: m['id'] as int?,
    usuarioId: m['usuario_id'] as int,
    usuarioNombre: (m['usuario_nombre'] ?? '') as String,
    usuarioCorreo: (m['usuario_correo'] ?? '') as String,
    total: (m['total'] as num?)?.toDouble() ?? 0.0,
    estado: (m['estado'] ?? 'pendiente') as String,
    items: List<Map<String, dynamic>>.from(
      json.decode(m['items'] as String) as List<dynamic>,
    ),
    latitud: (m['latitud'] as num?)?.toDouble(),
    longitud: (m['longitud'] as num?)?.toDouble(),
    direccion: m['direccion'] as String?,
    createdAt: m['createdAT'] as String?,
  );
}
