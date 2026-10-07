import 'package:flutter/material.dart';

/// 공용 사용자 알림 유틸.
/// SnackBar 를 통일된 디자인/위치로 띄워 조용히 실패하는 catch 블록을 줄인다.
///
/// 사용 예:
/// ```dart
/// try {
///   await service.save(...);
///   AppSnackbar.success(context, '저장되었습니다');
/// } catch (e) {
///   AppSnackbar.error(context, '저장 실패: $e');
/// }
/// ```
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _Variant.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _Variant.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _Variant.info);

  static void _show(BuildContext context, String message, _Variant variant) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(variant.icon, color: variant.foreground, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: variant.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: variant.background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: variant == _Variant.error
              ? const Duration(seconds: 4)
              : const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}

enum _Variant { success, error, info }

extension _VariantStyle on _Variant {
  IconData get icon {
    switch (this) {
      case _Variant.success:
        return Icons.check_circle_outline;
      case _Variant.error:
        return Icons.error_outline;
      case _Variant.info:
        return Icons.info_outline;
    }
  }

  Color get background {
    switch (this) {
      case _Variant.success:
        return const Color(0xFF065F46);
      case _Variant.error:
        return const Color(0xFF7F1D1D);
      case _Variant.info:
        return const Color(0xFF1E293B);
    }
  }

  Color get foreground {
    switch (this) {
      case _Variant.success:
        return const Color(0xFFD1FAE5);
      case _Variant.error:
        return const Color(0xFFFEE2E2);
      case _Variant.info:
        return const Color(0xFFE2E8F0);
    }
  }
}
