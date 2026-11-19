import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚡ INICIALIZAR BASE DE DATOS PARA WEB
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  final prefs = await SharedPreferences.getInstance();
  final modoOscuro = prefs.getBool('modoOscuro') ?? false;
  runApp(MyApp(modoOscuroInicial: modoOscuro));
}

class MyApp extends StatefulWidget {
  final bool modoOscuroInicial;
  const MyApp({super.key, required this.modoOscuroInicial});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguridad App',
      debugShowCheckedModeBanner: false,
      theme: AppTema.light,
      darkTheme: AppTema.dark,
      themeMode: widget.modoOscuroInicial ? ThemeMode.dark : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}
