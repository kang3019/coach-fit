import 'package:flutter/material.dart';

import '../../data/exercise_guide_data.dart';

/// 종목 가이드 바텀시트.
/// 사용자가 운동 기록 카드의 info 아이콘을 누르면 띄워진다.
/// 매칭되는 가이드가 없으면 "가이드 없음" 상태로 표시.
class ExerciseGuideSheet extends StatelessWidget {
  final String exerciseName;
  const ExerciseGuideSheet({super.key, required this.exerciseName});

  static Future<void> show(BuildContext context, String exerciseName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseGuideSheet(exerciseName: exerciseName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = findExerciseGuide(exerciseName);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF151922),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (guide == null)
              _buildNoGuide(accent)
            else
              _buildGuide(guide, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGuide(Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.help_outline, color: Colors.white24, size: 56),
          const SizedBox(height: 16),
          Text(
            exerciseName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '이 종목의 가이드는 아직 준비 중이에요.\n자주 하는 종목을 먼저 등록해주시면 가이드가 추가됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
        ],
      );

  Widget _buildGuide(ExerciseGuide guide, Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(guide.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.targetMuscles,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 자세 애니메이션 GIF (gifId 있을 때만, 민권이 쓰는 CDN 재활용)
          if (guide.gifUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: const Color(0xFF0E1116),
                  child: Image.network(
                    guide.gifUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(accent),
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined,
                              color: Colors.white24, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            '자세 영상을 불러올 수 없어요',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 자세 포인트
          _buildSection(
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
            title: '올바른 자세',
            items: guide.formPoints,
          ),
          const SizedBox(height: 20),

          // 주의사항
          _buildSection(
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF59E0B),
            title: '주의할 점',
            items: guide.mistakes,
          ),
        ],
      );

  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E232C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (i < items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );
}
