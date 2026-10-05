import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../services/achievement_service.dart';
import '../services/workout_service.dart';

/// (E) 업적/뱃지 전체 화면 — 카테고리 탭 스타일.
///
/// 디자인 포인트:
/// - 상단 요약 (달성 n/13 + 진행률 바)
/// - 카테고리 탭 (전체 / 스트릭 / 볼륨 / BIG3 / 시간대 / 다양성)
/// - 큰 원형 뱃지 + 리스트 레이아웃 (잠긴 뱃지는 흑백/뭉개짐)
/// - 탭하면 상세 모달 (큰 뱃지 + 축하 메시지 + 공유)
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final WorkoutService _service = WorkoutService();
  List<Achievement>? _achievements;
  bool _error = false;
  late final TabController _tabController;

  // 전체 + 5개 카테고리 = 6개 탭
  static final List<_TabDef> _tabs = [
    const _TabDef(label: '전체', emoji: '🏆', category: null),
    for (final c in AchievementCategory.values)
      _TabDef(label: c.label, emoji: c.emoji, category: c),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _openDetail(Achievement a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AchievementDetailSheet(achievement: a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 업적 & 뱃지'),
        bottom: _achievements == null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: accent,
                labelColor: accent,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: [
                  for (final t in _tabs)
                    Tab(text: '${t.emoji} ${t.label}'),
                ],
              ),
      ),
      body: _achievements == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                for (final t in _tabs)
                  _CategoryList(
                    achievements: t.category == null
                        ? _achievements!
                        : _achievements!
                            .where((a) => a.category == t.category)
                            .toList(),
                    showSummary: t.category == null,
                    totalForSummary: _achievements!,
                    error: t.category == null ? _error : false,
                    onTap: _openDetail,
                  ),
              ],
            ),
    );
  }
}

class _TabDef {
  final String label;
  final String emoji;
  final AchievementCategory? category;
  const _TabDef({
    required this.label,
    required this.emoji,
    required this.category,
  });
}

class _CategoryList extends StatelessWidget {
  final List<Achievement> achievements;
  final bool showSummary;
  final List<Achievement> totalForSummary;
  final bool error;
  final ValueChanged<Achievement> onTap;

  const _CategoryList({
    required this.achievements,
    required this.showSummary,
    required this.totalForSummary,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        if (showSummary) ...[
          _SummaryHeader(
            unlocked: totalForSummary.where((a) => a.unlocked).length,
            total: totalForSummary.length,
            accent: accent,
          ),
          if (error)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                '백엔드 서버에 연결하지 못해 기본 업적 상태로 표시됩니다.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          const SizedBox(height: 16),
        ],
        ...achievements.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AchievementRow(
              achievement: a,
              accent: accent,
              onTap: () => onTap(a),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  final Color accent;
  const _SummaryHeader({
    required this.unlocked,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((unlocked / total) * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.2),
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: total == 0 ? 0 : unlocked / total,
                  strokeWidth: 5,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const Text('🏆', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / $total 뱃지 획득',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '전체 달성률 $percent%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _motivation(percent),
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _motivation(int percent) {
    if (percent >= 80) return '거의 다 왔어요! 레전드 등극 코앞 🚀';
    if (percent >= 50) return '꽤 쌓였네요. 꾸준히 가봐요 💪';
    if (percent >= 20) return '좋은 시작이에요. 다음 뱃지도 노려봐요 🔥';
    return '첫 뱃지부터 하나씩 모아봐요 ✨';
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;
  final Color accent;
  final VoidCallback onTap;

  const _AchievementRow({
    required this.achievement,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.unlocked;
    final color = locked ? Colors.white24 : accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF171B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? Colors.white10 : accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // 원형 뱃지
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: locked
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.3),
                          accent.withValues(alpha: 0.1),
                        ],
                      ),
                color: locked ? Colors.white10 : null,
                border: Border.all(
                  color: locked ? Colors.white12 : accent,
                  width: 2,
                ),
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 26,
                  color: locked ? Colors.white24 : null,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 텍스트 + 진행도
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            color: locked ? Colors.white54 : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!locked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
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
                        Icon(Icons.lock_outline,
                            color: Colors.white24, size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: achievement.ratio,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${achievement.progress} / ${achievement.target}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;
  const _AchievementDetailSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final locked = !achievement.unlocked;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF171B22),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          // 큰 원형 뱃지 (글로우 효과)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: locked
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.4),
                        accent.withValues(alpha: 0.1),
                      ],
                    ),
              color: locked ? Colors.white10 : null,
              border: Border.all(
                color: locked ? Colors.white12 : accent,
                width: 3,
              ),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(
              achievement.emoji,
              style: TextStyle(
                fontSize: 64,
                color: locked ? Colors.white24 : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: achievement.category.emoji == '🔥'
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                  : accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${achievement.category.emoji} ${achievement.category.label}',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            achievement.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1116),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('진행도',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    Text(
                      '${achievement.progress} / ${achievement.target}',
                      style: TextStyle(
                        color: locked ? Colors.white54 : accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: achievement.ratio,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      locked ? Colors.white38 : accent,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  locked
                      ? '목표까지 ${achievement.target - achievement.progress} 남았어요 💪'
                      : '축하합니다! 뱃지 획득 완료 🎉',
                  style: TextStyle(
                    color: locked ? Colors.white54 : accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locked
                            ? '아직 잠긴 뱃지는 공유할 수 없어요'
                            : '뱃지 공유 기능은 실기기 빌드에서 지원됩니다'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('공유'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: locked ? Colors.white38 : accent,
                    side: BorderSide(
                      color: locked ? Colors.white12 : accent,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('닫기',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
