import 'package:flutter/material.dart';

import '../services/favorite_exercises_service.dart';
import '../services/workout_service.dart';
import 'widgets/common/empty_state_view.dart';

/// (F) 즐겨찾기 운동 목록 화면.
/// 저장된 즐겨찾기 + 추천 추가 (자주 하는 종목 기반).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteExercisesService _service = FavoriteExercisesService();
  final WorkoutService _workoutService = WorkoutService();
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSuggestions() async {
    try {
      final workouts = await _workoutService.fetchWorkouts();
      final freq = <String, int>{};
      for (final w in workouts) {
        freq[w.exerciseName] = (freq[w.exerciseName] ?? 0) + 1;
      }
      final sorted = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (!mounted) return;
      setState(() => _suggestions =
          sorted.take(8).map((e) => e.key).toList());
    } catch (_) {
      // 서버 미응답 시 추천 생략
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final favorites = _service.favorites.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('⭐ 즐겨찾기 운동')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            '내 즐겨찾기 (${favorites.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            const EmptyStateView(
              icon: Icons.star_outline_rounded,
              title: '아직 즐겨찾기가 없어요',
              message: '아래 추천에서 종목을 추가해보세요.',
              padding: EdgeInsets.symmetric(vertical: 24),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in favorites)
                  _Chip(
                    label: name,
                    selected: true,
                    onTap: () => _service.toggle(name),
                    accent: accent,
                  ),
              ],
            ),
          const SizedBox(height: 24),
          const Text(
            '자주 하는 운동 추천',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '운동 기록이 쌓이면 자주 하는 종목이 여기에 표시됩니다.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _suggestions)
                  _Chip(
                    label: name,
                    selected: _service.isFavorite(name),
                    onTap: () => _service.toggle(name),
                    accent: accent,
                  ),
              ],
            ),
          const SizedBox(height: 24),
          _AddCustomCard(onAdd: (name) => _service.toggle(name)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.star_rounded : Icons.add_rounded,
              size: 14,
              color: selected ? accent : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? accent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomCard extends StatefulWidget {
  final ValueChanged<String> onAdd;
  const _AddCustomCard({required this.onAdd});

  @override
  State<_AddCustomCard> createState() => _AddCustomCardState();
}

class _AddCustomCardState extends State<_AddCustomCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '직접 추가',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '종목명 입력',
                    hintStyle:
                        TextStyle(color: Colors.white38, fontSize: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submit,
                icon: Icon(Icons.add_circle, color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
