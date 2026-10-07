import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/community_tab.dart';
import 'tabs/menu_tab.dart';

/// CoachFit 메인 네비게이션 셸 화면 (5개 탭 바)
/// 1. 홈 (Home) - 오늘의 AI 루틴 추천 및 빠른 시작
/// 2. 기록 (History) - 날짜별 운동 세트 기록 및 신체 변화
/// 3. 통계 (Stats) - 주간/월간 볼륨 차트 및 부위별 분석
/// 4. 커뮤니티 (Community) - 오운완 인증 피드 및 응원
/// 5. 메뉴 (Menu/My) - 내 프로필 및 설정
class MainNavigationScreen extends StatefulWidget {
  /// 로그인 성공 직후 전달받는 사용자 닉네임.
  /// 값이 있으면 홈 진입 시 1회 환영 스낵바가 노출됩니다.
  final String? welcomeNickname;
  const MainNavigationScreen({super.key, this.welcomeNickname});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.welcomeNickname != null && widget.welcomeNickname!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환영합니다 ${widget.welcomeNickname}님 💪'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tabs = [
      HomeTab(
        onNavigateToLog: () => _onTabSelected(1),
        onNavigateToStats: () => _onTabSelected(2),
      ),
      const HistoryTab(),
      const StatsTab(),
      const CommunityTab(),
      const MenuTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13171F),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xFF13171F),
            indicatorColor: scheme.primary.withValues(alpha: 0.2),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: scheme.primary, size: 24);
              }
              return const IconThemeData(color: Colors.white54, size: 24);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                );
              }
              return const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today_rounded),
                label: '기록',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: '커뮤니티',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '메뉴',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
