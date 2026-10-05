import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// (F) 즐겨찾기 운동 종목 서비스.
/// 종목명(String) 기반 집합으로 관리 — 운동 기록/루틴 등록 시 UI 상단에 우선 노출.
class FavoriteExercisesService extends ChangeNotifier {
  static const String _kFavorites = 'favorites.exercises.v1';

  static final FavoriteExercisesService _instance =
      FavoriteExercisesService._internal();
  factory FavoriteExercisesService() => _instance;
  FavoriteExercisesService._internal();

  Set<String> _favorites = {};
  bool _loaded = false;

  Set<String> get favorites => Set.unmodifiable(_favorites);
  bool get loaded => _loaded;
  int get count => _favorites.length;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavorites) ?? [];
    _favorites = list.toSet();
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(String name) => _favorites.contains(name);

  Future<void> toggle(String name) async {
    if (_favorites.contains(name)) {
      _favorites.remove(name);
    } else {
      _favorites.add(name);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String name) async {
    _favorites.remove(name);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, _favorites.toList());
  }
}
