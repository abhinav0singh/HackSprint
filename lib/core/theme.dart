import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// MoneyByte AppTheme  (PRD §6 Design System)
// ─────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Colors ──────────────────────────────────────────────
  static const Color colorBackground    = Color(0xFF12151C);
  static const Color colorSurface       = Color(0xFF2A2D36);
  static const Color colorSurfaceAlt    = Color(0xFF1E2130);
  static const Color colorNeonGreen     = Color(0xFF00E676);
  static const Color colorRecoveryAmber = Color(0xFFFF9800);
  static const Color colorTextPrimary   = Color(0xFFFFFFFF);
  static const Color colorTextSecondary = Color(0xFFB0B8C8);
  static const Color colorError         = Color(0xFFFF5252);
  static const Color colorSuccess       = Color(0xFF69F0AE);
  static const Color colorDivider       = Color(0xFF3A3F4E);

  // Convenience alias used in multiple files
  static const Color kColorDivider      = Color(0xFF3A3F4E);

  // ── Neon BoxShadow helpers ───────────────────────────────
  /// Glowing ring shadow (neon green, 40% opacity)
  static List<BoxShadow> neonGlow({
    Color color = colorNeonGreen,
    double blurRadius = 28,
    double spreadRadius = 4,
  }) =>
      [
        BoxShadow(
          color: color.withOpacity(0.40),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ];

  /// Subtle amber glow for overdue elements
  static List<BoxShadow> amberGlow() => neonGlow(
        color: colorRecoveryAmber,
        blurRadius: 18,
        spreadRadius: 2,
      );

  // ── Typography ──────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: colorTextPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: colorTextPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: colorTextSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colorTextSecondary,
  );

  // ── ThemeData ────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: colorBackground,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          surface: colorSurface,
          primary: colorNeonGreen,
          error: colorError,
          onSurface: colorTextPrimary,
          onPrimary: colorBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: colorBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorTextPrimary,
          ),
          iconTheme: IconThemeData(color: colorTextPrimary),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: colorNeonGreen,
          foregroundColor: colorBackground,
          elevation: 6,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: colorSurfaceAlt,
          selectedItemColor: colorNeonGreen,
          unselectedItemColor: colorTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: colorSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorSurface,
          hintStyle: const TextStyle(color: colorTextSecondary),
          labelStyle: const TextStyle(color: colorTextSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorNeonGreen),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorError),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorNeonGreen,
            foregroundColor: colorBackground,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorNeonGreen,
            side: const BorderSide(color: colorNeonGreen),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorNeonGreen,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: colorDivider,
          thickness: 1,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colorSurfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: titleLarge,
          contentTextStyle: bodyMedium,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: colorSurface,
          contentTextStyle: bodyMedium.copyWith(color: colorTextPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: colorSurfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: colorSurface,
          labelStyle: labelSmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      );
}
