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

  /// AWS EC2 실서버 배포 시 퍼블릭 IP 또는 도메인을 기입한다.
  /// 예: '43.200.12.34' (AWS 서울 리전 EC2 퍼블릭 IP)
  static const String _ec2HostOverride = '';

  /// AWS EC2 실서버로 원터치 전환할 때 true 로 설정한다.
  static const bool useEc2Backend = false;

  static String get baseUrl {
    if (useEc2Backend && _ec2HostOverride.isNotEmpty) {
      return 'http://$_ec2HostOverride:$_backendPort';
    }

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
  static String get bodyMetrics => '$baseUrl/api/body-metrics';
  static String get profile => '$baseUrl/api/profile';
  static String get authRegister => '$baseUrl/api/auth/register';
  static String get authLogin => '$baseUrl/api/auth/login';
  static String get authMe => '$baseUrl/api/auth/me';

  static const String defaultUserId = 'user_01';
}
