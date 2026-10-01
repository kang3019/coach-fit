import 'package:flutter/material.dart';
import '../../models/exercise_master.dart';
import '../../services/workout_service.dart';

/// 운동 종목 선택 모달 바텀시트 (사진, 부위 필터, 검색 기능 포함)
class ExercisePickerModal extends StatefulWidget {
  final WorkoutService service;

  const ExercisePickerModal({super.key, required this.service});

  static Future<ExerciseMaster?> show(BuildContext context, {required WorkoutService service}) {
    return showModalBottomSheet<ExerciseMaster>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13171F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExercisePickerModal(service: service),
    );
  }

  @override
  State<ExercisePickerModal> createState() => _ExercisePickerModalState();
}

class _ExercisePickerModalState extends State<ExercisePickerModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = '전체';
  List<ExerciseMaster> _allExercises = [];
  List<ExerciseMaster> _filteredExercises = [];
  bool _loading = true;
  String? _error;

  static const List<String> _categories = [
    '전체',
    '가슴',
    '등',
    '하체',
    '어깨',
    '팔',
    '복근',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await widget.service.fetchExercises();
      setState(() {
        _allExercises = list;
        _loading = false;
        _applyFilter();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((item) {
        final matchCategory = _selectedCategory == '전체' || item.category == _selectedCategory;
        final matchSearch = query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            (item.englishName != null && item.englishName!.toLowerCase().contains(query)) ||
            item.targetMuscle.toLowerCase().contains(query);
        return matchCategory && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // 상단 핸들러 & 타이틀
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.fitness_center_rounded, color: Color(0xFF00E5A0), size: 20),
                          SizedBox(width: 8),
                          Text(
                            '운동 종목 선택',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 검색창
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '종목명 또는 타겟 근육 검색 (예: 벤치, 스쿼트, 광배근)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E2430),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 부위별 필터 칩
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                          _applyFilter();
                        });
                      },
                      selectedColor: scheme.primary.withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF1E2430),
                      labelStyle: TextStyle(
                        color: isSelected ? scheme.primary : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? scheme.primary : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // 운동 목록 본문
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.amber, size: 36),
                              const SizedBox(height: 8),
                              Text('운동 목록을 불러오지 못했습니다.\n$_error',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadExercises, child: const Text('다시 시도')),
                            ],
                          ),
                        )
                      : _filteredExercises.isEmpty
                          ? const Center(
                              child: Text(
                                '검색 결과가 없습니다.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _filteredExercises.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final exercise = _filteredExercises[i];
                                return _ExerciseCardTile(
                                  exercise: exercise,
                                  onTap: () => Navigator.pop(context, exercise),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _ExerciseCardTile extends StatelessWidget {
  final ExerciseMaster exercise;
  final VoidCallback onTap;

  const _ExerciseCardTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF171B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // 운동 사진 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: const Color(0xFF1F2633),
                child: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                    ? Image.network(
                        exercise.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.fitness_center, color: Colors.white24, size: 28),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.fitness_center, color: Colors.white24, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // 운동 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise.category,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (exercise.englishName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      exercise.englishName!,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '장비: ${exercise.equipment}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const Text('  •  ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                      Expanded(
                        child: Text(
                          exercise.targetMuscle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00E5A0), size: 22),
          ],
        ),
      ),
    );
  }
}
