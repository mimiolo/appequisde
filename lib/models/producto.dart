class Producto {
  final int? id;
  final String titulo;
  final String descripcion;
  final double precio;
  final String imagenUrl;
  final int stock;

  Producto({
    this.id,
    required this.titulo,
    this.descripcion = '',
    required this.precio,
    this.imagenUrl = '',
    required this.stock,
  });

  String get precioFormateado => '\$${precio.toStringAsFixed(2)} MXN';
  bool get hayStock => stock > 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'precio': precio,
        'imagen_url': imagenUrl,
        'stock': stock,
      };

  factory Producto.fromMap(Map<String, dynamic> m) => Producto(
        id: m['id'] as int?,
        titulo: (m['titulo'] ?? '') as String,
        descripcion: (m['descripcion'] ?? '') as String,
        precio: (m['precio'] as num?)?.toDouble() ?? 0.0,
        imagenUrl: (m['imagen_url'] ?? '') as String,
        stock: (m['stock'] ?? 0) as int,
      );
}
