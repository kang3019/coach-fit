import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../services/workout_service.dart';

/// 자주 하는 운동 Top 3를 보여주고 탭 시 바로 등록할 수 있는 가로 칩 열.
/// A 담당: WBS Could — 홈 "빠른 기록" 섹션.
///
/// 과거 기록에서 종목별 빈도를 계산해 Top 3 + 빠른 추가 버튼을 노출한다.
/// 칩 탭 시 해당 종목의 가장 최근 세트/횟수/무게를 그대로 복사한 workout
/// 을 생성해 저장 (원터치 기록).
class QuickRegisterRow extends StatefulWidget {
  final VoidCallback? onRegistered;
  final VoidCallback? onAddCustom;
  const QuickRegisterRow({super.key, this.onRegistered, this.onAddCustom});

  @override
  State<QuickRegisterRow> createState() => _QuickRegisterRowState();
}

class _QuickRegisterRowState extends State<QuickRegisterRow> {
  final WorkoutService _service = WorkoutService();
  late Future<List<Workout>> _future;
  String? _savingName;

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

  /// 종목별 등장 횟수 집계 후 상위 N개 반환.
  List<Workout> _topFavorites(List<Workout> all, {int limit = 3}) {
    final counts = <String, int>{};
    final latest = <String, Workout>{};
    for (final w in all) {
      counts[w.exerciseName] = (counts[w.exerciseName] ?? 0) + 1;
      final prev = latest[w.exerciseName];
      if (prev == null ||
          w.workoutDate.isAfter(prev.workoutDate) ||
          (w.workoutDate == prev.workoutDate &&
              (w.createdAt?.isAfter(prev.createdAt ?? DateTime(0)) ?? false))) {
        latest[w.exerciseName] = w;
      }
    }
    final names = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return names
        .take(limit)
        .map((e) => latest[e.key]!)
        .toList();
  }

  Future<void> _quickSave(Workout template) async {
    if (_savingName != null) return;
    setState(() => _savingName = template.exerciseName);
    try {
      final created = await _service.createWorkout(Workout(
        userId: template.userId,
        exerciseName: template.exerciseName,
        sets: template.sets,
        reps: template.reps,
        weight: template.weight,
        workoutDate: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${created.exerciseName}' 기록 완료"),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onRegistered?.call();
      setState(() => _future = _service.fetchWorkouts());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('빠른 등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return FutureBuilder<List<Workout>>(
      future: _future,
      builder: (ctx, snap) {
        final all = snap.data ?? const <Workout>[];
        final favorites = _topFavorites(all);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171B22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: accent, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    '빠른 기록',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '자주 하는 운동 Top 3',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final f in favorites) ...[
                    Expanded(
                      child: _FavoriteChip(
                        workout: f,
                        loading: _savingName == f.exerciseName,
                        onTap: () => _quickSave(f),
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 패딩용 placeholder (favorite 수가 3 미만일 때 레이아웃 유지)
                  for (var i = favorites.length; i < 3; i++) ...[
                    const Expanded(child: SizedBox()),
                    const SizedBox(width: 8),
                  ],
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: Colors.white10,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: widget.onAddCustom,
                        customBorder: const CircleBorder(),
                        child: const Icon(Icons.add, color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
              if (favorites.isEmpty) ...[
                const SizedBox(height: 6),
                const Text(
                  '아직 자주 하는 운동이 없어요. 몇 번 기록하면 여기에 노출돼요.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  final Workout workout;
  final bool loading;
  final VoidCallback onTap;
  final Color accent;
  const _FavoriteChip({
    required this.workout,
    required this.loading,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1116),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workout.exerciseName,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${workout.sets}×${workout.reps} · ${_fmt(workout.weight)}kg',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            if (loading) ...[
              const SizedBox(height: 4),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(double w) =>
      w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1);
}
