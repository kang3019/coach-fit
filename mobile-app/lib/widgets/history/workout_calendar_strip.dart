import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';

/// 기록 탭의 주간 캘린더 날짜 스트립 (나의 기록.png 디자인)
/// - 현재 월/연도 표시
/// - 월~일 요일 및 날짜 표시, 운동 완료 날짜에 민트 점 표시
/// - 선택된 날짜는 오렌지 라운드 박스로 하이라이트
class WorkoutCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<String> completedDateKeys; // 'yyyy-MM-dd' 형식

  const WorkoutCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.completedDateKeys = const {},
  });

  @override
  Widget build(BuildContext context) {
    // 선택된 날짜가 속한 주의 월요일 구하기
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final monthLabel = DateFormat('M월 yyyy', 'ko_KR').format(selectedDate);
    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return CoachFitCard(
      padding: const EdgeInsets.all(CoachFitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월/연도 라벨 및 주간 탐색
          Row(
            children: [
              Text(
                monthLabel.split(' ')[0],
                style: const TextStyle(
                  color: CoachFitColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                monthLabel.split(' ').length > 1 ? monthLabel.split(' ')[1] : '',
                style: const TextStyle(
                  color: CoachFitColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: '이전 주',
                icon: const Icon(Icons.chevron_left_rounded, color: CoachFitColors.textSecondary, size: 20),
                onPressed: () => onDateSelected(selectedDate.subtract(const Duration(days: 7))),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: '다음 주',
                icon: const Icon(Icons.chevron_right_rounded, color: CoachFitColors.textSecondary, size: 20),
                onPressed: () => onDateSelected(selectedDate.add(const Duration(days: 7))),
              ),
            ],
          ),
          const SizedBox(height: CoachFitSpacing.lg),

          // 월~일 7개 날짜 탭
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = weekDays[index];
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final hasWorkout = completedDateKeys.contains(dateKey);
              final dayLabel = dayLabels[index];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => onDateSelected(date),
                    borderRadius: BorderRadius.circular(CoachFitRadius.medium),
                    child: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: CoachFitColors.orange,
                              borderRadius: BorderRadius.circular(CoachFitRadius.medium),
                              boxShadow: [
                                BoxShadow(
                                  color: CoachFitColors.orange.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dayLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dayLabel,
                                  style: const TextStyle(
                                    color: CoachFitColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: CoachFitColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: hasWorkout ? CoachFitColors.mint : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
