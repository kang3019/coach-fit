import 'package:flutter/material.dart';
import '../models/coaching_result.dart';
import '../models/exercise_master.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import 'widgets/exercise_picker_modal.dart';
import 'widgets/muscle_map_widget.dart';

/// 루틴 내 포함된 운동 종목 모델
class RoutineExerciseItem {
  final String name;
  final String targetMuscle;
  final String? imageUrl;
  final int sets;
  final int reps;

  RoutineExerciseItem({
    required this.name,
    required this.targetMuscle,
    this.imageUrl,
    this.sets = 4,
    this.reps = 10,
  });
}

/// 플릭(Fleek) 스타일 루틴 상세 및 시작 화면
/// - 상단 3D 인체 전면/후면 근육 지도 (루틴 종목에 따라 타겟 근육 실시간 하이라이트)
/// - 3D 렌더 그래픽 운동 종목 리스트
/// - 하단 고정 액션 바: [▶ 시작] (오렌지) & [+ 운동 추가] (화이트)
class RoutineDetailScreen extends StatefulWidget {
  final String title;
  final List<RoutineExerciseItem> initialExercises;
  final VoidCallback? onStartWorkout;

  const RoutineDetailScreen({
    super.key,
    this.title = '헬스 초보 무분할 루틴',
    required this.initialExercises,
    this.onStartWorkout,
  });

