import 'package:flutter/material.dart';

abstract final class CoachFitColors {
  static const background = Color(0xFF090B0F);
  static const surface = Color(0xFF11151B);
  static const surfaceRaised = Color(0xFF171C24);
  static const surfaceSoft = Color(0xFF1D232D);
  static const orange = Color(0xFFFF5A31);
  static const mint = Color(0xFF31E6AA);
  static const text = Color(0xFFF5F7F9);
  static const textSoft = Color(0xFFA9B0BB);
  static const textMuted = Color(0xFF6F7783);
  static const divider = Color(0x14FFFFFF);
}

abstract final class CoachFitTheme {
  static ThemeData dark(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: CoachFitColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: CoachFitColors.background,
      dividerColor: CoachFitColors.divider,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: CoachFitColors.background,
        foregroundColor: CoachFitColors.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: CoachFitColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CoachFitColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoachFitColors.surface,
        hintStyle: const TextStyle(color: CoachFitColors.textMuted),
        prefixIconColor: CoachFitColors.textMuted,
        suffixIconColor: CoachFitColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoachFitColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoachFitColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoachFitColors.orange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: CoachFitColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CoachFitColors.surfaceSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CoachFitColors.surfaceRaised,
        contentTextStyle: const TextStyle(color: CoachFitColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
