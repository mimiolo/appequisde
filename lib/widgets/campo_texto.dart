import 'package:flutter/material.dart';

class CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final bool obscure;
  final Widget? sufijo;
  final String? Function(String?)? validator;
  final TextInputType? tipo;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.label,
    required this.icono,
    this.obscure = false,
    this.sufijo,
    this.validator,
    this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: tipo,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono),
          suffixIcon: sufijo,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}
