// Formulario para AGREGAR o MODIFICAR un producto.
// Con tema azul/morado y todas las validaciones.
import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import 'error_screen.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductoService();

  late TextEditingController _titulo;
  late TextEditingController _descripcion;
  late TextEditingController _precio;
  late TextEditingController _imagenUrl;
  late TextEditingController _stock;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.producto?.titulo ?? '');
    _descripcion =
        TextEditingController(text: widget.producto?.descripcion ?? '');
    _precio =
        TextEditingController(text: widget.producto?.precio.toString() ?? '');
    _imagenUrl = TextEditingController(text: widget.producto?.imagenUrl ?? '');
    _stock =
        TextEditingController(text: widget.producto?.stock.toString() ?? '');
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final titulo = _titulo.text.trim();

    if (!_esEdicion) {
      final sePuede = await _service.sePuedeCrearProducto();
      if (!sePuede) {
        if (!mounted) return;
        setState(() => _guardando = false);
        ErrorScreen.mostrar(context,
            titulo: 'Catálogo lleno',
            mensaje:
                'Ya alcanzaste el límite de ${ProductoService.MAX_PRODUCTOS} productos. '
                'Elimina alguno antes de agregar más.',
            icono: Icons.inventory_2_outlined);
        return;
      }
    }

    final existe =
        await _service.existeTitulo(titulo, exceptoId: widget.producto?.id);
    if (existe) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ErrorScreen.mostrar(context,
          titulo: 'Producto duplicado',
          mensaje:
              'Ya existe un producto con el título "$titulo". Usa otro nombre.',
          icono: Icons.inventory_2_outlined);
      return;
    }

    final producto = Producto(
      id: widget.producto?.id,
      titulo: titulo,
      descripcion: _descripcion.text.trim(),
      precio: double.parse(_precio.text.replaceAll(',', '.')),
      imagenUrl: _imagenUrl.text.trim(),
      stock: int.parse(_stock.text),
    );

    if (_esEdicion) {
      await _service.actualizar(producto);
    } else {
      await _service.crear(producto);
    }

    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_esEdicion
          ? 'Producto actualizado correctamente ✅'
          : 'Producto creado correctamente ✅'),
      backgroundColor: AppColores.success,
      behavior: SnackBarBehavior.floating,
    ));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Producto' : 'Agregar Producto'),
        backgroundColor: AppColores.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColores.softGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: AppColores.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Límites: stock 0-${ProductoService.MAX_STOCK}, '
                      'precio \$${ProductoService.MIN_PRECIO}-\$${ProductoService.MAX_PRECIO}, '
                      'título ${ProductoService.MIN_TITULO}-${ProductoService.MAX_TITULO} caracteres.',
                      style: const TextStyle(
                          fontSize: 11, color: AppColores.primaryDark),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColores.divider),
                ),
                child: _imagenUrl.text.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Pega una URL para ver la vista previa',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imagenUrl.text,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 60, color: AppColores.error),
                                SizedBox(height: 8),
                                Text('No se pudo cargar la imagen',
                                    style: TextStyle(color: AppColores.error)),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titulo,
                maxLength: ProductoService.MAX_TITULO,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Título del producto *',
                  prefixIcon: const Icon(Icons.title),
                  counterText:
                      '${_titulo.text.length}/${ProductoService.MAX_TITULO}',
                ),
                validator: _service.validarTitulo,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                maxLength: ProductoService.MAX_DESCRIPCION,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Descripción *',
                  prefixIcon: const Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                  counterText:
                      '${_descripcion.text.length}/${ProductoService.MAX_DESCRIPCION}',
                ),
                validator: _service.validarDescripcion,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _precio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'MXN',
                  helperText: 'Entre \$0.01 y \$999,999.99',
                ),
                validator: _service.validarPrecio,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imagenUrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen *',
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://ejemplo.com/imagen.jpg',
                ),
                validator: _service.validarImagenUrl,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Stock (cantidad disponible) *',
                  prefixIcon: const Icon(Icons.inventory),
                  helperText: 'Entre 0 y ${ProductoService.MAX_STOCK} unidades',
                  suffixIcon: _esStockBajo()
                      ? const Tooltip(
                          message: 'Stock bajo',
                          child: Icon(Icons.warning_amber,
                              color: AppColores.warning),
                        )
                      : null,
                ),
                validator: _service.validarStock,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColores.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR PRODUCTO',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _esStockBajo() {
    final s = int.tryParse(_stock.text);
    if (s == null) return false;
    return s > 0 && s <= ProductoService.STOCK_BAJO;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _imagenUrl.dispose();
    _stock.dispose();
    super.dispose();
  }
}
