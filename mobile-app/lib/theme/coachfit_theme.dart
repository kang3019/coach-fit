import 'package:flutter/material.dart';

abstract final class CoachFitColors {
  // Figma 1:1 컬러 시스템 (AMOLED 딥 다크 & 서피스)
  static const background = Color(0xFF090B0F); // --bg: #090B0F
  static const surface = Color(0xFF11151B); // --surface: #11151B
  static const surfaceRaised = Color(0xFF171C24); // --surface-raised: #171C24
  static const surfaceSoft = Color(0xFF1D232D); // --surface-soft: #1D232D

  // 포인트 악센트 & 소프트 배지
  static const orange = Color(0xFFFF5A31); // --orange: #FF5A31
  static const orangeBright = Color(0xFFFF6C47); // --orange-bright: #FF6C47
  static const orangeSoft = Color(0x24FF5A31); // --orange-soft: rgba(255, 90, 49, 0.14)
  static const mint = Color(0xFF31E6AA); // --mint: #31E6AA
  static const mintSoft = Color(0x2131E6AA); // --mint-soft: rgba(49, 230, 170, 0.13)
  static const accent = orange;
  static const success = mint;

  // 텍스트 & 경계선
  static const text = Color(0xFFF5F7F9); // --text: #F5F7F9
  static const textSoft = Color(0xFFA9B0BB); // --text-soft: #A9B0BB
  static const textMuted = Color(0xFF6F7783); // --text-muted: #6F7783
  static const textPrimary = text;
  static const textSecondary = textSoft;
  static const line = Color(0x14FFFFFF); // --line: rgba(255, 255, 255, 0.08)
  static const lineStrong = Color(0x21FFFFFF); // --line-strong: rgba(255, 255, 255, 0.13)
  static const divider = line;
  static const border = line;
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
  static const double medium = 14;
  static const double large = 20;
  static const double hero = 28;
  static const double pill = 999;
}

abstract final class CoachFitTypography {
  // Eyebrow / Kicker (10px, w850, +0.12em)
  static const kicker = TextStyle(
    color: CoachFitColors.orange,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  // Page Title (29px, w850, -0.05em)
  static const pageTitle = TextStyle(
    color: CoachFitColors.text,
    fontSize: 29,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
  );

  // Page Caption (11px, w500)
  static const pageCaption = TextStyle(
    color: CoachFitColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // Hero Display (24~26px, w850, -0.05em)
  static const heroDisplay = TextStyle(
    color: CoachFitColors.text,
    fontSize: 25,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  // Section Title (16px, w780, -0.025em)
  static const sectionTitle = TextStyle(
    color: CoachFitColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  // Card Metric (23px, w850, -0.035em)
  static const cardMetric = TextStyle(
    color: CoachFitColors.text,
    fontSize: 23,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  // Body Primary (13px, w700, -0.01em)
  static const bodyPrimary = TextStyle(
    color: CoachFitColors.text,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.13,
  );

  // Caption / Sub (11px, w500)
  static const caption = TextStyle(
    color: CoachFitColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
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
          borderRadius: BorderRadius.circular(CoachFitRadius.large),
          side: const BorderSide(color: CoachFitColors.line),
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
          borderSide: const BorderSide(color: CoachFitColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoachFitColors.line),
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
