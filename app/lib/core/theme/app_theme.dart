import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ManaLoom Theme: "Arcane Weaver" Color Palette
/// Inspired by weaving mana threads with technology
class AppTheme {
  // Color Palette
  static const Color backgroundAbyss = Color(0xFF0A0E14);  // Preto azulado profundo
  static const Color manaViolet = Color(0xFF8B5CF6);       // Roxo vibrante (Primary)
  static const Color loomCyan = Color(0xFF06B6D4);         // Ciano tecnológico (Secondary)
  static const Color mythicGold = Color(0xFFF59E0B);       // Dourado (Accent)
  static const Color surfaceSlate = Color(0xFF1E293B);     // Cinza ardósia (Cards)
  static const Color textPrimary = Color(0xFFF1F5F9);      // Branco suave
  static const Color textSecondary = Color(0xFF94A3B8);    // Cinza claro

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: manaViolet,
      secondary: loomCyan,
      tertiary: mythicGold,
      surface: surfaceSlate,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundAbyss,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceSlate,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: surfaceSlate,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: manaViolet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
