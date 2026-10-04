import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';
import '../../services/workout_service.dart';

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
    const accent = Color(0xFF00E5A0);
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
                    color: const Color(0xFF0E1116),
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
                        onPressed: widget.onStartRecording,
                        style: TextButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        child: const Text(
                          '기록하러',
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
