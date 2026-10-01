import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// FastAPI 통합 백엔드(포트 8000) 접속 URL을 실행 플랫폼별로 자동 분기한다.
///
/// - Android 에뮬레이터: 호스트 PC를 가리키는 특수 IP `10.0.2.2`
/// - iOS 시뮬레이터 / macOS / Windows / Linux 데스크톱: `localhost`
/// - 웹 (Chrome 데모): 브라우저에서 그대로 `localhost`
/// - 실기기(스마트폰): 발표 당일 노트북 IP로 교체 (예: `192.168.0.20`)
class ApiConstants {
  ApiConstants._();

  static const int _backendPort = 8000;

  /// 실기기 테스트 시 여기만 노트북 IP로 바꾸면 된다.
  /// 위험 관리 문서(04-risk-management.md)의 "발표 3일 전 실기기 검증" 대응.
  static const String _physicalDeviceHostOverride = '';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_backendPort';
    }

    if (_physicalDeviceHostOverride.isNotEmpty) {
      return 'http://$_physicalDeviceHostOverride:$_backendPort';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_backendPort';
    }

    return 'http://localhost:$_backendPort';
  }

  static String get workouts => '$baseUrl/api/workouts';
  static String get weeklyStats => '$baseUrl/api/workouts/weekly-stats';
  static String get coachingGenerate => '$baseUrl/api/coaching/generate';
  static String get exercises => '$baseUrl/api/exercises';

  static const String defaultUserId = 'user_01';

}
