import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_master.dart';
import '../../models/workout.dart';
import '../../services/pr_service.dart';
import '../../services/workout_service.dart';
import '../exercise_growth_screen.dart';
import '../widgets/body_measurement_section.dart';
import '../widgets/exercise_guide_sheet.dart';
import '../widgets/exercise_picker_modal.dart';
import '../widgets/rest_timer.dart';
import '../widgets/history_day_header.dart';
import 'history_filter_and_edit.dart';
import 'muscle_map_widget_shim.dart';

/// 2. 기록 탭 (History & Body Measurement Tab)
/// - 날짜별 운동 세트 기록 (조회/추가/삭제)
/// - 신체 변화 (체중, 골격근량, 체지방률 추이)
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutService _workoutService = WorkoutService();
  final PrService _prService = PrService();
  late Future<List<Workout>> _workoutsFuture;

  DateTime _selectedDate = DateTime.now();

  // A 담당 추가: 검색/필터/메모 전용 토글 상태
  String _searchQuery = '';
  MuscleGroup? _bodyFilter;
  bool _memoOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _workoutsFuture = _workoutService.fetchWorkouts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workoutService.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _workoutsFuture = _workoutService.fetchWorkouts();
    });
    await _workoutsFuture;
  }

  Future<void> _openAddWorkoutSheet() async {
    // 최근 운동 기록 상위 5건을 바텀시트에 전달해 "원터치 복사" 칩으로 쓰게 한다.
    List<Workout> recent = const [];
    try {
      final loaded = await _workoutsFuture;
      recent = loaded.take(5).toList();
    } catch (_) {
      // 데이터 로드 실패 시 그냥 빈 리스트 — 복사 칩만 안 보이게 됨
    }

    if (!mounted) return;
    final created = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddWorkoutModal(
        service: _workoutService,
        initialDate: _selectedDate,
        recentWorkouts: recent,
      ),
    );

    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\'${created.exerciseName}\' 기록이 저장되었습니다.')),
      );
      _refresh();
    }
  }

  Future<void> _confirmDelete(Workout workout) async {
    if (workout.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('운동 기록 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '\'${workout.exerciseName}\' 기록을 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _workoutService.deleteWorkout(workout.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('운동 기록이 삭제되었습니다.')),
          );
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  /// A 담당 추가: 어제(또는 선택 날짜) 운동 세션을 오늘로 통째로 복사.
  Future<void> _copySessionToToday(List<Workout> templates) async {
    if (templates.isEmpty) return;
    final today = DateTime.now();
    try {
      int ok = 0;
      Workout? prWorkout;
      PrResult prResult = PrResult.none;
      for (final t in templates) {
        final created = await _workoutService.createWorkout(Workout(
          userId: t.userId,
          exerciseName: t.exerciseName,
          sets: t.sets,
          reps: t.reps,
          weight: t.weight,
          workoutDate: today,
          memo: t.memo,
        ));
        ok++;
        final history = await _workoutsFuture;
        final evaluated = _prService.evaluate(created, history);
        if (evaluated.isRecord) {
          prWorkout = created;
          prResult = evaluated;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prWorkout != null && prResult.isRecord
              ? "$ok개 복사 완료! ${prResult.title} (${prWorkout.exerciseName})"
              : '$ok개 복사 완료!'),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _selectedDate = today;
        _workoutsFuture = _workoutService.fetchWorkouts();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복사 실패: $e')),
      );
    }
  }

  /// A 담당 추가: 기존 운동 기록을 수정 (DELETE + CREATE 패턴).
  /// 백엔드 PUT API 를 신설하지 않고 클라이언트에서 처리.
  Future<void> _openEditSheet(Workout original) async {
    final updated = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditWorkoutSheet(original: original),
      ),
    );
    if (updated == null || original.id == null) return;
    try {
      await _workoutService.deleteWorkout(original.id!);
      final saved = await _workoutService.createWorkout(updated);
      final history = await _workoutsFuture;
      final pr = _prService.evaluate(saved, history);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pr.isRecord
              ? "'${saved.exerciseName}' 수정됨 · ${pr.title}"
              : "'${saved.exerciseName}' 수정 완료"),
        ),
      );
      setState(() => _workoutsFuture = _workoutService.fetchWorkouts());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e')),
      );
    }
  }

  void _openGrowthScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExerciseGrowthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '운동 & 신체 기록',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: '종목별 성장 그래프',
            onPressed: _openGrowthScreen,
            icon: const Icon(Icons.show_chart_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: scheme.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '🏋️ 날짜별 운동 기록'),
            Tab(text: '⚖️ 신체 변화'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddWorkoutSheet,
              icon: const Icon(Icons.add),
              label: const Text('세트 기록'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭 1: 날짜별 운동 기록
          _buildWorkoutsTab(scheme),

          // 탭 2: 신체 변화 추이
          _buildBodyTab(scheme),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab(ColorScheme scheme) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Workout>>(
        future: _workoutsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(
                      '기록을 불러오지 못했습니다.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(onPressed: _refresh, child: const Text('다시 시도')),
                  ],
                ),
              ),
            );
          }

          final allWorkouts = snap.data ?? [];
          final selectedDay = DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day);
          final workoutsOfDay = allWorkouts.where((w) {
            final d = DateTime(
                w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
            return d == selectedDay;
          }).toList();

          // 전체 목록에 대한 검색/필터/메모 적용 (A 담당 G·I 기능)
          final filteredList = _applyFilters(allWorkouts);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // 1. 주간 캘린더 스트립 + 네비게이션 (A 담당: 과거 주간 조회)
              _WeekNavRow(
                selectedDate: _selectedDate,
                onPrevWeek: () => setState(() =>
                    _selectedDate = _selectedDate.subtract(const Duration(days: 7))),
                onNextWeek: () {
                  final now = DateTime.now();
                  final todayEnd = DateTime(now.year, now.month, now.day);
                  final target =
                      _selectedDate.add(const Duration(days: 7));
                  if (!target.isAfter(todayEnd)) {
                    setState(() => _selectedDate = target);
                  }
                },
                onPickDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024, 1, 1),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF00E5A0),
                          onPrimary: Colors.black,
                          surface: Color(0xFF171B22),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                onJumpToToday: () =>
                    setState(() => _selectedDate = DateTime.now()),
              ),
              const SizedBox(height: 8),
              _WeeklyCalendarStrip(
                selectedDate: _selectedDate,
                workouts: allWorkouts,
                onSelectDate: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 14),

              // 2. 선택한 날짜 요약 카드 (A 담당: 세션 복사 / 빈 날짜 복원 포함)
              HistoryDayHeader(
                selectedDate: _selectedDate,
                workoutsOfDay: workoutsOfDay,
                allWorkouts: allWorkouts,
                onCopyToToday: _copySessionToToday,
              ),
              const SizedBox(height: 16),

              // 3. 검색 + 부위 필터 + 메모 토글 (A 담당 G·I)
              HistoryFilterBar(
                query: _searchQuery,
                bodyFilter: _bodyFilter,
                memoOnly: _memoOnly,
                onQueryChanged: (v) => setState(() => _searchQuery = v),
                onBodyFilterChanged: (v) =>
                    setState(() => _bodyFilter = v),
                onMemoOnlyToggle: () =>
                    setState(() => _memoOnly = !_memoOnly),
              ),
              const SizedBox(height: 12),

              // 4. 필터 결과 또는 선택 날짜 운동 리스트
              if (filteredList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      '조건에 맞는 운동 기록이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.4),
                    ),
                  ),
                )
              else
                ...filteredList.map((w) => _WorkoutItemCard(
                      key: ValueKey('card_${w.id}_${w.exerciseName}'),
                      workout: w,
                      onDelete: () => _confirmDelete(w),
                      onEdit: () => _openEditSheet(w),
                    )),
            ],
          );
        },
      ),
    );
  }

  /// 검색 쿼리 + 부위 필터 + 메모 전용 토글을 적용한 결과 반환.
  List<Workout> _applyFilters(List<Workout> all) {
    Iterable<Workout> list = all;
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((w) => w.exerciseName.toLowerCase().contains(q));
    }
    if (_bodyFilter != null) {
      list = list.where((w) {
        final groups = MuscleGroupExtension.parseFromText(w.exerciseName);
        return groups.contains(_bodyFilter);
      });
    }
    if (_memoOnly) {
      list = list.where((w) => (w.memo ?? '').trim().isNotEmpty);
    }
    return list.toList();
  }

  Widget _buildBodyTab(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: const [
        // A 담당: dummy 데이터 교체 → 실제 로컬 저장 입력 섹션
        BodyMeasurementSection(),
      ],
    );
  }

}

