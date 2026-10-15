import 'package:flutter/material.dart';
import '../../models/coaching_result.dart';
import '../../models/workout.dart';
import '../../theme/coachfit_theme.dart';

/// 루틴 내 표시할 운동 종목 데이터 모델 (AI 추천 또는 기존 기록 통일)
class RoutinePreviewItem {
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weight;
  final String focus;
  final String tip;

  const RoutinePreviewItem({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.weight,
    this.focus = '',
    this.tip = '',
  });

  factory RoutinePreviewItem.fromRecommended(RecommendedRoutineItem item) {
    return RoutinePreviewItem(
      exerciseName: item.exerciseName,
      sets: item.sets,
      reps: item.reps,
      focus: item.focus,
      tip: item.tip,
    );
  }

  factory RoutinePreviewItem.fromWorkout(Workout w) {
    return RoutinePreviewItem(
      exerciseName: w.exerciseName,
      sets: w.sets,
      reps: w.reps,
      weight: w.weight,
      focus: '이전 기록',
      tip: w.memo ?? '자세를 정확히 유지하세요.',
    );
  }
}

/// 추천 루틴 시작 / 최근 루틴 다시 시작 시 표시되는 종합 확인 모달 (BottomSheet)
/// - 포함된 운동 목록 (종목명, 세트수, 횟수, 타겟 부위, 자세 팁)
/// - 권장 휴식 타이머 설정 (60초 / 90초 / 120초)
/// - 오늘 기록으로 일괄 등록 및 즉시 시작 CTA
class RoutineStartModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final List<RoutinePreviewItem> items;
  final Future<void> Function(int selectedTimerSeconds) onConfirm;
  final VoidCallback? onOpenFullDetail;

  const RoutineStartModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.tagColor = CoachFitColors.orange,
    required this.items,
    required this.onConfirm,
    this.onOpenFullDetail,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String tag,
    Color tagColor = CoachFitColors.orange,
    required List<RoutinePreviewItem> items,
    required Future<void> Function(int selectedTimerSeconds) onConfirm,
    VoidCallback? onOpenFullDetail,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RoutineStartModal(
        title: title,
        subtitle: subtitle,
        tag: tag,
        tagColor: tagColor,
        items: items,
        onConfirm: onConfirm,
        onOpenFullDetail: onOpenFullDetail,
      ),
    );
  }

  @override
  State<RoutineStartModal> createState() => _RoutineStartModalState();
}

class _RoutineStartModalState extends State<RoutineStartModal> {
  int _selectedTimerSeconds = 90;
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final totalSets = widget.items.fold<int>(0, (sum, item) => sum + item.sets);
    final estMinutes = (totalSets * 3.5 + 8).toInt();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 드래그 핸들
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

          // 1. 헤더: 배지 & 닫기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.tagColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  widget.tag,
                  style: TextStyle(
                    color: widget.tagColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. 루틴 제목 & 안내
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.subtitle} • 총 ${widget.items.length}개 종목 ($totalSets세트, 약 $estMinutes분)',
            style: const TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // 3. 권장 휴식 타이머 설정
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CoachFitColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CoachFitColors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: CoachFitColors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '세트 간 휴식 타이머',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...[60, 90, 120].map((sec) {
                  final isSelected = _selectedTimerSeconds == sec;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTimerSeconds = sec),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CoachFitColors.orange
                              : const Color(0xFF202634),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? CoachFitColors.orange
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          '$sec초',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. 종목 리스트 (스크롤 가능)
          const Text(
            '포함된 운동 종목',
            style: TextStyle(
              color: CoachFitColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final item = widget.items[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CoachFitColors.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CoachFitColors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: CoachFitColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.exerciseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item.weight != null && item.weight! > 0
                                      ? '${item.sets}세트 × ${item.reps}회 · ${item.weight}kg'
                                      : '${item.sets}세트 × ${item.reps}회',
                                  style: const TextStyle(
                                    color: CoachFitColors.mint,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (item.focus.isNotEmpty || item.tip.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.tip.isNotEmpty ? item.tip : item.focus,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 5. 액션 버튼: 오늘 기록에 추가 & 시작
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CoachFitColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              icon: _isStarting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                _isStarting ? '운동 세션 준비 중...' : '오늘 기록에 추가하고 운동 시작',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: _isStarting
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isStarting = true);
                      try {
                        await widget.onConfirm(_selectedTimerSeconds);
                        navigator.pop();
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _isStarting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('운동 시작 실패: $e')),
                        );
                      }
                    },
            ),
          ),

          if (widget.onOpenFullDetail != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onOpenFullDetail!();
              },
              child: const Text(
                '루틴 전체 상세 및 종목 편집 >',
                style: TextStyle(
                  color: CoachFitColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
