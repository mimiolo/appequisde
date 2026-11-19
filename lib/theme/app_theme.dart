import 'package:flutter/material.dart';

class AppColores {
  static const Color pastelPink = Color(0xFFF8BBD0);
  static const Color pastelPinkDark = Color(0xFFEC7DA1);
  static const Color pastelLavender = Color(0xFFD1C4E9);
  static const Color pastelLavenderDark = Color(0xFF9575CD);
  static const Color pastelMint = Color(0xFFB2DFDB);
  static const Color pastelMintDark = Color(0xFF4DB6AC);
  static const Color pastelPeach = Color(0xFFFFCCBC);
  static const Color pastelPeachDark = Color(0xFFFF8A65);
  static const Color pastelBlue = Color(0xFFBBDEFB);
  static const Color pastelBlueDark = Color(0xFF64B5F6);
  static const Color pastelYellow = Color(0xFFFFF9C4);
  static const Color pastelYellowDark = Color(0xFFFDD835);

  static const Color primary = pastelLavenderDark;
  static const Color primaryDark = Color(0xFF7E57C2);
  static const Color secondary = pastelPinkDark;
  static const Color secondaryDark = Color(0xFFC2185B);
  static const Color accent = pastelPeachDark;
  static const Color accentLight = pastelPeach;
  static const Color success = pastelMintDark;
  static const Color warning = pastelYellowDark;
  static const Color error = Color(0xFFE57373);
  static const Color info = pastelBlueDark;
  static const Color background = Color(0xFFFAF9FC);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF8B88A0);

  static const Color adminColor = pastelPinkDark;
  static const Color editorColor = pastelPeachDark;
  static const Color lectorColor = pastelMintDark;
  static const Color pedidoPendiente = pastelYellowDark;
  static const Color pedidoEntregado = pastelMintDark;
  static const Color pedidoCancelado = pastelPinkDark;

  static const Color bgLight = Color(0xFFFAF9FC);
  static const Color bgDark = Color(0xFF1A1A1A);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF2A2A2A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pastelLavenderDark, pastelPinkDark],
  );
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7E57C2), Color(0xFFC2185B)],
  );
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pastelYellow, pastelPeach],
  );
}

class AppTema {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColores.bgLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColores.pastelLavenderDark,
      brightness: Brightness.light,
      primary: AppColores.pastelLavenderDark,
      secondary: AppColores.pastelPinkDark,
      surface: AppColores.cardLight,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: AppColores.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColores.pastelLavender.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColores.pastelLavender.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColores.pastelLavenderDark, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColores.pastelLavenderDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColores.bgDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColores.pastelLavender,
      brightness: Brightness.dark,
      primary: AppColores.pastelLavender,
      secondary: AppColores.pastelPink,
      surface: AppColores.cardDark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: AppColores.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
