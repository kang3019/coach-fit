import 'package:flutter/material.dart';

/// (J) 앱 정보 / 크레딧 화면.
/// 개발자 소개, 기술 스택, 라이선스, 저장소 링크.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('앱 정보')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text('💪', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'CoachFit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Center(
            child: Text(
              'AI 코치가 함께하는 피트니스 트래커',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'v2.0.0',
              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('👥 개발팀'),
          const _InfoCard(
            lines: [
              ('🎨 A — 모바일 Flutter 리드', '홈/통계/기록/커뮤니티/메뉴 UI, 상태 관리'),
              ('🔧 민권(B) — 백엔드 리드', 'FastAPI/PostgreSQL, AI 코치 파이프라인, 3D 근육 맵'),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('🛠 기술 스택'),
          const _InfoCard(
            lines: [
              ('Frontend', 'Flutter 3.9 / Dart / Material 3'),
              ('Backend', 'FastAPI / PostgreSQL / SQLAlchemy'),
              ('AI', 'OpenAI GPT-4o-mini + 룰베이스 하이브리드'),
              ('Chart', 'fl_chart 0.69'),
              ('State', 'ChangeNotifier (vanilla)'),
              ('Storage', 'shared_preferences + REST'),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('🔗 링크'),
          Card(
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.code,
                  title: 'GitHub 저장소',
                  subtitle: 'github.com/kang3019/coach-fit',
                  color: accent,
                ),
                const Divider(height: 1, color: Colors.white10),
                _LinkTile(
                  icon: Icons.description_outlined,
                  title: '프로젝트 문서 (WBS/ADR/Vision)',
                  subtitle: 'kang3019.github.io/coach-fit',
                  color: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('📜 오픈소스 라이선스'),
          const _InfoCard(
            lines: [
              ('Flutter', 'BSD-3-Clause'),
              ('fl_chart', 'MIT'),
              ('http', 'BSD-3-Clause'),
              ('shared_preferences', 'BSD-3-Clause'),
              ('intl', 'BSD-3-Clause'),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '© 2026 CoachFit Team\n2인 사이드 프로젝트 • 11/20 데모 발표 예정',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> lines;
  const _InfoCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < lines.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      lines[i].$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lines[i].$2,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (i < lines.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
    );
  }
}
