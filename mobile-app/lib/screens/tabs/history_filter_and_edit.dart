import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../widgets/muscle_map_widget.dart';

/// 검색 쿼리 + 부위 필터 chip + 메모 전용 토글 바.
/// A 담당 G·I 통합. history_tab 에서 사용.
class HistoryFilterBar extends StatefulWidget {
  final String query;
  final MuscleGroup? bodyFilter;
  final bool memoOnly;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MuscleGroup?> onBodyFilterChanged;
  final VoidCallback onMemoOnlyToggle;

  const HistoryFilterBar({
    super.key,
    required this.query,
    required this.bodyFilter,
    required this.memoOnly,
    required this.onQueryChanged,
    required this.onBodyFilterChanged,
    required this.onMemoOnlyToggle,
  });

  @override
  State<HistoryFilterBar> createState() => _HistoryFilterBarState();
}

class _HistoryFilterBarState extends State<HistoryFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<MuscleGroup> _displayGroups = [
    MuscleGroup.chest,
    MuscleGroup.back,
    MuscleGroup.shoulders,
    MuscleGroup.quads,
    MuscleGroup.biceps,
  ];

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onQueryChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: '종목명 검색…',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            prefixIcon:
                const Icon(Icons.search, color: Colors.white38, size: 18),
            suffixIcon: widget.query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white38, size: 16),
                    onPressed: () {
                      _controller.clear();
                      widget.onQueryChanged('');
                    },
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF171B22),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '전체',
                selected: widget.bodyFilter == null,
                onTap: () => widget.onBodyFilterChanged(null),
                accent: accent,
              ),
              const SizedBox(width: 6),
              for (final g in _displayGroups) ...[
                _FilterChip(
                  label: g.koreanName,
                  selected: widget.bodyFilter == g,
                  onTap: () => widget.onBodyFilterChanged(g),
                  accent: accent,
                ),
                const SizedBox(width: 6),
              ],
              _FilterChip(
                label: '📝 메모만',
                selected: widget.memoOnly,
                onTap: widget.onMemoOnlyToggle,
                accent: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 운동 기록 편집 바텀시트 (B).
/// 저장 시 수정된 Workout 반환 — 호출부가 DELETE + CREATE 로 반영.
class EditWorkoutSheet extends StatefulWidget {
  final Workout original;
  const EditWorkoutSheet({super.key, required this.original});

  @override
  State<EditWorkoutSheet> createState() => _EditWorkoutSheetState();
}

class _EditWorkoutSheetState extends State<EditWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _memoCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.original.exerciseName);
    _setsCtrl = TextEditingController(text: '${widget.original.sets}');
    _repsCtrl = TextEditingController(text: '${widget.original.reps}');
    _weightCtrl = TextEditingController(
      text: widget.original.weight % 1 == 0
          ? widget.original.weight.toInt().toString()
          : widget.original.weight.toStringAsFixed(1),
    );
    _memoCtrl = TextEditingController(text: widget.original.memo ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final updated = Workout(
      userId: widget.original.userId,
      exerciseName: _nameCtrl.text.trim(),
      sets: int.parse(_setsCtrl.text),
      reps: int.parse(_repsCtrl.text),
      weight: double.parse(_weightCtrl.text),
      workoutDate: widget.original.workoutDate,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
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
            const Text(
              '운동 기록 수정',
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
              decoration: const InputDecoration(labelText: '종목'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '필수' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '세트'),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? '숫자' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _repsCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '횟수'),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? '숫자' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '무게(kg)'),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? '숫자' : null,
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
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
