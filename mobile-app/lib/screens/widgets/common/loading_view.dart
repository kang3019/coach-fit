import 'package:flutter/material.dart';

/// 공용 로딩 인디케이터.
/// 산발적으로 쓰이던 CircularProgressIndicator 를 일관된 크기/색상으로 통일.
class LoadingView extends StatelessWidget {
  final String? message;
  final double size;
  final EdgeInsetsGeometry padding;

  const LoadingView({
    super.key,
    this.message,
    this.size = 32,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
