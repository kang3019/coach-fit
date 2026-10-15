import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';
import '../../services/workout_events.dart';
import '../../services/workout_service.dart';
import '../../theme/coachfit_theme.dart';

/// 마지막 운동 복습 + progressive overload (+2.5kg) 추천 카드.
/// A 담당: WBS Could — 홈 "복습 & 도전" 섹션.
///
/// 가장 최근 운동 기록을 가져와서, 같은 종목으로 +2.5kg 도전을
/// 유도한다. 보디빌딩 핵심 원리인 점진적 과부하 모델링.
class LastWorkoutCard extends StatefulWidget {
  final VoidCallback? onStartRecording;
  const LastWorkoutCard({super.key, this.onStartRecording});

  @override
  State<LastWorkoutCard> createState() => _LastWorkoutCardState();
}

class _LastWorkoutCardState extends State<LastWorkoutCard> {
  final WorkoutService _service = WorkoutService();
  late Future<List<Workout>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchWorkouts();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = CoachFitColors.mint;
    return FutureBuilder<List<Workout>>(
      future: _future,
      builder: (ctx, snap) {
        final list = snap.data ?? const <Workout>[];
        if (list.isEmpty) {
          return _EmptyCard();
        }
        // 가장 최근 세션 (DB 조회 결과가 이미 최신순이지만 안전하게 재정렬)
        final sorted = [...list]..sort((a, b) {
            final cmp = b.workoutDate.compareTo(a.workoutDate);
            if (cmp != 0) return cmp;
            final aCreated = a.createdAt;
            final bCreated = b.createdAt;
            if (aCreated == null || bCreated == null) return 0;
            return bCreated.compareTo(aCreated);
          });
        final last = sorted.first;
        final nextWeight = (last.weight + 2.5);
        final dateLabel =
            DateFormat('M월 d일 (E)', 'ko_KR').format(last.workoutDate);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, color: accent, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      '지난 운동 복습',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 지난 세션 요약
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CoachFitColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              last.exerciseName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${last.sets}세트 × ${last.reps}회 · ${_fmtWeight(last.weight)} kg',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 다음 도전
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘 도전: ${_fmtWeight(nextWeight)} kg',
                              style: TextStyle(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '점진적 과부하 +2.5 kg 적용',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _handleChallengeTap(context, last, nextWeight),
                        style: TextButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        child: const Text(
                          '도전 기록',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleChallengeTap(
    BuildContext context,
    Workout last,
    double nextWeight,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF131720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CoachFitColors.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CoachFitColors.mint.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '점진적 과부하 도전',
                    style: TextStyle(
                      color: CoachFitColors.mint,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${last.exerciseName} +2.5kg 증량 도전',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CoachFitColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CoachFitColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('지난 수행 무게', style: TextStyle(color: CoachFitColors.textMuted, fontSize: 13)),
                      Text(
                        '${_fmtWeight(last.weight)}kg (${last.sets}세트 × ${last.reps}회)',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: CoachFitColors.line, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '오늘 도전 무게 (+2.5kg)',
                        style: TextStyle(color: CoachFitColors.mint, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_fmtWeight(nextWeight)}kg (${last.sets}세트 × ${last.reps}회)',
                        style: const TextStyle(color: CoachFitColors.mint, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '안전한 중량 증량을 위해 워밍업 세트 후 본 세트에서 시도해 보세요.\n오늘 기록에 +2.5kg 증량 세트를 추가하고 운동을 시작할까요?',
              style: TextStyle(color: CoachFitColors.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoachFitColors.mint,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.fitness_center_rounded, size: 20),
                label: const Text(
                  '오늘 기록에 추가 & 바로 시작',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _service.createWorkout(Workout(
          userId: last.userId,
          exerciseName: last.exerciseName,
          sets: last.sets,
          reps: last.reps,
          weight: nextWeight,
          workoutDate: DateTime.now(),
          memo: '점진적 과부하 도전 (+2.5kg)',
        ));
        WorkoutEvents.instance.ensureSessionStarted();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: CoachFitColors.mint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('🎯 ${last.exerciseName} ${_fmtWeight(nextWeight)}kg 도전이 오늘 기록에 추가되었습니다!'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF151922),
            ),
          );
          widget.onStartRecording?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('기록 추가 실패: $e')),
          );
        }
      }
    }
  }

  String _fmtWeight(double w) =>
      w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1);
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            '첫 운동을 기록해보세요',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
