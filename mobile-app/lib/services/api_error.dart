import 'dart:convert';

import 'package:http/http.dart' as http;

/// FastAPI 에러 응답의 `detail` 문구를 사용자에게 보여줄 메시지로 변환한다.
String apiErrorMessage(http.Response res, String fallback) {
  if (res.statusCode == 401) {
    return '로그인이 만료되었습니다. 다시 로그인해 주세요.';
  }
  try {
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
  } catch (_) {}
  return '$fallback (status=${res.statusCode})';
}
