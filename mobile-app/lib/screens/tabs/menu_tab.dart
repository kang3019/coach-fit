import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/goal_service.dart';
import '../../services/profile_service.dart';
import '../profile_edit_screen.dart';
import '../widgets/rest_timer.dart';

/// 5. 메뉴/마이 탭 (Menu & Settings Tab)
/// - 내 신체 스펙 및 운동 목표 설정
/// - 기본 휴식 타이머 설정
/// - 백엔드 연동 상태 및 앱 정보
class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  void _openTimer(BuildContext context) {
    RestTimerSheet.show(context, initialSeconds: 90);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '메뉴 & 마이페이지',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. 사용자 프로필 카드 (A 담당: WBS 1.1.2 — 동적 바인딩 + 편집)
          const _ProfileCard(),
          const SizedBox(height: 14),

          // 2. 신체 스펙 그리드 (A 담당: WBS 1.1.2 — 저장된 신체 정보 표시)
          const _ProfileSpecGrid(),
          const SizedBox(height: 20),

          // 3. 운동 설정 섹션
          const Text(
            '운동 설정',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: Colors.white70),
                  title: const Text('기본 세트 간 휴식 시간', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Text('90초', style: TextStyle(color: Color(0xFF00E5A0), fontWeight: FontWeight.w700)),
                  onTap: () => _openTimer(context),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.fitness_center_rounded, color: Colors.white70),
                  title: const Text('무게 단위', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Text('kg (킬로그램)', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                  title: const Text('운동 리마인더 알림', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Text('오후 7:00', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3.5. 운동 목표 (A 담당: WBS 1.1.3 — AI 코칭 프롬프트 분기)
          const Text(
            '운동 목표',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const _GoalSelector(),
          const SizedBox(height: 20),

          // 4. 시스템 및 백엔드 연동 정보
          const Text(
            '시스템 및 서버 상태',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.dns_outlined, color: Color(0xFF10B981)),
                  title: Text('백엔드 서버', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('FastAPI 단일 백엔드 (포트 8000)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Text('온라인 🟢', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const Divider(height: 1, color: Colors.white10),
                const ListTile(
                  leading: Icon(Icons.storage_rounded, color: Color(0xFF60A5FA)),
                  title: Text('데이터베이스', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('PostgreSQL / SQLite 영속성', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Text('연결됨', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const Divider(height: 1, color: Colors.white10),
                const ListTile(
                  leading: Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
                  title: Text('AI 코칭 엔진', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('OpenAI GPT-4o-mini & 스마트 룰베이스 하이브리드', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white70),
                  title: const Text('앱 버전', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Text('v2.0.0', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 운동 목표(근비대 / 체지방 감량 / 근력 증가) 선택 섹션.
/// 선택값은 shared_preferences 에 저장되고, AI 코칭 호출 시
/// CoachingService 가 자동으로 불러와 백엔드 `goal` 파라미터에 반영한다.
class _GoalSelector extends StatefulWidget {
  const _GoalSelector();

  @override
  State<_GoalSelector> createState() => _GoalSelectorState();
}

class _GoalSelectorState extends State<_GoalSelector> {
  final GoalService _service = GoalService();
  WorkoutGoal? _selected;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final current = await _service.load();
    if (mounted) {
      setState(() => _selected = current);
    }
  }

  Future<void> _select(WorkoutGoal goal) async {
    setState(() => _selected = goal);
    await _service.save(goal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("목표를 '${goal.label}' (으)로 설정했어요"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return Card(
      child: Column(
        children: WorkoutGoal.values.map((goal) {
          final isSelected = _selected == goal;
          final isLast = goal == WorkoutGoal.values.last;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  _iconFor(goal),
                  color: isSelected ? accent : Colors.white70,
                ),
                title: Text(
                  goal.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  goal.aiPromptPhrase,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? accent : Colors.white24,
                  size: 20,
                ),
                onTap: () => _select(goal),
              ),
              if (!isLast) const Divider(height: 1, color: Colors.white10),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(WorkoutGoal goal) {
    switch (goal) {
      case WorkoutGoal.hypertrophy:
        return Icons.fitness_center;
      case WorkoutGoal.fatLoss:
        return Icons.local_fire_department;
      case WorkoutGoal.strength:
        return Icons.bolt;
    }
  }
}

class _SpecColumn extends StatelessWidget {
  final String label;
  final String value;
  const _SpecColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 저장된 사용자 프로필을 메뉴 상단에 표시하고,
/// 탭하면 ProfileEditScreen 으로 이동한다. ProfileService 리스너로
/// 다른 화면에서 저장돼도 자동 갱신된다.
class _ProfileCard extends StatefulWidget {
  const _ProfileCard();

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  final ProfileService _service = ProfileService();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onProfileChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    _service.removeListener(_onProfileChanged);
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final p = await _service.load();
    if (mounted) setState(() => _profile = p);
  }

  void _onProfileChanged() => _loadInitial();

  Future<void> _openEdit() async {
    final current = _profile ?? await _service.load();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(initial: current),
      ),
    );
    // save() 가 ProfileService.notifyListeners() 를 호출하므로 자동 갱신됨
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = _profile ?? UserProfile.defaultProfile();
    return Card(
      child: InkWell(
        onTap: _openEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primary.withValues(alpha: 0.2),
                child: const Text('💪', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${profile.nickname} 회원님',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.experience.label.toUpperCase(),
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.gender.label} · ${profile.experience.description}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '프로필 편집하려면 탭',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 저장된 신장/체중/목표 체중/경력을 보여주는 그리드.
/// 값이 비어있으면 `-` 로 fallback.
class _ProfileSpecGrid extends StatefulWidget {
  const _ProfileSpecGrid();

  @override
  State<_ProfileSpecGrid> createState() => _ProfileSpecGridState();
}

class _ProfileSpecGridState extends State<_ProfileSpecGrid> {
  final ProfileService _service = ProfileService();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _service.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _service.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final p = await _service.load();
    if (mounted) setState(() => _profile = p);
  }

  String _fmt(double? v, String unit) =>
      v == null ? '-' : (v % 1 == 0 ? '${v.toInt()} $unit' : '${v.toStringAsFixed(1)} $unit');

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? UserProfile.defaultProfile();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SpecColumn(label: '키', value: _fmt(profile.heightCm, 'cm')),
          _SpecColumn(label: '체중', value: _fmt(profile.weightKg, 'kg')),
          _SpecColumn(label: '목표', value: _fmt(profile.targetWeightKg, 'kg')),
          _SpecColumn(label: '경력', value: profile.experience.label),
        ],
      ),
    );
  }
}
