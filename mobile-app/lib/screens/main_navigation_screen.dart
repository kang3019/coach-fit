import 'package:flutter/material.dart';

import '../theme/coachfit_theme.dart';
import 'tabs/community_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/stats_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final String? welcomeNickname;

  const MainNavigationScreen({super.key, this.welcomeNickname});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    HomeTab(
      onNavigateToLog: () => _selectTab(1),
      onNavigateToStats: () => _selectTab(2),
    ),
    const HistoryTab(),
    const StatsTab(),
    const CommunityTab(),
    const MenuTab(),
  ];

  @override
  void initState() {
    super.initState();
    final nickname = widget.welcomeNickname;
    if (nickname != null && nickname.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: CoachFitColors.mint,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(child: Text('$nickname님, 오늘도 함께 시작해요.')),
              ],
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      });
    }
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: CoachFitColors.surface,
          border: Border(top: BorderSide(color: CoachFitColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _NavItem(
                  label: '홈',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  selected: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _NavItem(
                  label: '기록',
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today_rounded,
                  selected: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                _NavItem(
                  label: '통계',
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart_rounded,
                  selected: _currentIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                _NavItem(
                  label: '커뮤니티',
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                  selected: _currentIndex == 3,
                  onTap: () => _selectTab(3),
                ),
                _NavItem(
                  label: '마이',
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  selected: _currentIndex == 4,
                  onTap: () => _selectTab(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: '$label 탭',
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                top: 0,
                child: Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected
                        ? CoachFitColors.orange
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? CoachFitColors.orange.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      size: 22,
                      color: selected
                          ? CoachFitColors.orange
                          : CoachFitColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? CoachFitColors.orange
                          : CoachFitColors.textMuted,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
