import 'package:flutter/material.dart';
import '../../screens/ai_chat_screen.dart';
import '../../screens/coaching_screen.dart';
import '../../services/reminder_service.dart';
import '../../theme/coachfit_theme.dart';

/// CoachFit 전 화면 공통 통일 상단 헤더 (AppBar)
/// - 오렌지 볼트 로고 + 'CoachFit' 브랜드 타이틀
/// - 탭별 배지(기록, 통계, 커뮤니티, 마이) 표시 지원
/// - 알림 아이콘 및 커스텀 액션 버튼 지원
class CoachFitAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? tabTitle;
  final List<Widget>? actions;

  const CoachFitAppBar({
    super.key,
    this.tabTitle,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: const Color(0xF0090B0F),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: CoachFitColors.line),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CoachFitColors.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x42FF5A31),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            'CoachFit',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.8,
            ),
          ),
          if (tabTitle != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CoachFitColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CoachFitColors.line),
              ),
              child: Text(
                tabTitle!,
                style: const TextStyle(
                  color: CoachFitColors.mint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: actions ?? [
        // AI 코치 1:1 실시간 대화 버튼
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: CoachFitColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CoachFitColors.orange.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: CoachFitColors.orange, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'AI 코치',
                    style: TextStyle(
                      color: CoachFitColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CoachFitColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CoachFitColors.line),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: CoachFitColors.textSoft,
              size: 20,
            ),
            onPressed: () => _showNotificationSheet(context),
          ),
        ),
      ],
    );
  }

  void _showNotificationSheet(BuildContext context) {
    final reminder = ReminderService();
    showModalBottomSheet(
      context: context,
      backgroundColor: CoachFitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '알림 센터',
                    style: TextStyle(
                      color: CoachFitColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: CoachFitColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CoachFitColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: CoachFitColors.orange, size: 20),
                ),
                title: const Text(
                  '오늘의 AI 코칭 리포트 준비 완료',
                  style: TextStyle(
                    color: CoachFitColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  '최근 운동 볼륨과 신체 지표를 바탕으로 맞춤 루틴이 구성되었습니다.',
                  style: TextStyle(color: CoachFitColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: CoachFitColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CoachingScreen()),
                  );
                },
              ),
              const Divider(color: CoachFitColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CoachFitColors.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: CoachFitColors.mint, size: 20),
                ),
                title: Text(
                  '운동 리마인더 · ${reminder.enabled ? "켜짐 (${reminder.displayKorean})" : "꺼짐"}',
                  style: const TextStyle(
                    color: CoachFitColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  '마이 탭 > 운동 설정에서 리마인더 시간을 자유롭게 변경할 수 있습니다.',
                  style: TextStyle(color: CoachFitColors.textSecondary, fontSize: 12),
                ),
              ),
              const Divider(color: CoachFitColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CoachFitColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: CoachFitColors.orange, size: 20),
                ),
                title: const Text(
                  '1:1 AI 피트니스 코치 상시 대기 중',
                  style: TextStyle(
                    color: CoachFitColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  '운동 자세, 점진적 과부하, 단백질 식단을 실시간으로 질문해 보세요.',
                  style: TextStyle(color: CoachFitColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: CoachFitColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
