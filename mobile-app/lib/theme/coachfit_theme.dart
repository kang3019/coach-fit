import 'package:flutter/material.dart';

abstract final class CoachFitColors {
  // 기본 테마 (AMOLED 다크 & 서피스)
  static const background = Color(0xFF0E1116);
  static const surface = Color(0xFF151922);
  static const surfaceRaised = Color(0xFF1D232D);
  static const surfaceSoft = Color(0xFF242C38);

  // 포인트 악센트 & 상태
  static const orange = Color(0xFFFF4820);
  static const mint = Color(0xFF00E5A0);
  static const accent = orange;
  static const success = mint;

  // 텍스트 & 경계선
  static const text = Color(0xFFF5F7F9);
  static const textSoft = Color(0xFFA9B0BB);
  static const textMuted = Color(0xFF6F7783);
  static const textPrimary = text;
  static const textSecondary = textSoft;
  static const divider = Color(0x1AFFFFFF);
  static const border = divider;
}

abstract final class CoachFitSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class CoachFitRadius {
  static const double small = 10;
  static const double medium = 16;
  static const double large = 20;
  static const double hero = 24;
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
