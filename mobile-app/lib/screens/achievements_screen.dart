import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../services/achievement_service.dart';
import '../services/workout_service.dart';

/// (E) 업적/뱃지 전체 화면.
/// WorkoutService 에서 운동 기록 불러와 AchievementService 로 계산.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final WorkoutService _service = WorkoutService();
  List<Achievement>? _achievements;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final workouts = await _service.fetchWorkouts();
      if (!mounted) return;
      setState(
          () => _achievements = AchievementService.computeAll(workouts));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _achievements = AchievementService.computeAll(const <Workout>[]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 업적 & 뱃지')),
      body: _achievements == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(accent),
    );
  }

  Widget _buildBody(Color accent) {
    final achievements = _achievements!;
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '달성한 업적 $unlockedCount / ${achievements.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: unlockedCount / achievements.length,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(accent),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              '백엔드 서버에 연결하지 못해 기본 업적 상태로 표시됩니다.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: achievements.length,
          itemBuilder: (ctx, i) =>
              _AchievementTile(achievement: achievements[i], accent: accent),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final Color accent;
  const _AchievementTile({required this.achievement, required this.accent});

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.unlocked;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locked ? Colors.white10 : accent.withValues(alpha: 0.6),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 26,
                  color: locked ? Colors.white24 : null,
                ),
              ),
              const Spacer(),
              if (!locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '달성',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                const Icon(Icons.lock_outline,
                    color: Colors.white24, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              color: locked ? Colors.white54 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: achievement.ratio,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(
              locked ? Colors.white38 : accent,
            ),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            '${achievement.progress} / ${achievement.target}',
            style: TextStyle(
              color: locked ? Colors.white38 : accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
