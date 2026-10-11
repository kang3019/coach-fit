import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../services/pr_service.dart';
import '../../theme/coachfit_theme.dart';
import 'muscle_map_widget.dart';

class _PrEntry {
  final String exerciseName;
  final PrResult result;
  const _PrEntry(this.exerciseName, this.result);
}

/// "오늘 운동 완료" 결과 모달: 총 시간 · 총 볼륨 · 자극 근육 · PR 요약.
class WorkoutCompleteSheet extends StatefulWidget {
  final List<Workout> todayWorkouts;
  final List<Workout> earlierHistory;
  final Duration? elapsed;

  const WorkoutCompleteSheet({
    super.key,
    required this.todayWorkouts,
    required this.earlierHistory,
    this.elapsed,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Workout> todayWorkouts,
    required List<Workout> earlierHistory,
    Duration? elapsed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: CoachFitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WorkoutCompleteSheet(
        todayWorkouts: todayWorkouts,
        earlierHistory: earlierHistory,
        elapsed: elapsed,
      ),
    );
  }

  @override
  State<WorkoutCompleteSheet> createState() => _WorkoutCompleteSheetState();
}

class _WorkoutCompleteSheetState extends State<WorkoutCompleteSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _titleScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
  );
  late final Animation<double> _countUp = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _mapFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _prFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
  );

  late final double _totalVolume =
      widget.todayWorkouts.fold<double>(0, (sum, w) => sum + w.volume);
  late final int _totalSets =
      widget.todayWorkouts.fold<int>(0, (sum, w) => sum + w.sets);
  late final int _exerciseCount =
      widget.todayWorkouts.map((w) => w.exerciseName).toSet().length;
  late final Set<MuscleGroup> _muscles = {
    for (final w in widget.todayWorkouts)
      ...MuscleGroupExtension.parseFromText(w.exerciseName),
  };
  late final List<_PrEntry> _prs = _computePrs();

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_PrEntry> _computePrs() {
    final byExercise = <String, List<Workout>>{};
    for (final w in widget.todayWorkouts) {
      byExercise.putIfAbsent(w.exerciseName, () => []).add(w);
    }
    final service = PrService();
    final entries = <_PrEntry>[];
    byExercise.forEach((name, list) {
      final maxWeight = list.reduce((a, b) => b.weight > a.weight ? b : a);
      final maxVolume = list.reduce((a, b) => b.volume > a.volume ? b : a);
      var result = service.evaluate(maxWeight, widget.earlierHistory);
      if (!result.isRecord) {
        result = service.evaluate(maxVolume, widget.earlierHistory);
      }
      if (result.isRecord) entries.add(_PrEntry(name, result));
    });
    return entries;
  }

  int get _displayMinutes {
    final elapsed = widget.elapsed;
    if (elapsed != null && elapsed.inMinutes > 0) return elapsed.inMinutes;
    return (widget.todayWorkouts.length * 3 + 10).clamp(10, 180);
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h시간' : '$h시간 ${m.toString().padLeft(2, '0')}분';
  }

  String _formatVolume(double kg) {
    final rounded = kg.round();
    final text = rounded.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    return '$text kg';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _titleScale,
              child: const Column(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 8),
                  Text(
                    '오늘 운동 완료!',
                    style: TextStyle(
                      color: CoachFitColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '수고했어요. 오늘의 결과를 확인해 보세요.',
                    style: TextStyle(
                      color: CoachFitColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AnimatedBuilder(
              animation: _countUp,
              builder: (context, _) {
                final t = _countUp.value;
                return Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer_outlined,
                        label: widget.elapsed == null ? '운동 시간(추정)' : '운동 시간',
                        value: _formatMinutes((_displayMinutes * t).round()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.fitness_center_rounded,
                        label: '총 볼륨',
                        value: _formatVolume(_totalVolume * t),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.layers_rounded,
                        label: '$_exerciseCount종목',
                        value: '${(_totalSets * t).round()}세트',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _mapFade,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CoachFitColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CoachFitColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘 자극한 근육',
                      style: TextStyle(
                        color: CoachFitColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MuscleMapWidget(activeMuscles: _muscles, height: 260),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _prFade,
              child: _PrSection(entries: _prs),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: CoachFitColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: CoachFitColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: CoachFitColors.mint, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: CoachFitColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrSection extends StatelessWidget {
  final List<_PrEntry> entries;

  const _PrSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CoachFitColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: CoachFitColors.textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '오늘은 신기록이 없었지만, 꾸준함이 가장 큰 기록이에요.',
                style: TextStyle(
                  color: CoachFitColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 신기록',
          style: TextStyle(
            color: CoachFitColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final e in entries)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CoachFitColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CoachFitColors.orange.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.exerciseName,
                        style: const TextStyle(
                          color: CoachFitColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (e.result.subtitle != null)
                        Text(
                          e.result.subtitle!,
                          style: const TextStyle(
                            color: CoachFitColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  e.result.title,
                  style: const TextStyle(
                    color: CoachFitColors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
