// Test básico: verifico que la app arranque sin errores.
// (El test original era de un contador que ya no aplica a esta app.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pruebas/main.dart';

void main() {
  testWidgets('La app arranca y muestra el Login', (WidgetTester tester) async {
    // Construyo la app
    await tester.pumpWidget(const MyApp(modoOscuroInicial: false));

    // Verifico que se muestre el título "Seguridad App"
    expect(find.text('Seguridad App'), findsOneWidget);

    // Verifico que exista el botón de iniciar sesión
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
