import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit {
  kg('kg', '킬로그램', 1.0),
  lbs('lbs', '파운드', 2.20462);

  final String symbol;
  final String label;
  final double kgToUnitFactor;
  const WeightUnit(this.symbol, this.label, this.kgToUnitFactor);

  double fromKg(double kg) => kg * kgToUnitFactor;
  double toKg(double v) => v / kgToUnitFactor;
}

enum ThemeAccent {
  mint('민트', Color(0xFF00E5A0)),
  orange('오렌지 레드', Color(0xFFFF4820)),
  cyan('시안', Color(0xFF22D3EE)),
  violet('바이올렛', Color(0xFF8B5CF6)),
  pink('핑크', Color(0xFFEC4899));

  final String label;
  final Color color;
  const ThemeAccent(this.label, this.color);
}

enum TextScale {
  small('작게', 0.9),
  normal('보통', 1.0),
  large('크게', 1.15);

  final String label;
  final double factor;
  const TextScale(this.label, this.factor);
}

/// 앱 전역 설정 (무게 단위 / 테마 포인트 색 / 글자 크기 / 튜토리얼 플래그) 통합 서비스.
/// 싱글톤 ChangeNotifier — 설정 변경 시 MaterialApp 가 자동 리빌드 되도록 구독.
///
/// 담당 기능:
/// - A) 무게 단위 (kg ↔ lbs) 토글
/// - C) 테마 포인트 색상 커스터마이즈 (5종)
/// - K) 글자 크기 조절 (작게/보통/크게)
/// - L) 튜토리얼 "본 적 있음" 플래그
class AppSettingsService extends ChangeNotifier {
  static const String _kWeightUnit = 'settings.weightUnit.v1';
  static const String _kThemeAccent = 'settings.themeAccent.v1';
  static const String _kTextScale = 'settings.textScale.v1';
  static const String _kTutorialSeen = 'settings.tutorialSeen.v1';

  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;
  AppSettingsService._internal();

  WeightUnit _weightUnit = WeightUnit.kg;
  ThemeAccent _themeAccent = ThemeAccent.mint;
  TextScale _textScale = TextScale.normal;
  bool _tutorialSeen = false;
  bool _loaded = false;

  WeightUnit get weightUnit => _weightUnit;
  ThemeAccent get themeAccent => _themeAccent;
  TextScale get textScale => _textScale;
  bool get tutorialSeen => _tutorialSeen;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _weightUnit = _parse(
      prefs.getString(_kWeightUnit),
      WeightUnit.values,
      WeightUnit.kg,
    );
    _themeAccent = _parse(
      prefs.getString(_kThemeAccent),
      ThemeAccent.values,
      ThemeAccent.mint,
    );
    _textScale = _parse(
      prefs.getString(_kTextScale),
      TextScale.values,
      TextScale.normal,
    );
    _tutorialSeen = prefs.getBool(_kTutorialSeen) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setWeightUnit(WeightUnit v) async {
    _weightUnit = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeightUnit, v.name);
    notifyListeners();
  }

  Future<void> setThemeAccent(ThemeAccent v) async {
    _themeAccent = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeAccent, v.name);
    notifyListeners();
  }

  Future<void> setTextScale(TextScale v) async {
    _textScale = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTextScale, v.name);
    notifyListeners();
  }

  Future<void> markTutorialSeen() async {
    _tutorialSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTutorialSeen, true);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    _tutorialSeen = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTutorialSeen, false);
    notifyListeners();
  }

  /// (I) 데이터 전체 초기화 — 앱의 모든 SharedPreferences 키 삭제.
  Future<void> wipeAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _weightUnit = WeightUnit.kg;
    _themeAccent = ThemeAccent.mint;
    _textScale = TextScale.normal;
    _tutorialSeen = false;
    notifyListeners();
  }

  T _parse<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
