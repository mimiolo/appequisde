// Modelo que representa UN producto/servicio de la respuesta de Punto Red.
// Agrego getter "logoUrl" que construye la URL del logo del servicio.
class PuntoRedProducto {
  final int? id;
  final String servicio;
  final String producto;
  final String idServicio;
  final String idProducto;
  final String idCatTipoServicio;
  final String tipoFront;
  final bool hasDigitoVerificador;
  final double precio;
  final bool showAyuda;
  final String tipoReferencia;
  final String legend;

  PuntoRedProducto({
    this.id,
    required this.servicio,
    required this.producto,
    required this.idServicio,
    required this.idProducto,
    required this.idCatTipoServicio,
    required this.tipoFront,
    required this.hasDigitoVerificador,
    required this.precio,
    required this.showAyuda,
    required this.tipoReferencia,
    required this.legend,
  });

  /// ⚡ URL del logo del servicio (endpoint oficial de Punto Red)
  /// Formato: {baseUrl}/sistema/images/gestopago/servicios/{idServicio}.png
  String get logoUrl {
    // ⚡ CAMBIA ESTA BASE si tu servidor es distinto.
    // En Postman aparece como {{GESTOPAGO_SERVER}}
    const base = 'https://gestopago.mx';
    return '$base/sistema/images/gestopago/servicios/$idServicio.png';
  }

  /// Convierte el objeto a Map para SQLite
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'servicio': servicio,
    'producto': producto,
    'id_servicio': idServicio,
    'id_producto': idProducto,
    'id_cat_tipo_servicio': idCatTipoServicio,
    'tipo_front': tipoFront,
    'has_digito_verificador': hasDigitoVerificador ? 1 : 0,
    'precio': precio,
    'show_ayuda': showAyuda ? 1 : 0,
    'tipo_referencia': tipoReferencia,
    'legend': legend,
  };

  factory PuntoRedProducto.fromMap(Map<String, dynamic> m) => PuntoRedProducto(
    id: m['id'] as int?,
    servicio: (m['servicio'] ?? '') as String,
    producto: (m['producto'] ?? '') as String,
    idServicio: (m['id_servicio'] ?? '') as String,
    idProducto: (m['id_producto'] ?? '') as String,
    idCatTipoServicio: (m['id_cat_tipo_servicio'] ?? '') as String,
    tipoFront: (m['tipo_front'] ?? '') as String,
    hasDigitoVerificador: (m['has_digito_verificador'] ?? 0) == 1,
    precio: (m['precio'] as num?)?.toDouble() ?? 0.0,
    showAyuda: (m['show_ayuda'] ?? 0) == 1,
    tipoReferencia: (m['tipo_referencia'] ?? '') as String,
    legend: (m['legend'] ?? '') as String,
  );

  /// Precio formateado para mostrar en UI
  String get precioFormateado => '\$${precio.toStringAsFixed(2)}';
}
