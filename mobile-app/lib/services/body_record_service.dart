import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 신체 측정 레코드 1건.
class BodyRecord {
  final DateTime date;
  final double? weightKg;
  final double? muscleKg;
  final double? bodyFatPercent;

  const BodyRecord({
    required this.date,
    this.weightKg,
    this.muscleKg,
    this.bodyFatPercent,
  });

  Map<String, dynamic> toJson() => {
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        if (weightKg != null) 'weightKg': weightKg,
        if (muscleKg != null) 'muscleKg': muscleKg,
        if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
      };

  factory BodyRecord.fromJson(Map<String, dynamic> json) {
    final parts = (json['date'] as String).split('-');
    return BodyRecord(
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      muscleKg: (json['muscleKg'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
    );
  }
}

/// 신체 측정 기록을 로컬에 저장하는 싱글톤 ChangeNotifier.
/// H: 신체 측정 실제 입력 (기존 dummy 데이터 교체).
///
/// 날짜별로 1건의 기록만 유지 (같은 날 재입력 시 덮어씀).
class BodyRecordService extends ChangeNotifier {
  static const String _prefKey = 'body.records.v1';
  static final BodyRecordService _instance = BodyRecordService._internal();

  factory BodyRecordService() => _instance;
  BodyRecordService._internal();

  List<BodyRecord>? _cache;

  Future<List<BodyRecord>> loadAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) {
      _cache = [];
      return [];
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => BodyRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _cache = list;
      return List.unmodifiable(list);
    } catch (_) {
      _cache = [];
      return [];
    }
  }

  Future<void> add(BodyRecord record) async {
    final list = [...await loadAll()]
      ..removeWhere((r) =>
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day)
      ..add(record)
      ..sort((a, b) => b.date.compareTo(a.date));

    final prefs = await SharedPreferences.getInstance();
    await prefs
        .setString(_prefKey, jsonEncode(list.map((r) => r.toJson()).toList()));
    _cache = list;
    notifyListeners();
  }
}
