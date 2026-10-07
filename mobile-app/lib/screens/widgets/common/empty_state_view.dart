import 'package:flutter/material.dart';

/// 데이터가 없을 때 보여주는 공용 빈 상태 UI.
/// 산발적으로 흩어져 있던 "아직 없어요" 메시지들을 일관된 디자인으로 통일.
///
/// 사용 예:
/// ```dart
/// const EmptyStateView(
///   icon: Icons.history,
///   title: '아직 기록이 없어요',
///   message: '오른쪽 아래 + 버튼으로 첫 세트를 남겨보세요.',
/// )
/// ```
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 56),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
