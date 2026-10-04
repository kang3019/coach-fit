import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_profile.dart';
import '../../models/workout.dart';
import '../../services/profile_service.dart';
import '../../services/workout_service.dart';

/// 홈 상단 통합 진행 스트립 (A 담당: WBS Could — 홈 대시보드 보강).
/// - 오늘 세션/볼륨
/// - 이번 주 운동일 vs 목표 4회 진행 바
/// - 현재 스트릭 상태 메시지
/// - 체중 목표 진행 (프로필에 설정된 경우만)
class HomeProgressStrip extends StatefulWidget {
  const HomeProgressStrip({super.key});

  @override
  State<HomeProgressStrip> createState() => _HomeProgressStripState();
}

class _HomeProgressStripState extends State<HomeProgressStrip> {
  final WorkoutService _workoutService = WorkoutService();
  final ProfileService _profileService = ProfileService();
  late Future<_ProgressData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _profileService.addListener(_reload);
  }

  @override
  void dispose() {
    _profileService.removeListener(_reload);
    _workoutService.dispose();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<_ProgressData> _load() async {
    final results = await Future.wait<Object>([
      _workoutService.fetchWorkouts(),
      _profileService.load(),
    ]);
    final workouts = results[0] as List<Workout>;
    final profile = results[1] as UserProfile;
    return _ProgressData(workouts: workouts, profile: profile);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProgressData>(
      future: _future,
      builder: (ctx, snap) {
        final data = snap.data;
        if (data == null) {
          return const _LoadingShell();
        }
        return _ProgressStripContent(data: data);
      },
    );
  }
}

class _ProgressData {
  final List<Workout> workouts;
  final UserProfile profile;
  _ProgressData({required this.workouts, required this.profile});
}

class _ProgressStripContent extends StatelessWidget {
  final _ProgressData data;
  const _ProgressStripContent({required this.data});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final todayWorkouts = _todayWorkouts(data.workouts);
    final weekDays = _distinctWeekdays(data.workouts);
    final streak = _currentStreak(data.workouts);
    final todayVolume =
        todayWorkouts.fold<double>(0, (a, w) => a + w.volume);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: '오늘',
                value: '${todayWorkouts.length}',
                suffix: '세션',
                sub: todayVolume > 0
                    ? '${NumberFormat('#,###').format(todayVolume.round())} kg'
                    : '시작해보세요',
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: '이번 주',
                value: '$weekDays',
                suffix: '/ 4일',
                sub: _weekMessage(weekDays),
                color: const Color(0xFF60A5FA),
                progress: (weekDays / 4).clamp(0.0, 1.0).toDouble(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: '스트릭',
                value: '$streak',
                suffix: '일 🔥',
                sub: _streakMessage(streak, data.workouts),
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        if (data.profile.weightKg != null &&
            data.profile.targetWeightKg != null) ...[
          const SizedBox(height: 10),
          _WeightTargetBar(
            current: data.profile.weightKg!,
            target: data.profile.targetWeightKg!,
          ),
        ],
      ],
    );
  }

  List<Workout> _todayWorkouts(List<Workout> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((w) {
      final d = DateTime(
          w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      return d == today;
    }).toList();
  }

  int _distinctWeekdays(List<Workout> all) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDate.add(const Duration(days: 7));
    final days = <DateTime>{};
    for (final w in all) {
      final d = DateTime(
          w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      if (!d.isBefore(weekStartDate) && d.isBefore(weekEnd)) {
        days.add(d);
      }
    }
    return days.length;
  }

  int _currentStreak(List<Workout> all) {
    final days = all
        .map((w) =>
            DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
        .toSet();
    if (days.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime cursor =
        days.contains(today) ? today : today.subtract(const Duration(days: 1));
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _weekMessage(int count) {
    if (count >= 4) return '🎉 목표 달성!';
    if (count >= 2) return '잘 가고 있어요';
    if (count == 1) return '시작 좋아요';
    return '시작해보세요';
  }

  String _streakMessage(int streak, List<Workout> all) {
    if (streak <= 0) return '오늘 시작!';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = all
        .map((w) =>
            DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
        .toSet();
    if (!days.contains(today)) {
      return '오늘 안 하면 끊김!';
    }
    return '유지 중 👏';
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final String sub;
  final Color color;
  final double? progress;
  const _StatTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.sub,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: ' $suffix',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeightTargetBar extends StatelessWidget {
  final double current;
  final double target;
  const _WeightTargetBar({required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final diff = (current - target).abs();
    final direction = current > target ? '감량' : '증량';
    // 간이 진행도: 10kg 범위 안에서 얼마나 가까워졌는지
    final maxRange = 10.0;
    final progress = (1 - (diff / maxRange)).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_outlined,
              color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '목표 체중까지 ${diff.toStringAsFixed(1)} kg $direction',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${current.toStringAsFixed(1)} → ${target.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
