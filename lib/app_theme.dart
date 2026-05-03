import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF32415C);
  static const Color defaultAccent = Color(0xFFF5A623);
  static const Color lightBackground = Color(0xFFF7F1E8);

  /// Build theme from ThemeProvider state
  /// Light mode accent: #1A2B49, Dark mode accent: #F5A623
  static ThemeData buildTheme(ThemeProvider provider) {
    final isDark = provider.isDarkMode;
    final accent = provider.accentColor;
    final bg = isDark ? darkBackground : lightBackground;
    final cardColor = isDark ? const Color(0xFF3D4F6E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1C3D);
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white24 : Colors.black12;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,

      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: cardColor,
        onSurface: textColor,
        error: Colors.red,
        onError: Colors.white,
        background: bg,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: GoogleFonts.nunitoTextTheme(
        TextTheme(
          /// PAGE TITLES
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark
                ? const Color(0xFFF5A623)
                : const Color(0xFF1A2B49),
          ),

          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),

          bodyMedium: TextStyle(
            fontSize: 16,
            color: textColor,
          ),

          bodySmall: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        hintStyle: TextStyle(color: textMuted),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF3D4F6E) : const Color(0xFFF5EFE4),
        selectedItemColor: accent,
        unselectedItemColor:
            isDark ? Colors.white60 : Colors.grey.shade700,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textColor,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: borderColor,
      ),

      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: accent,
      ),
    );
  }

  /// Original light theme for pre-application screens
  static ThemeData get originalLight => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F1E8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C1C3D),
          primary: const Color(0xFF0C1C3D),
          secondary: const Color(0xFFF5D47A),
          background: const Color(0xFFF7F1E8),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0C1C3D),
            textStyle: const TextStyle(fontSize: 14),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF0C1C3D), width: 2),
          ),
          hintStyle: const TextStyle(color: Colors.black38),
        ),
      );
}
