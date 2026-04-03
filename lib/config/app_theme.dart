import 'package:flutter/material.dart';

/// Paleta Titanium Minimalist para MyoAxon
/// Diseño: Clean Performance (claro) y Deep Neural (oscuro)
class AppTheme {
  // ==================== PALETA CLARA (Clean Performance) ====================
  static const Color _lightScaffold = Color(0xFFF8FAFC); // Blanco "hueso" suave
  static const Color _lightSurface = Color(0xFFFFFFFF); // Blanco puro
  static const Color _lightPrimary = Color(0xFF0284C7); // Azul Océano (el axón)
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightSecondary = Color(0xFF64748B); // Gris medio
  static const Color _lightOnSecondary = Color(0xFF0F172A);
  static const Color _lightTertiary = Color(0xFFF59E0B); // Ámbar (RPE/Intensidad)
  static const Color _lightTextPrimary = Color(0xFF0F172A); // Azul Pizarra casi negro
  static const Color _lightTextSecondary = Color(0xFF64748B); // Gris medio
  static const Color _lightDivider = Color(0xFFE2E8F0);
  static const Color _lightError = Color(0xFFEF4444);
  
  // Colores de contenedor para botones flotantes y steppers
  static const Color _lightPrimaryContainer = Color(0xFFBAE6FD); // Azul claro tenue
  static const Color _lightOnPrimaryContainer = Color(0xFF0C4A6E); // Azul oscuro

  // ==================== PALETA OSCURA (Deep Neural) ====================
  static const Color _darkScaffold = Color(0xFF020617); // Negro "Noche Profunda"
  static const Color _darkSurface = Color(0xFF1E293B); // Gris Azulado oscuro
  static const Color _darkPrimary = Color(0xFF38BDF8); // Cian Eléctrico (brilla en OLED)
  static const Color _darkOnPrimary = Color(0xFF020617);
  static const Color _darkSecondary = Color(0xFF94A3B8);
  static const Color _darkOnSecondary = Color(0xFFF1F5F9);
  static const Color _darkTertiary = Color(0xFFFB7185); // Rosa Eléctrico
  static const Color _darkTextPrimary = Color(0xFFF1F5F9); // Blanco Humo
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  static const Color _darkDivider = Color(0xFF334155);
  static const Color _darkError = Color(0xFFF87171);
  
  // Colores de contenedor para botones flotantes y steppers
  static const Color _darkPrimaryContainer = Color(0xFF0C4A6E); // Azul oscuro semitransparente
  static const Color _darkOnPrimaryContainer = Color(0xFFBAE6FD); // Azul claro

  // ==================== TEMA CLARO ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: _lightOnPrimary,
        secondary: _lightSecondary,
        onSecondary: _lightOnSecondary,
        tertiary: _lightTertiary,
        surface: _lightSurface,
        onSurface: _lightTextPrimary,
        error: _lightError,
        outline: _lightDivider,
        primaryContainer: _lightPrimaryContainer,
        onPrimaryContainer: _lightOnPrimaryContainer,
      ),
      scaffoldBackgroundColor: _lightScaffold,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: _lightPrimary.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: _lightOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          side: const BorderSide(color: _lightPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: _lightTextSecondary,
        size: 24,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _lightPrimary,
        textColor: _lightTextPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightScaffold,
        selectedColor: _lightPrimary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: _lightTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _lightDivider),
        ),
      ),
    );
  }

  // ==================== TEMA OSCURO ====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        secondary: _darkSecondary,
        onSecondary: _darkOnSecondary,
        tertiary: _darkTertiary,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        error: _darkError,
        outline: _darkDivider,
        primaryContainer: _darkPrimaryContainer,
        onPrimaryContainer: _darkOnPrimaryContainer,
      ),
      scaffoldBackgroundColor: _darkScaffold,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: _darkPrimary.withValues(alpha: 0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: _darkTextSecondary,
        size: 24,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _darkPrimary,
        textColor: _darkTextPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkScaffold,
        selectedColor: _darkPrimary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: _darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _darkDivider),
        ),
      ),
    );
  }

  // ==================== COLORES DE ACENTO COMPARTIDOS ====================
  static Color get accentAmber => const Color(0xFFF59E0B);
  static Color get accentPink => const Color(0xFFFB7185);
  
  // Nota: Los colores de acento se usan directamente en los sliders
  // a través de Theme.of(context).colorScheme.secondary y error
}
