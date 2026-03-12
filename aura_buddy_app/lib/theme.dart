import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aura Buddy — Clean Purple Gradient Theme
class AuraBuddyTheme {
  AuraBuddyTheme._();
  
  static Widget auraIcon({double size = 20}) => Image.asset(
    'assets/aura-coins-logo.jpg',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );

  // ─── Primary Palette ────────────────────────────────────────────
  // We use the highlight as the primary for actions
  static const Color primary = Color(0xFF00BFFF); // Skyblue
  static const Color primaryLight = Color(0xFF87CEFA); 
  static const Color primaryDark = Color(0xFF009ACD);

  // ─── Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)], // Aura gain gradient
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
  );

  // ─── Background & Surface ──────────────────────────────────────
  static const Color background = Color(0xFF0F0F0F); // Primary background
  static const Color surface = Color(0xFF1A1A1A); // Secondary background
  static const Color surfaceVariant = Color(0xFF2C2C2C); // Divider / subtle variant
  static const Color cardWhite = Color(0xFF1F1F1F); // Card background

  // ─── Semantic Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF22C55E); // Aura gain
  static const Color danger = Color(0xFFEF4444); // Aura loss
  static const Color warning = Color(0xFFFFD700); // Gold
  static const Color gold = Color(0xFFFFD700); // Gold

  // ─── Text ──────────────────────────────────────────────────────
  static const Color textDark = Color(0xFFFFFFFF); // Text primary (White on Black)
  static const Color textMedium = Color(0xFFD1D1D1); // Text secondary
  static const Color textLight = Color(0xFFAAAAAA); 
  static const Color textOnPrimary = Color(0xFF000000); // Black text on Skyblue/Gold buttons

  // ─── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> purpleGlow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  // ─── Decorations ───────────────────────────────────────────────
  static BoxDecoration whiteCard({double radius = 16}) => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: cardShadow,
  );

  static BoxDecoration splitCard({double radius = 16}) => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
  );

  static BoxDecoration gradientHeader({BorderRadius? borderRadius}) =>
      BoxDecoration(gradient: headerGradient, borderRadius: borderRadius);

  // ─── Theme Data ────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      brightness: Brightness.dark, // Changed to dark brightness for proper native color inverting
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        error: danger,
        onPrimary: textOnPrimary,
        onSurface: textDark,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w800,
          fontSize: 28,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textDark),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textMedium),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: textLight,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: GoogleFonts.inter(color: textDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 4,
      ),
    );
  }
}

