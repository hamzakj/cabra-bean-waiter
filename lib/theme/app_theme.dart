import 'package:flutter/material.dart';

class AppTheme {
  // Coffee Luxury Palette
  static const Color primaryCoffee = Color(0xFF4E342E);
  static const Color primaryAmber = Color(0xFFC58940);
  static const Color secondaryRoast = Color(0xFF6D4C41);
  static const Color accentCaramel = Color(0xFFE5A958);
  static const Color backgroundCream = Color(0xFFFBF8F5);
  static const Color surfaceWarm = Color(0xFFFFFFFF);
  static const Color cardLatte = Color(0xFFF7F3EE);
  static const Color textDark = Color(0xFF231815);
  static const Color textMuted = Color(0xFF7D6E68);
  static const Color borderSubtle = Color(0xFFE8DFD7);
  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color statusOrange = Color(0xFFEF6C00);
  static const Color statusBlue = Color(0xFF1565C0);
  static const Color statusRed = Color(0xFFC62828);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryCoffee,
      primary: primaryCoffee,
      secondary: primaryAmber,
      surface: surfaceWarm,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundCream,
      fontFamily: 'Cairo', // Falls back to system sans if not bundled
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryCoffee,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWarm,
        elevation: 1.5,
        shadowColor: primaryCoffee.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCoffee,
          side: const BorderSide(color: primaryCoffee, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWarm,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAmber, width: 1.8),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardLatte,
        selectedColor: primaryAmber,
        secondarySelectedColor: primaryAmber,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderSubtle, width: 0.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWarm,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWarm,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
