import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;

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
          // 1. 사용자 프로필 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.primary.withValues(alpha: 0.2),
                    child: Text('💪', style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              '김운동 회원님',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'LV.3',
                              style: TextStyle(
                                color: Color(0xFF00E5A0),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '운동 목표: 근비대 & 체력 증진 (주 4회)',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '식별 ID: user_01',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. 신체 스펙 그리드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SpecColumn(label: '키', value: '178 cm'),
                _SpecColumn(label: '체중', value: '74.2 kg'),
                _SpecColumn(label: '목표 체중', value: '78.0 kg'),
                _SpecColumn(label: '경력', value: '8개월'),
              ],
            ),
          ),
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
