import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_constants.dart';

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

/// 신체 측정 기록을 백엔드 DB(FastAPI) 및 로컬(SharedPreferences)에 동기화하는 싱글톤.
/// - 온라인 시: FastAPI 백엔드 DB와 양방향 동기화
/// - 오프라인 시: 로컬 캐시 자동 폴백
class BodyRecordService extends ChangeNotifier {
  static const String _prefKey = 'body.records.v1';
  static final BodyRecordService _instance = BodyRecordService._internal();

  factory BodyRecordService() => _instance;
  BodyRecordService._internal();

  final http.Client _client = http.Client();
  List<BodyRecord>? _cache;

  Future<List<BodyRecord>> loadAll({String userId = ApiConstants.defaultUserId}) async {
    // 1. 백엔드 DB 최신 데이터 조회 시도
    try {
      final uri = Uri.parse('${ApiConstants.bodyMetrics}?userId=$userId');
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        final serverList = decoded
            .map((e) => BodyRecord.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        _cache = serverList;
        // 로컬 오프라인 캐시 갱신
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _prefKey,
          jsonEncode(serverList.map((r) => r.toJson()).toList()),
        );
        return List.unmodifiable(serverList);
      }
    } catch (_) {
      // 서버 미응답 또는 오프라인 시 로컬 캐시 폴백 진행
    }

    // 2. 메모리 캐시 확인
    if (_cache != null) return List.unmodifiable(_cache!);

    // 3. 로컬 SharedPreferences 캐시 복구
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

  Future<void> add(
    BodyRecord record, {
    String userId = ApiConstants.defaultUserId,
  }) async {
    // 1. 낙관적 UI 업데이트 (로컬 캐시 및 SharedPreferences 즉각 저장)
    final list = [...await loadAll(userId: userId)]
      ..removeWhere((r) =>
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day)
      ..add(record)
      ..sort((a, b) => b.date.compareTo(a.date));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(list.map((r) => r.toJson()).toList()),
    );
    _cache = list;
    notifyListeners();

    // 2. 백엔드 FastAPI DB로 비동기 전송
    try {
      final uri = Uri.parse(ApiConstants.bodyMetrics);
      final body = {
        'userId': userId,
        'date': record.toJson()['date'],
        if (record.weightKg != null) 'weightKg': record.weightKg,
        if (record.muscleKg != null) 'muscleKg': record.muscleKg,
        if (record.bodyFatPercent != null) 'bodyFatPercent': record.bodyFatPercent,
      };
      await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // 네트워크 장애 시 로컬 캐시로 안전 유지
    }
  }
}
