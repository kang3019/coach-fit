import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../services/workout_service.dart';

/// 상황 기반 스마트 추천 로테이션 카드.
/// A 담당: WBS Could — 홈 "조언 & 영감" 섹션.
///
/// 3가지 모드를 사용자가 좌우로 넘기면서 볼 수 있다:
///   1) 휴식 추천: 어제 고강도였으면 쉼, 오래 쉬었으면 복귀 유도
///   2) 랜덤 운동 추천: "오늘 뭐 할지 모를 때" 종목 1개 랜덤 제시
///   3) 명언 카드: 운동 동기부여 명언
class SmartSuggestionCard extends StatefulWidget {
  const SmartSuggestionCard({super.key});

  @override
  State<SmartSuggestionCard> createState() => _SmartSuggestionCardState();
}

class _SmartSuggestionCardState extends State<SmartSuggestionCard> {
  final WorkoutService _service = WorkoutService();
  late Future<List<Workout>> _future;
  int _mode = 0; // 0=휴식, 1=랜덤, 2=명언

  static const List<String> _randomExercises = [
    '푸시업 20회 × 3세트',
    '스쿼트 15회 × 3세트',
    '플랭크 60초 × 3세트',
    '버피 10회 × 3세트',
    '풀업 (어시스트 OK) 5회 × 3세트',
    '덤벨 숄더프레스 10회 × 3세트',
    '러시안 트위스트 20회 × 3세트',
    '덤벨 로우 10회 × 4세트',
  ];

  static const List<String> _quotes = [
    '"어제의 나보다 1% 더" — 꾸준함이 재능을 이긴다',
    '"고통 없이 성장도 없다" — Pain is temporary, pride is forever',
    '"오늘 흘린 땀은 내일의 자신감이 된다"',
    '"운동은 변명과 결과 사이의 선택이다"',
    '"포기하지 않는 한 실패가 아니다"',
    '"작은 반복이 큰 변화를 만든다"',
    '"몸은 네가 쉬고 있을 때도 리모델링 중"',
    '"힘든 세트가 성장을 만든다 (The last rep counts)"',
  ];

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

  void _nextMode() => setState(() => _mode = (_mode + 1) % 3);
  void _prevMode() => setState(() => _mode = (_mode + 2) % 3);

  /// 어제 운동 볼륨 기준 휴식 vs 운동 추천 메시지.
  (String title, String body) _restMessage(List<Workout> workouts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final yesterdayVol = workouts
        .where((w) {
          final d = DateTime(
              w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
          return d == yesterday;
        })
        .fold<double>(0, (a, w) => a + w.volume);

    final hasToday = workouts.any((w) {
      final d = DateTime(
          w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      return d == today;
    });

    if (hasToday) {
      return (
        '오늘 운동 완료 🎉',
        '수고했어요. 수분·단백질 섭취와 수면을 챙기면 회복이 빨라져요.'
      );
    }
    if (yesterdayVol > 10000) {
      return (
        '어제 고강도 완료 💪',
        '어제 ${yesterdayVol.round()}kg 볼륨이면 오늘 가벼운 유산소나 스트레칭도 좋아요.'
      );
    }
    final days = workouts
        .map((w) =>
            DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
        .toSet();
    DateTime cursor = today;
    int restDays = 0;
    while (!days.contains(cursor) && restDays < 14) {
      restDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    if (restDays >= 3) {
      return (
        '$restDays일째 휴식 중',
        '가볍게 복귀해요. 평소 무게의 70% 로 시작해도 충분합니다.'
      );
    }
    return (
      '오늘도 가볍게 💨',
      '컨디션 좋으면 바로 시작, 아니면 10분 산책도 OK.'
    );
  }

  String _randomExercise() {
    final rand = Random(DateTime.now().day);
    return _randomExercises[rand.nextInt(_randomExercises.length)];
  }

  String _dailyQuote() {
    // 하루 동안은 같은 명언, 날짜 바뀌면 변경
    final rand = Random(DateTime.now().day);
    return _quotes[rand.nextInt(_quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return FutureBuilder<List<Workout>>(
      future: _future,
      builder: (ctx, snap) {
        final workouts = snap.data ?? const <Workout>[];
        final (title, body) = switch (_mode) {
          0 => _restMessage(workouts),
          1 => ('오늘 뭐 할지 모르겠다면', _randomExercise()),
          _ => ('💭 오늘의 명언', _dailyQuote()),
        };
        final iconData = switch (_mode) {
          0 => Icons.spa_rounded,
          1 => Icons.casino_rounded,
          _ => Icons.format_quote_rounded,
        };

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: _prevMode,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Icon(iconData, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _mode == i ? accent : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: _nextMode,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}
