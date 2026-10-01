import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_master.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../widgets/exercise_picker_modal.dart';

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
  late Future<List<Workout>> _workoutsFuture;

  // 신체 기록 더미 상태 (실제 앱에서는 로컬/DB 연동 가능)
  final List<Map<String, dynamic>> _bodyRecords = [
    {'date': '2026-10-01', 'weight': 74.2, 'muscle': 35.8, 'fat': 15.2},
    {'date': '2026-09-24', 'weight': 74.8, 'muscle': 35.5, 'fat': 15.6},
    {'date': '2026-09-17', 'weight': 75.5, 'muscle': 35.1, 'fat': 16.2},
    {'date': '2026-09-10', 'weight': 75.9, 'muscle': 34.8, 'fat': 16.8},
  ];

  DateTime _selectedDate = DateTime.now();

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

  void _openAddBodyRecordDialog() {
    final weightCtrl = TextEditingController(text: '74.0');
    final muscleCtrl = TextEditingController(text: '35.9');
    final fatCtrl = TextEditingController(text: '15.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171B22),
        title: const Text('신체 스펙 기록', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '체중 (kg)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: muscleCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '골격근량 (kg)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fatCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '체지방률 (%)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(weightCtrl.text) ?? 74.0;
              final m = double.tryParse(muscleCtrl.text) ?? 35.0;
              final f = double.tryParse(fatCtrl.text) ?? 15.0;
              setState(() {
                _bodyRecords.insert(0, {
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'weight': w,
                  'muscle': m,
                  'fat': f,
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('신체 변화가 성공적으로 기록되었습니다!')),
              );
            },
            child: const Text('저장'),
          ),
        ],
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: scheme.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '🏋️ 날짜별 운동 기록'),
            Tab(text: '⚖️ 신체 변화 (눈바디)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _openAddWorkoutSheet();
          } else {
            _openAddBodyRecordDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? '세트 기록' : '신체 기록'),
      ),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // 1. 주간 캘린더 스트립
              _WeeklyCalendarStrip(
                selectedDate: _selectedDate,
                workouts: allWorkouts,
                onSelectDate: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 16),

              // 2. 선택한 날짜 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '총 ${allWorkouts.length}건 기록됨',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (allWorkouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      '아직 등록된 운동 기록이 없습니다.\n오른쪽 아래 + 버튼으로 기록해 보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.4),
                    ),
                  ),
                )
              else
                ...allWorkouts.map((w) => _WorkoutItemCard(
                      workout: w,
                      onDelete: () => _confirmDelete(w),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBodyTab(ColorScheme scheme) {
    final latest = _bodyRecords.first;
    final oldest = _bodyRecords.last;
    final weightDiff = (latest['weight'] as double) - (oldest['weight'] as double);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // 상단 요약 카드
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2838), Color(0xFF131822)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '최근 신체 변화 요약',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${latest['weight']} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: weightDiff <= 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: weightDiff <= 0 ? const Color(0xFF10B981) : Colors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _BodyMiniStat(label: '골격근량', value: '${latest['muscle']} kg'),
                  const SizedBox(width: 16),
                  _BodyMiniStat(label: '체지방률', value: '${latest['fat']} %'),
                  const SizedBox(width: 16),
                  const _BodyMiniStat(label: 'BMI 지수', value: '23.4 (정상)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 신체 기록 히스토리 목록
        const Text(
          '신체 측정 히스토리',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        ..._bodyRecords.map((r) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.monitor_weight_outlined, color: scheme.primary, size: 22),
                ),
                title: Text(
                  '${r['weight']} kg',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '골격근량: ${r['muscle']}kg  |  체지방률: ${r['fat']}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Text(
                  r['date'] as String,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            )),
      ],
    );
  }
}

class _BodyMiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _BodyMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
    final now = DateTime.now();
    // 최근 7일 생성
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

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

  const _WorkoutItemCard({required this.workout, required this.onDelete});

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  /// 선택한 과거 세트의 종목/세트/횟수/무게를 폼에 자동 입력.
  /// 메모는 복사하지 않음 (각 세션 상황이 다르므로).
  void _copyFromPast(Workout w) {
    setState(() {
      _nameCtrl.text = w.exerciseName;
      _setsCtrl.text = w.sets.toString();
      _repsCtrl.text = w.reps.toString();
      _weightCtrl.text = w.weight % 1 == 0
          ? w.weight.toInt().toString()
          : w.weight.toStringAsFixed(1);
      // 종목 사전 카드는 리셋 (이름이 사전 종목과 일치하지 않을 수 있으므로)
      _selectedMaster = null;
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
    setState(() => _saving = true);

    try {
      final workout = Workout(
        userId: 'user_01',
        exerciseName: _nameCtrl.text.trim(),
        sets: int.parse(_setsCtrl.text),
        reps: int.parse(_repsCtrl.text),
        weight: double.parse(_weightCtrl.text),
        workoutDate: widget.initialDate,
        memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      );

      final created = await widget.service.createWorkout(workout);
      if (mounted) Navigator.of(context).pop(created);
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

              // 1.5. 최근 세트 원터치 복사 칩 (A 담당: 간편 입력 UX)
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

              const SizedBox(height: 16),

              // 3. 세트 / 반복 / 중량 입력 및 스텝 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 세트
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

                  // 횟수
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

                  // 중량
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
              // 미세 중량 조절 칩
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

              const SizedBox(height: 14),

              // 4. 메모 필드
              TextFormField(
                controller: _memoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항, 자극 부위나 컨디션)',
                  hintText: '예: 마지막 세트 드롭세트 진행, 가슴 하부 자극 굿',
                ),
              ),

              const SizedBox(height: 20),

              // 5. 완료 버튼
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