  /// AI 코칭 결과로부터 RoutineDetailScreen 생성 편의 팩토리
  factory RoutineDetailScreen.fromCoachingResult(
    CoachingResult result, {
    String? title,
    VoidCallback? onStartWorkout,
  }) {
    final exercises = result.recommendedRoutine.map((item) {
      return RoutineExerciseItem(
        name: item.exerciseName,
        targetMuscle: item.focus,
        sets: item.sets > 0 ? item.sets : 4,
        reps: item.reps > 0 ? item.reps : 10,
      );
    }).toList();

    return RoutineDetailScreen(
      title: title ?? 'AI 맞춤 오늘 추천 루틴',
      initialExercises: exercises,
      onStartWorkout: onStartWorkout,
    );
  }

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late List<RoutineExerciseItem> _exercises;
  final WorkoutService _workoutService = WorkoutService();
  bool _starting = false;
  Map<String, ExerciseMaster> _masterCache = {};
  MuscleGroup? _selectedMuscle;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.initialExercises);
    _loadMasters();
  }

  @override
  void dispose() {
    _workoutService.dispose();
    super.dispose();
  }

  Future<void> _loadMasters() async {
    try {
      final list = await _workoutService.fetchExercises();
      if (!mounted) return;
      setState(() {
        _masterCache = {for (final e in list) e.name: e};
        // 초기 운동들의 이미지 URL 보강
        _exercises = _exercises.map((item) {
          if (item.imageUrl == null && _masterCache.containsKey(item.name)) {
            final m = _masterCache[item.name]!;
            return RoutineExerciseItem(
              name: item.name,
              targetMuscle: m.targetMuscle,
              imageUrl: m.imageUrl,
              sets: item.sets,
              reps: item.reps,
            );
          }
          return item;
        }).toList();
      });
    } catch (_) {}
  }

  /// 현재 루틴에 포함된 운동들의 모든 타겟 근육 추출
  Set<MuscleGroup> _calculateActiveMuscles() {
    final active = <MuscleGroup>{};
    for (final item in _exercises) {
      active.addAll(MuscleGroupExtension.parseFromText('${item.name} ${item.targetMuscle}'));
    }
    return active;
  }

  /// [+ 운동 추가] 버튼 동작: 사진/3D 사전 모달 열기
  Future<void> _addExercise() async {
    final picked = await ExercisePickerModal.show(context, service: _workoutService);
    if (picked != null && mounted) {
      setState(() {
        _exercises.add(RoutineExerciseItem(
          name: picked.name,
          targetMuscle: picked.targetMuscle,
          imageUrl: picked.imageUrl,
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'${picked.name}\' 종목이 루틴에 추가되었습니다!'),
          backgroundColor: const Color(0xFFFF5722),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// [▶ 시작] 버튼 동작: 오늘 기록에 루틴 일괄 저장 및 운동 시작
  Future<void> _startWorkout() async {
    if (_starting) return;
    setState(() => _starting = true);

    try {
      final now = DateTime.now();
      for (final item in _exercises) {
        final w = Workout(
          userId: 'user_01',
          exerciseName: item.name,
          sets: item.sets,
          reps: item.reps,
          weight: 40.0,
          workoutDate: now,
          memo: '루틴 [${widget.title}] - ${item.targetMuscle}',
        );
        await _workoutService.createWorkout(w);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'${widget.title}\' (${_exercises.length}종목) 운동을 시작합니다!'),
            backgroundColor: const Color(0xFFFF5722),
          ),
        );
        if (widget.onStartWorkout != null) {
          widget.onStartWorkout!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('루틴 시작 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMuscles = _calculateActiveMuscles();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1116),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('루틴 설정 메뉴')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              // 1. 인체 근육 지도 (Front & Back Muscle Map)
              MuscleMapWidget(
                activeMuscles: activeMuscles,
                height: 350,
                selectedMuscle: _selectedMuscle,
                onSelectMuscle: (muscle) {
                  setState(() {
                    _selectedMuscle = (_selectedMuscle == muscle ? null : muscle);
                  });
                },
              ),

              const SizedBox(height: 24),

              // 2. 운동 종목 목록 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '운동 종목 (${_exercises.length}개)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '총 ${_exercises.fold<int>(0, (sum, e) => sum + e.sets)}세트',
                    style: const TextStyle(
                      color: Color(0xFFFF6A3D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. 운동 종목 리스트
              if (_exercises.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text(
                    '추가된 운동이 없습니다.\n아래 [+ 운동 추가] 버튼을 눌러보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, height: 1.5),
                  ),
                )
              else
                ..._exercises.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isTargeted = _selectedMuscle != null &&
                      MuscleGroupExtension.parseFromText('${item.name} ${item.targetMuscle}')
                          .contains(_selectedMuscle);
                  return _RoutineExerciseTile(
                    item: item,
                    isHighlighted: isTargeted,
                    onDelete: () {
                      setState(() => _exercises.removeAt(idx));
                    },
                  );
                }),
            ],
          ),

          // 4. 하단 고정 액션 바 [▶ 시작] (오렌지) & [+ 운동 추가] (화이트)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              children: [
                // [▶ 시작] 버튼 (주황/빨강)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _starting ? null : _startWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4820),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 24),
                    label: Text(
                      _starting ? '시작 중...' : '시작',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // [+ 운동 추가] 버튼 (화이트 카드)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0E1116),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF0E1116)),
                    label: const Text(
                      '운동 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
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

/// 개별 운동 종목 리스트 타일 (3D 그래픽 썸네일 + 명칭 + 자극 부위)
class _RoutineExerciseTile extends StatelessWidget {
  final RoutineExerciseItem item;
  final VoidCallback onDelete;
  final bool isHighlighted;

  const _RoutineExerciseTile({
    required this.item,
    required this.onDelete,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF221719) : const Color(0xFF151922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFF4820) : Colors.white.withValues(alpha: 0.05),
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4820).withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 3D 그래픽 썸네일 (애니메이션 GIF)
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isHighlighted ? const Color(0xFF2E1C20) : const Color(0xFF1E2430),
              borderRadius: BorderRadius.circular(12),
              border: isHighlighted
                  ? Border.all(color: const Color(0xFFFF4820).withValues(alpha: 0.4))
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white38,
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white38,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // 운동명 및 타겟 부위
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHighlighted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4820),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TARGET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.targetMuscle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 세트 수 배지 및 옵션 메뉴
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white38, size: 20),
                color: const Color(0xFF1C222E),
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('종목 삭제', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                '${item.sets}세트',
                style: const TextStyle(
                  color: Color(0xFFFF6A3D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
