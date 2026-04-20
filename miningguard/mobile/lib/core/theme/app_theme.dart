import 'package:flutter/material.dart';

/// MiningGuard design system.
///
/// Color palette is chosen for high contrast in low-light mine environments
/// and for clear risk-level communication (green / amber / red).
class AppTheme {
  AppTheme._();

  // ── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primaryYellow = Color(0xFFF5A623);    // Safety yellow
  static const Color primaryDark = Color(0xFF1A1A2E);      // Deep navy — backgrounds
  static const Color accentBlue = Color(0xFF0EA5E9);       // Sky blue — CTAs

  // ── Risk Level Colors ─────────────────────────────────────────────────────
  static const Color riskLow = Color(0xFF22C55E);          // Green
  static const Color riskMedium = Color(0xFFF59E0B);       // Amber
  static const Color riskHigh = Color(0xFFEF4444);         // Red

  // ── Severity Colors ───────────────────────────────────────────────────────
  static const Color severityLow = Color(0xFF6B7280);      // Grey
  static const Color severityMedium = Color(0xFFF59E0B);   // Amber
  static const Color severityHigh = Color(0xFFEF4444);     // Red
  static const Color severityCritical = Color(0xFF7F1D1D); // Deep red

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryYellow,
        brightness: Brightness.light,
      ),
      fontFamily: 'NotoSans',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: primaryDark,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryYellow,
        brightness: Brightness.dark,
      ),
      fontFamily: 'NotoSans',
      scaffoldBackgroundColor: primaryDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F23),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
