import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';

/// 기록 탭 상단 날짜 헤더 카드.
/// A 담당: 날짜별 요약(C) + 세션 복사(E) + 빈 날짜 복원(F) 통합.
///
/// - 선택 날짜의 세션/세트/볼륨 요약
/// - 운동이 있으면: "오늘로 복사" 버튼
/// - 운동이 없으면: 지난 비슷한 요일 복사 유도
class HistoryDayHeader extends StatelessWidget {
  final DateTime selectedDate;
  final List<Workout> workoutsOfDay;

  /// 전체 운동 기록 (요일 패턴 분석용).
  final List<Workout> allWorkouts;

  /// 오늘 날짜로 세션을 복사할 때 호출됨.
  final Future<void> Function(List<Workout> templates)? onCopyToToday;

  const HistoryDayHeader({
    super.key,
    required this.selectedDate,
    required this.workoutsOfDay,
    required this.allWorkouts,
    this.onCopyToToday,
  });

  @override
  Widget build(BuildContext context) {
    final hasWorkouts = workoutsOfDay.isNotEmpty;
    if (hasWorkouts) {
      return _FilledHeader(
        date: selectedDate,
        items: workoutsOfDay,
        onCopyToToday: onCopyToToday,
      );
    }
    return _EmptyHeader(
      date: selectedDate,
      allWorkouts: allWorkouts,
      onCopyToToday: onCopyToToday,
    );
  }
}

class _FilledHeader extends StatelessWidget {
  final DateTime date;
  final List<Workout> items;
  final Future<void> Function(List<Workout> templates)? onCopyToToday;
  const _FilledHeader({
    required this.date,
    required this.items,
    required this.onCopyToToday,
  });

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final totalSets = items.fold<int>(0, (a, w) => a + w.sets);
    final totalVolume = items.fold<double>(0, (a, w) => a + w.volume);
    final dateLabel = DateFormat('yyyy. M. d. (E)', 'ko_KR').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!_isToday && onCopyToToday != null)
                TextButton.icon(
                  onPressed: () => onCopyToToday!(items),
                  icon: const Icon(Icons.content_copy, size: 14),
                  label: const Text(
                    '오늘로 복사',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                label: '세션',
                value: '${items.length}',
                color: accent,
              ),
              const SizedBox(width: 20),
              _MiniStat(
                label: '총 세트',
                value: '$totalSets',
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 20),
              _MiniStat(
                label: '총 볼륨',
                value: NumberFormat('#,###').format(totalVolume.round()),
                suffix: 'kg',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHeader extends StatelessWidget {
  final DateTime date;
  final List<Workout> allWorkouts;
  final Future<void> Function(List<Workout> templates)? onCopyToToday;
  const _EmptyHeader({
    required this.date,
    required this.allWorkouts,
    required this.onCopyToToday,
  });

  bool get _isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cmp = DateTime(date.year, date.month, date.day);
    return cmp.isAfter(today);
  }

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 선택 날짜와 같은 요일에 운동한 가장 가까운 과거 세션을 찾는다.
  List<Workout> _findRecentSimilarWeekday() {
    final targetWeekday = date.weekday;
    // 같은 요일, 선택 날짜 이전인 기록만 필터 → 날짜 역순
    final candidates = allWorkouts.where((w) {
      final d = DateTime(
          w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      return w.workoutDate.weekday == targetWeekday &&
          d.isBefore(DateTime(date.year, date.month, date.day));
    }).toList()
      ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
    if (candidates.isEmpty) return const [];
    // 가장 최근 "같은 요일 날짜" 하루에 수행한 운동 전체 반환
    final latestDay = DateTime(
      candidates.first.workoutDate.year,
      candidates.first.workoutDate.month,
      candidates.first.workoutDate.day,
    );
    return candidates.where((w) {
      final d = DateTime(
          w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      return d == latestDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final weekdayName =
        DateFormat('EEEE', 'ko_KR').format(date);
    final dateLabel = DateFormat('yyyy. M. d. (E)', 'ko_KR').format(date);
    final similar = _findRecentSimilarWeekday();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy_rounded,
                  color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isFuture
                ? '아직 오지 않은 날이에요'
                : _isToday
                    ? '오늘 운동 아직이에요'
                    : '이 날은 운동 기록이 없어요',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (!_isFuture && similar.isNotEmpty && onCopyToToday != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onCopyToToday!(similar),
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(
                '지난 $weekdayName 운동 ${similar.length}개 오늘로 복사',
                style: const TextStyle(fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            children: [
              if (suffix != null)
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
    );
  }
}
