import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';
import '../../services/workout_service.dart';
import 'muscle_map_widget.dart';

/// 월간 운동 캘린더 카드.
/// GitHub 잔디 스타일 강도별 색상 + 월간 요약 통계 + 날짜 탭 상세 모달.
///
/// 구성 요소:
/// - 상단 통계 3칸 (운동한 날 / 최장 스트릭 / 총 볼륨)
/// - 월 네비게이션 (좌우 화살표, 미래 월 제한)
/// - 7열 Sun→Sat 그리드 (한국 캘린더 관례)
/// - 날짜 셀 탭 → 그 날 운동 상세 바텀시트
class MonthlyCalendarCard extends StatefulWidget {
  const MonthlyCalendarCard({super.key});

  @override
  State<MonthlyCalendarCard> createState() => _MonthlyCalendarCardState();
}

class _MonthlyCalendarCardState extends State<MonthlyCalendarCard> {
  final WorkoutService _service = WorkoutService();
  late Future<List<Workout>> _future;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _future = _service.fetchWorkouts();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    return _displayedMonth.isBefore(currentMonth);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  /// 전체 운동 기록을 날짜(연월일) 기준으로 묶는다.
  /// 하루 여러 세션이 있을 수 있으므로 `List<Workout>` 로 집계.
  Map<DateTime, List<Workout>> _groupByDay(List<Workout> workouts) {
    final map = <DateTime, List<Workout>>{};
    for (final w in workouts) {
      final key = DateTime(
          w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      (map[key] ??= <Workout>[]).add(w);
    }
    return map;
  }

  /// 오늘(또는 어제까지) 이어지는 현재 스트릭.
  int _currentStreak(Map<DateTime, List<Workout>> byDay) {
    if (byDay.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime cursor =
        byDay.containsKey(today) ? today : today.subtract(const Duration(days: 1));
    int streak = 0;
    while (byDay.containsKey(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 전체 기록에서 최장 연속 운동 일수를 찾는다.
  int _longestStreak(Map<DateTime, List<Workout>> byDay) {
    if (byDay.isEmpty) return 0;
    final sortedDays = byDay.keys.toList()..sort();
    int longest = 1;
    int current = 1;
    for (var i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  int _daysInMonth(Map<DateTime, List<Workout>> byDay) {
    return byDay.keys
        .where((d) =>
            d.year == _displayedMonth.year && d.month == _displayedMonth.month)
        .length;
  }

  double _volumeInMonth(List<Workout> workouts) {
    return workouts
        .where((w) =>
            w.workoutDate.year == _displayedMonth.year &&
            w.workoutDate.month == _displayedMonth.month)
        .fold<double>(0, (a, w) => a + w.volume);
  }

  Future<void> _showDayDetail(DateTime day, List<Workout> items) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayDetailSheet(day: day, items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Workout>>(
          future: _future,
          builder: (ctx, snap) {
            final workouts = snap.data ?? const <Workout>[];
            final byDay = _groupByDay(workouts);
            final streak = _currentStreak(byDay);
            final longest = _longestStreak(byDay);
            final monthDays = _daysInMonth(byDay);
            final monthVolume = _volumeInMonth(workouts);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(streak: streak, accent: accent),
                const SizedBox(height: 14),
                _SummaryRow(
                  monthDays: monthDays,
                  longest: longest,
                  monthVolume: monthVolume,
                  accent: accent,
                ),
                const SizedBox(height: 18),
                _MonthNav(
                  displayedMonth: _displayedMonth,
                  canGoNext: _canGoNext,
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                ),
                const SizedBox(height: 12),
                const _WeekdayRow(),
                const SizedBox(height: 6),
                _MonthGrid(
                  month: _displayedMonth,
                  byDay: byDay,
                  accent: accent,
                  onDayTap: _showDayDetail,
                ),
                const SizedBox(height: 10),
                const _IntensityLegend(accent: accent),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int streak;
  final Color accent;
  const _Header({required this.streak, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.calendar_month_rounded, color: accent, size: 20),
        const SizedBox(width: 8),
        const Text(
          '운동 캘린더',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '🔥 $streak일 연속',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// 월간 요약 3칸 — 운동한 날 / 최장 스트릭 / 이달 총 볼륨.
class _SummaryRow extends StatelessWidget {
  final int monthDays;
  final int longest;
  final double monthVolume;
  final Color accent;
  const _SummaryRow({
    required this.monthDays,
    required this.longest,
    required this.monthVolume,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: '이달 운동',
            value: '$monthDays',
            suffix: '일',
            color: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: '최장 스트릭',
            value: '$longest',
            suffix: '일',
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: '이달 볼륨',
            value: NumberFormat('#,###').format(monthVolume.round()),
            suffix: 'kg',
            color: const Color(0xFF60A5FA),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1116),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

class _MonthNav extends StatelessWidget {
  final DateTime displayedMonth;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthNav({
    required this.displayedMonth,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        DateFormat('yyyy년 M월', 'ko_KR').format(displayedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white70),
          onPressed: onPrev,
          tooltip: '이전 월',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: canGoNext ? Colors.white70 : Colors.white24,
          ),
          onPressed: canGoNext ? onNext : null,
          tooltip: '다음 월',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: labels.asMap().entries.map((e) {
        final isWeekend = e.key == 0 || e.key == 6;
        return Expanded(
          child: Center(
            child: Text(
              e.value,
              style: TextStyle(
                color: isWeekend ? Colors.white38 : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, List<Workout>> byDay;
  final Color accent;
  final void Function(DateTime day, List<Workout> items) onDayTap;
  const _MonthGrid({
    required this.month,
    required this.byDay,
    required this.accent,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final dayNum = index - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 36));
              }
              final cellDate = DateTime(month.year, month.month, dayNum);
              final items = byDay[cellDate] ?? const <Workout>[];
              final isToday = cellDate == todayKey;
              return Expanded(
                child: _DayCell(
                  day: dayNum,
                  sessionCount: items.length,
                  isToday: isToday,
                  isWeekend: col == 0 || col == 6,
                  accent: accent,
                  onTap: items.isEmpty
                      ? null
                      : () => onDayTap(cellDate, items),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int sessionCount;
  final bool isToday;
  final bool isWeekend;
  final Color accent;
  final VoidCallback? onTap;
  const _DayCell({
    required this.day,
    required this.sessionCount,
    required this.isToday,
    required this.isWeekend,
    required this.accent,
    required this.onTap,
  });

  /// GitHub 잔디 스타일: 세션 수에 따라 민트 투명도 3단계.
  double _intensityAlpha() {
    if (sessionCount <= 0) return 0.0;
    if (sessionCount == 1) return 0.4;
    if (sessionCount == 2) return 0.7;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final hasWorkout = sessionCount > 0;
    final Color baseTextColor;
    final Color? bg;
    final Color? border;

    if (hasWorkout) {
      final alpha = _intensityAlpha();
      bg = accent.withValues(alpha: alpha);
      border = null;
      // 투명도 낮으면 흰색이 안 보이므로 상위 세션은 흰색, 1세션은 민트
      baseTextColor = sessionCount >= 2 ? Colors.white : accent;
    } else if (isToday) {
      baseTextColor = accent;
      bg = null;
      border = accent;
    } else {
      baseTextColor = isWeekend ? Colors.white38 : Colors.white70;
      bg = null;
      border = null;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 36,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border == null
                  ? null
                  : Border.all(color: border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: baseTextColor,
                fontSize: 12,
                fontWeight: hasWorkout || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// GitHub 잔디 범례 (낮음 → 높음).
class _IntensityLegend extends StatelessWidget {
  final Color accent;
  const _IntensityLegend({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '적음',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(width: 6),
        _dot(accent.withValues(alpha: 0.4)),
        const SizedBox(width: 3),
        _dot(accent.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        _dot(accent.withValues(alpha: 1.0)),
        const SizedBox(width: 6),
        const Text(
          '많음',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// 날짜 셀 탭 시 열리는 바텀시트.
/// 그 날 수행한 운동들을 세트/횟수/무게 함께 리스트로 표시.
class _DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final List<Workout> items;
  const _DayDetailSheet({required this.day, required this.items});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final dateLabel =
        DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(day);
    final totalVolume =
        items.fold<double>(0, (a, w) => a + w.volume);
    final totalSets = items.fold<int>(0, (a, w) => a + w.sets);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${items.length}세션 · $totalSets세트',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: RichText(
                  text: TextSpan(
                    text: NumberFormat('#,###').format(totalVolume.round()),
                    style: const TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(
                        text: ' kg',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _BodyPartDonut(items: items),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ExerciseRow(workout: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 그 날 운동의 부위별 볼륨을 도넛 차트로 시각화.
/// 친구가 만든 `MuscleGroup.parseFromText` 를 재사용해 종목명 자동 분류 후,
/// 10개 세부 근육을 6개 상위 그룹으로 통합한다.
class _BodyPartDonut extends StatelessWidget {
  final List<Workout> items;
  const _BodyPartDonut({required this.items});

  /// 종목명 → 부위 집합 → 볼륨 등분배.
  Map<_BodyPart, double> _aggregate() {
    final acc = <_BodyPart, double>{};
    for (final w in items) {
      final muscles = MuscleGroupExtension.parseFromText(w.exerciseName);
      if (muscles.isEmpty) continue;
      final parts = muscles.map(_toBodyPart).toSet();
      final share = w.volume / parts.length;
      for (final p in parts) {
        acc[p] = (acc[p] ?? 0) + share;
      }
    }
    return acc;
  }

  _BodyPart _toBodyPart(MuscleGroup m) {
    switch (m) {
      case MuscleGroup.chest:
        return _BodyPart.chest;
      case MuscleGroup.back:
        return _BodyPart.back;
      case MuscleGroup.shoulders:
        return _BodyPart.shoulders;
      case MuscleGroup.biceps:
      case MuscleGroup.triceps:
        return _BodyPart.arms;
      case MuscleGroup.abs:
        return _BodyPart.core;
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return _BodyPart.legs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumes = _aggregate();
    final total = volumes.values.fold<double>(0, (a, b) => a + b);

    if (total <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          '종목명에서 부위를 자동 분류하지 못했어요',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      );
    }

    final sorted = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1116),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // 도넛 차트
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    startDegreeOffset: -90,
                    sections: sorted.map((e) {
                      final percent = (e.value / total) * 100;
                      return PieChartSectionData(
                        value: e.value,
                        color: e.key.color,
                        radius: 20,
                        showTitle: percent >= 15,
                        title: '${percent.round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Center(
                  child: Text(
                    '부위',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 범례
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: sorted.map((e) {
                final percent = (e.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${percent.round()}%',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 부위별 분류용 상위 그룹 (10개 근육 → 6개 통합).
/// `stats_tab.dart` 의 `_BodyGroup` 과 동일한 분류 체계.
enum _BodyPart { chest, back, shoulders, arms, legs, core }

extension _BodyPartExtension on _BodyPart {
  String get label {
    switch (this) {
      case _BodyPart.chest:
        return '가슴';
      case _BodyPart.back:
        return '등';
      case _BodyPart.shoulders:
        return '어깨';
      case _BodyPart.arms:
        return '팔';
      case _BodyPart.legs:
        return '하체';
      case _BodyPart.core:
        return '코어';
    }
  }

  Color get color {
    switch (this) {
      case _BodyPart.chest:
        return const Color(0xFF00E5A0);
      case _BodyPart.back:
        return const Color(0xFF60A5FA);
      case _BodyPart.shoulders:
        return const Color(0xFFF59E0B);
      case _BodyPart.arms:
        return const Color(0xFFEF4444);
      case _BodyPart.legs:
        return const Color(0xFFA855F7);
      case _BodyPart.core:
        return const Color(0xFFEC4899);
    }
  }
}

class _ExerciseRow extends StatelessWidget {
  final Workout workout;
  const _ExerciseRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1116),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workout.exerciseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${workout.sets}세트 × ${workout.reps}회 · ${_fmtWeight(workout.weight)} kg',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (workout.memo != null && workout.memo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              workout.memo!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtWeight(double w) =>
      w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1);
}
