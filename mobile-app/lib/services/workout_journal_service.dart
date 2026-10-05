import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 운동 일지 1건.
class JournalEntry {
  final DateTime date;
  final int rating;
  final String note;

  const JournalEntry({
    required this.date,
    required this.rating,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'rating': rating,
        'note': note,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) {
    final parts = (j['date'] as String).split('-');
    return JournalEntry(
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      rating: (j['rating'] as num).toInt(),
      note: j['note'] as String,
    );
  }
}

/// (G) 운동 일지 서비스 — 날짜별 컨디션(1~5) + 메모.
/// 날짜 1건만 유지 (같은 날 덮어쓰기).
class WorkoutJournalService extends ChangeNotifier {
  static const String _prefKey = 'journal.entries.v1';

  static final WorkoutJournalService _instance =
      WorkoutJournalService._internal();
  factory WorkoutJournalService() => _instance;
  WorkoutJournalService._internal();

  List<JournalEntry>? _cache;

  Future<List<JournalEntry>> loadAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) {
      _cache = [];
      return [];
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _cache = list;
      return List.unmodifiable(list);
    } catch (_) {
      _cache = [];
      return [];
    }
  }

  JournalEntry? latestOf(DateTime date) {
    if (_cache == null) return null;
    for (final e in _cache!) {
      if (e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day) {
        return e;
      }
    }
    return null;
  }

  Future<void> upsert(JournalEntry entry) async {
    final list = [...await loadAll()]
      ..removeWhere((e) =>
          e.date.year == entry.date.year &&
          e.date.month == entry.date.month &&
          e.date.day == entry.date.day)
      ..add(entry)
      ..sort((a, b) => b.date.compareTo(a.date));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    _cache = list;
    notifyListeners();
  }

  Future<void> delete(DateTime date) async {
    final list = [...await loadAll()]
      ..removeWhere((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    _cache = list;
    notifyListeners();
  }
}
