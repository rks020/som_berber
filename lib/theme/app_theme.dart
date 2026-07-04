import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color goldDark = Color(0xFF8A6D3B);
  static const Color goldMedium = Color(0xFFC5A880);
  static const Color goldLight = Color(0xFFE6D5B8);
  static const Color goldPrimary = Color(0xFFD4AF37);

  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color bgCard = Color(0xFF161616);
  static const Color bgField = Color(0xFF222222);

  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFFAAAAAA);

  static const Color accentGreen = Color(0xFF2EC4B6);
  static const Color accentRed = Color(0xFFE71D36);

  static LinearGradient get goldGradient => const LinearGradient(
    colors: [goldDark, goldPrimary, goldLight],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static LinearGradient get darkCardGradient => const LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: goldPrimary,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: goldPrimary,
        secondary: goldMedium,
        surface: bgCard,
        error: accentRed,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: goldPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: goldPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: bgDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldPrimary,
          side: const BorderSide(color: goldPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: goldPrimary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: Color(0xFF666666)),
        prefixIconColor: goldMedium,
        suffixIconColor: goldMedium,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textLight,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: goldPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: textLight, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: goldPrimary,
        foregroundColor: bgDark,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: goldPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
