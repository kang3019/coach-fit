import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../services/workout_service.dart';
import 'coaching_screen.dart';
import 'widgets/rest_timer.dart';
import 'widgets/weekly_volume_chart.dart';

typedef _HomeData = ({List<Workout> workouts, Map<String, double> weekly});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WorkoutService _service = WorkoutService();
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_HomeData> _loadAll() async {
    final results = await Future.wait([
      _service.fetchWorkouts(),
      _service.fetchWeeklyVolume(),
    ]);
    return (
      workouts: results[0] as List<Workout>,
      weekly: results[1] as Map<String, double>,
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAll();
    });
    await _future;
  }

  Future<void> _openAddSheet() async {
    final created = await showModalBottomSheet<Workout>(
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
        child: _AddWorkoutSheet(service: _service),
      ),
    );
    if (created != null) {
      _refresh();
      if (mounted) {
        RestTimerSheet.show(context, initialSeconds: 90);
      }
    }
  }

  void _openTimer() {
    RestTimerSheet.show(context, initialSeconds: 90);
  }

  void _openCoaching() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CoachingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CoachFit',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: '휴식 타이머',
            onPressed: _openTimer,
            icon: const Icon(Icons.timer_outlined),
          ),
          IconButton(
            tooltip: 'AI 코칭 받기',
            onPressed: _openCoaching,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('세트 기록'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(
                message: '서버 연결 실패\n${snap.error}',
                onRetry: _refresh,
              );
            }
            final data = snap.data!;
            final items = data.workouts;
            if (items.isEmpty) {
              return const _EmptyView();
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length + 2,
              itemBuilder: (_, i) {
                if (i == 0) return _SummaryHeader(items: items);
                if (i == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WeeklyVolumeChart(volumeByDay: data.weekly),
                  );
                }
                return _WorkoutCard(workout: items[i - 2]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final List<Workout> items;
  const _SummaryHeader({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalVolume = items.fold<double>(0, (a, w) => a + w.volume);
    final totalSets = items.fold<int>(0, (a, w) => a + w.sets);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: '누적 세션',
              value: '${items.length}',
              suffix: '건',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: '총 세트',
              value: '$totalSets',
              suffix: '세트',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: '총 볼륨',
              value: NumberFormat('#,###').format(totalVolume.round()),
              suffix: 'kg',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  const _StatTile({
    required this.label,
    required this.value,
    required this.suffix,
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
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: ' $suffix',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
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

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  const _WorkoutCard({required this.workout});

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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip('${workout.sets}세트', color: scheme.primary),
                _Chip('${workout.reps}회', color: Colors.white70),
                _Chip('${workout.weight.toStringAsFixed(1)}kg',
                    color: Colors.white70),
                _Chip('볼륨 ${workout.volume.round()}kg',
                    color: Colors.white38),
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

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, {required this.color});

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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: const [
        Icon(Icons.fitness_center, size: 48, color: Colors.white24),
        SizedBox(height: 12),
        Center(
          child: Text(
            '아직 기록이 없어요.\n오른쪽 아래 + 버튼으로 첫 세트를 남겨보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, height: 1.4),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ),
      ],
    );
  }
}

class _AddWorkoutSheet extends StatefulWidget {
  final WorkoutService service;
  const _AddWorkoutSheet({required this.service});

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _setsCtrl = TextEditingController(text: '4');
  final _repsCtrl = TextEditingController(text: '10');
  final _weightCtrl = TextEditingController(text: '20');
  final _memoCtrl = TextEditingController();
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
        workoutDate: DateTime.now(),
        memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      );
      final saved = await widget.service.createWorkout(workout);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              '오늘의 세트 기록',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '운동 종목 (예: 벤치프레스)',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '종목을 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: _setsCtrl, label: '세트'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(controller: _repsCtrl, label: '횟수'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _weightCtrl,
                    label: '무게(kg)',
                    allowDecimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '메모 (선택)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? '저장 중…' : '기록 저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool allowDecimal;
  const _NumberField({
    required this.controller,
    required this.label,
    this.allowDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '입력';
        final parsed = allowDecimal ? double.tryParse(v) : int.tryParse(v);
        if (parsed == null) return '숫자';
        if (parsed < 0) return '음수 X';
        return null;
      },
    );
  }
}