class _WeeklyCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<Workout> workouts;
  final ValueChanged<DateTime> onSelectDate;

  const _WeeklyCalendarStrip({
    required this.selectedDate,
    required this.workouts,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // selectedDate 가 포함된 주 (일요일 시작)를 보여준다.
    // A 담당 수정: 과거 주간 조회를 위해 "최근 7일" 하드코딩 제거.
    final weekStart =
        selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final days =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) {
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;

          final hasWorkout = workouts.any((w) =>
              w.workoutDate.year == d.year &&
              w.workoutDate.month == d.month &&
              w.workoutDate.day == d.day);

          final dayName = DateFormat('E', 'ko_KR').format(d);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelectDate(d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? scheme.primary : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? scheme.primary : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasWorkout ? const Color(0xFF00E5A0) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WorkoutItemCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const _WorkoutItemCard({
    super.key,
    required this.workout,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('MM.dd (E)', 'ko_KR').format(workout.workoutDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workout.exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ExerciseGuideSheet.show(
                      context, workout.exerciseName),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.info_outline,
                        size: 16, color: Colors.white38),
                  ),
                ),
                if (onEdit != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: Colors.white38),
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge('${workout.sets}세트', color: scheme.primary),
                _Badge('${workout.reps}회', color: Colors.white70),
                _Badge('${workout.weight.toStringAsFixed(1)}kg', color: Colors.white70),
                _Badge('볼륨 ${workout.volume.round()}kg', color: Colors.white38),
              ],
            ),
            if (workout.memo != null && workout.memo!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                workout.memo!,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 플릭 스타일 세트별 행 데이터 모델
class _SetRowItem {
  int setNumber;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  bool isCompleted = false;
  String? prevRecord;

  _SetRowItem({
    required this.setNumber,
    required double weight,
    required int reps,
    this.prevRecord,
  })  : weightCtrl = TextEditingController(
          text: weight % 1 == 0 ? weight.toInt().toString() : weight.toStringAsFixed(1),
        ),
        repsCtrl = TextEditingController(text: reps.toString());

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

class _AddWorkoutModal extends StatefulWidget {
  final WorkoutService service;
  final DateTime initialDate;
  final List<Workout> recentWorkouts;

  const _AddWorkoutModal({
    required this.service,
    required this.initialDate,
    this.recentWorkouts = const [],
  });

  @override
  State<_AddWorkoutModal> createState() => _AddWorkoutModalState();
}

class _AddWorkoutModalState extends State<_AddWorkoutModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _setsCtrl = TextEditingController(text: '4');
  final _repsCtrl = TextEditingController(text: '10');
  final _weightCtrl = TextEditingController(text: '40');
  final _memoCtrl = TextEditingController();
  ExerciseMaster? _selectedMaster;
  bool _saving = false;

  // 플릭 스타일 세트 테이블 상태
  bool _isTableMode = true; // 기본값: 플릭 스타일 세트별 테이블
  final List<_SetRowItem> _setRows = [];

  @override
  void initState() {
    super.initState();
    // 초기 3세트 기본 추가 (예: 40kg, 10회)
    _setRows.addAll([
      _SetRowItem(setNumber: 1, weight: 40.0, reps: 10),
      _SetRowItem(setNumber: 2, weight: 40.0, reps: 10),
      _SetRowItem(setNumber: 3, weight: 40.0, reps: 10),
    ]);
  }

  @override
  void dispose() {
    for (final row in _setRows) {
      row.dispose();
    }
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  /// 선택한 과거 세트의 종목/세트/횟수/무게를 폼에 자동 입력.
  void _copyFromPast(Workout w) {
    setState(() {
      _nameCtrl.text = w.exerciseName;
      _setsCtrl.text = w.sets.toString();
      _repsCtrl.text = w.reps.toString();
      _weightCtrl.text = w.weight % 1 == 0
          ? w.weight.toInt().toString()
          : w.weight.toStringAsFixed(1);
      _selectedMaster = null;

      // 테이블 모드 행도 해당 세트 수에 맞춰 재구성
      for (final row in _setRows) {
        row.dispose();
      }
      _setRows.clear();
      final count = w.sets.clamp(1, 15);
      final prevHint = '${w.weight % 1 == 0 ? w.weight.toInt() : w.weight}kg×${w.reps}회';
      for (int i = 1; i <= count; i++) {
        _setRows.add(_SetRowItem(
          setNumber: i,
          weight: w.weight,
          reps: w.reps,
          prevRecord: prevHint,
        ));
      }
    });
  }

  Future<void> _pickExercise() async {
    final picked = await ExercisePickerModal.show(context, service: widget.service);
    if (picked != null) {
      setState(() {
        _selectedMaster = picked;
        _nameCtrl.text = picked.name;
      });
    }
  }

  void _addSetRow() {
    setState(() {
      final nextNum = _setRows.length + 1;
      double lastWeight = 40.0;
      int lastReps = 10;
      String? lastPrev;
      if (_setRows.isNotEmpty) {
        lastWeight = double.tryParse(_setRows.last.weightCtrl.text) ?? 40.0;
        lastReps = int.tryParse(_setRows.last.repsCtrl.text) ?? 10;
        lastPrev = _setRows.last.prevRecord;
      }
      _setRows.add(_SetRowItem(
        setNumber: nextNum,
        weight: lastWeight,
        reps: lastReps,
        prevRecord: lastPrev,
      ));
      _setsCtrl.text = _setRows.length.toString();
    });
  }

  void _removeSetRow(int index) {
    if (_setRows.length <= 1) return;
    setState(() {
      final removed = _setRows.removeAt(index);
      removed.dispose();
      for (int i = 0; i < _setRows.length; i++) {
        _setRows[i].setNumber = i + 1;
      }
      _setsCtrl.text = _setRows.length.toString();
    });
  }

  void _toggleSetComplete(int index) {
    setState(() {
      final item = _setRows[index];
      item.isCompleted = !item.isCompleted;

      if (item.isCompleted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF151922),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF00E5A0), width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00E5A0), size: 18),
                const SizedBox(width: 8),
                Text(
                  '${item.setNumber}세트 완료! ⏱️ 60초 휴식 권장',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            action: SnackBarAction(
              label: '타이머 열기',
              textColor: const Color(0xFF00E5A0),
              onPressed: () {
                RestTimerSheet.show(context, initialSeconds: 60);
              },
            ),
          ),
        );
      }
    });
  }

  double get _totalTableVolume {
    double total = 0;
    for (final row in _setRows) {
      final w = double.tryParse(row.weightCtrl.text) ?? 0.0;
      final r = int.tryParse(row.repsCtrl.text) ?? 0;
      total += w * r;
    }
    return total;
  }

  int get _completedSetCount {
    return _setRows.where((r) => r.isCompleted).length;
  }

  void _adjustSets(int delta) {
    final current = int.tryParse(_setsCtrl.text) ?? 1;
    final next = (current + delta).clamp(1, 50);
    setState(() {
      _setsCtrl.text = next.toString();
    });
  }

  void _adjustReps(int delta) {
    final current = int.tryParse(_repsCtrl.text) ?? 1;
    final next = (current + delta).clamp(1, 100);
    setState(() {
      _repsCtrl.text = next.toString();
    });
  }

  void _adjustWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0.0;
    final next = (current + delta).clamp(0.0, 500.0);
    setState(() {
      _weightCtrl.text = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final exerciseName = _nameCtrl.text.trim();
    if (exerciseName.isEmpty) return;

    setState(() => _saving = true);

    try {
      Workout? lastCreated;
      final baseDate = widget.initialDate;

      if (_isTableMode && _setRows.isNotEmpty) {
        // 플릭 스타일 세트 테이블 기록
        final setDetailStrings = <String>[];
        for (final row in _setRows) {
          final w = double.tryParse(row.weightCtrl.text) ?? 40.0;
          final r = int.tryParse(row.repsCtrl.text) ?? 10;
          setDetailStrings.add('${row.setNumber}세트: ${w % 1 == 0 ? w.toInt() : w}kg×$r회');
        }

        final firstW = double.tryParse(_setRows.first.weightCtrl.text) ?? 40.0;
        final firstR = int.tryParse(_setRows.first.repsCtrl.text) ?? 10;
        final allSame = _setRows.every((r) {
          final w = double.tryParse(r.weightCtrl.text) ?? 40.0;
          final reps = int.tryParse(r.repsCtrl.text) ?? 10;
          return w == firstW && reps == firstR;
        });

        final userMemo = _memoCtrl.text.trim();
        final tableSummaryMemo = '[세트 상세] ${setDetailStrings.join(" / ")}${userMemo.isNotEmpty ? " • $userMemo" : ""}';

        if (allSame) {
          // 모든 세트가 동일하면 1건으로 집계하여 깔끔하게 저장
          final workout = Workout(
            userId: 'user_01',
            exerciseName: exerciseName,
            sets: _setRows.length,
            reps: firstR,
            weight: firstW,
            workoutDate: baseDate,
            memo: tableSummaryMemo,
          );
          lastCreated = await widget.service.createWorkout(workout);
        } else {
          // 점진적 과부하 등으로 세트별 무게/횟수가 다른 경우:
          // 주간 볼륨 및 통계가 100% 오차 없이 정확히 계산되도록 각 세트를 저장
          for (final row in _setRows) {
            final w = double.tryParse(row.weightCtrl.text) ?? 40.0;
            final r = int.tryParse(row.repsCtrl.text) ?? 10;
            final workout = Workout(
              userId: 'user_01',
              exerciseName: exerciseName,
              sets: 1,
              reps: r,
              weight: w,
              workoutDate: baseDate,
              memo: '${row.setNumber}/${_setRows.length}세트${userMemo.isNotEmpty ? " • $userMemo" : ""}',
            );
            lastCreated = await widget.service.createWorkout(workout);
          }
        }
      } else {
        // 간편 묶음 기록 모드
        final workout = Workout(
          userId: 'user_01',
          exerciseName: exerciseName,
          sets: int.parse(_setsCtrl.text),
          reps: int.parse(_repsCtrl.text),
          weight: double.parse(_weightCtrl.text),
          workoutDate: baseDate,
          memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
        );
        lastCreated = await widget.service.createWorkout(workout);
      }

      if (mounted) Navigator.of(context).pop(lastCreated);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(widget.initialDate);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 헤더 (날짜 및 닫기)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '새 운동 기록',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1.5. 최근 세트 원터치 복사 칩
              if (widget.recentWorkouts.isNotEmpty) ...[
                Row(
                  children: const [
                    Icon(Icons.content_copy, size: 14, color: Colors.white54),
                    SizedBox(width: 6),
                    Text(
                      '최근 세트 원터치 복사',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.touch,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.recentWorkouts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _CopyChip(
                        workout: widget.recentWorkouts[i],
                        onTap: () => _copyFromPast(widget.recentWorkouts[i]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. 운동 종목 선택기 (사전 연동 카드)
              if (_selectedMaster != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C222D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E5A0).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _selectedMaster!.imageUrl != null
                            ? Image.network(
                                _selectedMaster!.imageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.white10,
                                  child: const Icon(Icons.fitness_center, color: Colors.white54),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.white10,
                                child: const Icon(Icons.fitness_center, color: Colors.white54),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMaster!.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5A0).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _selectedMaster!.category,
                                    style: const TextStyle(
                                      color: Color(0xFF00E5A0),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_selectedMaster!.equipment} · ${_selectedMaster!.targetMuscle}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickExercise,
                        icon: const Icon(Icons.swap_horiz, size: 16, color: Color(0xFF00E5A0)),
                        label: const Text('변경', style: TextStyle(color: Color(0xFF00E5A0))),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: _pickExercise,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2430),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E5A0).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0x2200E5A0),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Icon(Icons.photo_library_outlined, color: Color(0xFF00E5A0), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '운동 종목 사전에서 선택하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '사진, 운동 부위, 장비별 22+개 종목 제공',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // 종목명 직접 입력 필드
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '운동 종목명 (직접 입력/수정)',
                  hintText: '종목명을 입력하거나 위 사전에서 선택하세요',
                  suffixIcon: _nameCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.white38),
                          onPressed: () {
                            setState(() {
                              _nameCtrl.clear();
                              _selectedMaster = null;
                            });
                          },
                        )
                      : null,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? '종목명을 입력하세요' : null,
              ),

              const SizedBox(height: 14),

              // 3. 기록 모드 전환 세그먼트 (플릭 스타일 테이블 vs 간편 묶음)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF13171F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isTableMode = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isTableMode ? const Color(0xFF00E5A0).withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isTableMode ? const Color(0xFF00E5A0) : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_rows_outlined, size: 14, color: _isTableMode ? const Color(0xFF00E5A0) : Colors.white54),
                              const SizedBox(width: 6),
                              Text(
                                '플릭 세트 테이블',
                                style: TextStyle(
                                  color: _isTableMode ? const Color(0xFF00E5A0) : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isTableMode = false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isTableMode ? const Color(0xFF00E5A0).withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_isTableMode ? const Color(0xFF00E5A0) : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_on_outlined, size: 14, color: !_isTableMode ? const Color(0xFF00E5A0) : Colors.white54),
                              const SizedBox(width: 6),
                              Text(
                                '간편 묶음 기록',
                                style: TextStyle(
                                  color: !_isTableMode ? const Color(0xFF00E5A0) : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4-A. 플릭 스타일 세트별 테이블 모드
              if (_isTableMode) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      // 테이블 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          children: const [
                            SizedBox(width: 36, child: Text('세트', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                            SizedBox(width: 8),
                            SizedBox(width: 72, child: Text('이전 기록', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11))),
                            SizedBox(width: 8),
                            Expanded(flex: 3, child: Text('kg', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                            SizedBox(width: 8),
                            Expanded(flex: 3, child: Text('회', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                            SizedBox(width: 8),
                            SizedBox(width: 36, child: Text('완료', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00E5A0), fontSize: 11, fontWeight: FontWeight.bold))),
                            SizedBox(width: 28),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 12),

                      // 세트 행 목록
                      for (int i = 0; i < _setRows.length; i++) ...[
                        _buildSetRowItem(i),
                        if (i < _setRows.length - 1) const SizedBox(height: 6),
                      ],

                      const SizedBox(height: 12),

                      // 하단 액션 및 실시간 통계 바
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addSetRow,
                            icon: const Icon(Icons.add, size: 14, color: Color(0xFF00E5A0)),
                            label: const Text('세트 추가', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF00E5A0)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5A0).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '완료 $_completedSetCount/${_setRows.length} · ${_totalTableVolume.round()}kg 볼륨',
                              style: const TextStyle(
                                color: Color(0xFF00E5A0),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 4-B. 기존 간편 묶음 기록 모드
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _setsCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: '세트'),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? '숫자' : null,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QuickBtn(label: '-1', onTap: () => _adjustSets(-1)),
                              const SizedBox(width: 4),
                              _QuickBtn(label: '+1', onTap: () => _adjustSets(1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _repsCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: '회(Reps)'),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? '숫자' : null,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QuickBtn(label: '-1', onTap: () => _adjustReps(-1)),
                              const SizedBox(width: 4),
                              _QuickBtn(label: '+1', onTap: () => _adjustReps(1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: '중량(kg)'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? '숫자' : null,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QuickBtn(label: '-5', onTap: () => _adjustWeight(-5)),
                              const SizedBox(width: 4),
                              _QuickBtn(label: '+5', onTap: () => _adjustWeight(5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('중량 퀵 조절: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    _QuickBtn(label: '-2.5', onTap: () => _adjustWeight(-2.5)),
                    const SizedBox(width: 4),
                    _QuickBtn(label: '-1', onTap: () => _adjustWeight(-1)),
                    const SizedBox(width: 4),
                    _QuickBtn(label: '+1', onTap: () => _adjustWeight(1)),
                    const SizedBox(width: 4),
                    _QuickBtn(label: '+2.5', onTap: () => _adjustWeight(2.5)),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // 5. 메모 필드
              TextFormField(
                controller: _memoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항, 자극 부위나 컨디션)',
                  hintText: '예: 마지막 세트 드롭세트 진행, 가슴 하부 자극 굿',
                ),
              ),

              const SizedBox(height: 20),

              // 6. 완료 버튼
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5A0),
                  foregroundColor: const Color(0xFF0E1116),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0E1116)))
                    : const Text('기록 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetRowItem(int index) {
    final row = _setRows[index];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: row.isCompleted ? const Color(0xFF00E5A0).withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 세트 번호 뱃지
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: row.isCompleted ? const Color(0xFF00E5A0) : const Color(0xFF1E2430),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${row.setNumber}',
              style: TextStyle(
                color: row.isCompleted ? const Color(0xFF0E1116) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 이전 기록
          SizedBox(
            width: 72,
            child: Text(
              row.prevRecord ?? '-',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // kg 입력
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 36,
              child: TextFormField(
                controller: row.weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFF1C222D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF00E5A0))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // reps 입력
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 36,
              child: TextFormField(
                controller: row.repsCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFF1C222D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF00E5A0))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 완료 체크 버튼
          InkWell(
            onTap: () => _toggleSetComplete(index),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 32,
              decoration: BoxDecoration(
                color: row.isCompleted ? const Color(0xFF00E5A0) : const Color(0xFF1E2430),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: row.isCompleted ? const Color(0xFF00E5A0) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: row.isCompleted ? const Color(0xFF0E1116) : Colors.white30,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 삭제 버튼
          SizedBox(
            width: 24,
            child: _setRows.length > 1
                ? InkWell(
                    onTap: () => _removeSetRow(index),
                    child: const Icon(Icons.close, size: 16, color: Colors.white30),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF222836),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// 과거 운동 기록을 원터치로 복사할 수 있는 작은 카드형 칩.
/// 종목명 + 세트×횟수 + 무게를 압축해서 보여준다.
/// AGENTS.md 의 포인트 악센트 민트(`#00E5A0`) 와 카드 배경(`#151922`) 톤 준수.
class _CopyChip extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  const _CopyChip({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF151922),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workout.exerciseName,
              style: const TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${workout.sets}×${workout.reps} · ${workout.weight.toStringAsFixed(workout.weight % 1 == 0 ? 0 : 1)}kg',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _WeekNavRow extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onPickDate;
  final VoidCallback onJumpToToday;

  const _WeekNavRow({
    required this.selectedDate,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onPickDate,
    required this.onJumpToToday,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    final selectedWeekStart = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final canGoNext = selectedWeekStart.isBefore(DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day));
    final isCurrentWeek = selectedWeekStart.year == currentWeekStart.year && selectedWeekStart.month == currentWeekStart.month && selectedWeekStart.day == currentWeekStart.day;
    final weekEnd = selectedWeekStart.add(const Duration(days: 6));
    final rangeLabel = selectedWeekStart.month == weekEnd.month
        ? '${selectedWeekStart.year}년 ${selectedWeekStart.month}월 ${selectedWeekStart.day} ~ ${weekEnd.day}일'
        : '${selectedWeekStart.year}년 ${selectedWeekStart.month}.${selectedWeekStart.day} ~ ${weekEnd.month}.${weekEnd.day}';
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white70),
          onPressed: onPrevWeek,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_rounded, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text(rangeLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: canGoNext ? Colors.white70 : Colors.white24),
          onPressed: canGoNext ? onNextWeek : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
        ),
        if (!isCurrentWeek)
          TextButton(
            onPressed: onJumpToToday,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF00E5A0), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), visualDensity: VisualDensity.compact),
            child: const Text('오늘', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }
}
