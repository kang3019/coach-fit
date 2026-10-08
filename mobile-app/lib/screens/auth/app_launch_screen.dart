import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/coachfit_theme.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AppLaunchScreen extends StatefulWidget {
  final bool initialLoggedIn;

  const AppLaunchScreen({super.key, required this.initialLoggedIn});

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
  bool _showWelcome = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), _finishSplash);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finishSplash() {
    if (!mounted) return;
    if (widget.initialLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
      return;
    }
    setState(() => _showWelcome = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showWelcome ? const _WelcomeView() : const _SplashView(),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('splash'),
      fit: StackFit.expand,
      children: [
        const _AmbientGlow(
          alignment: Alignment.center,
          color: CoachFitColors.orange,
        ),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: CoachFitColors.orange,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: CoachFitColors.orange.withValues(alpha: 0.28),
                      blurRadius: 44,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'CoachFit',
                style: TextStyle(
                  color: CoachFitColors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '매일 더 나은 나를 만드는 가장 똑똑한 루틴',
                style: TextStyle(color: CoachFitColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 44),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: CoachFitColors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey('welcome'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Brand(),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _AmbientGlow(
                    alignment: Alignment.center,
                    color: CoachFitColors.orange,
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Image.asset(
                        'assets/images/body_base_neutral.png',
                        fit: BoxFit.contain,
                        color: Colors.white.withValues(alpha: 0.82),
                        colorBlendMode: BlendMode.modulate,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 54,
                    right: 2,
                    child: _MetricChip(
                      icon: Icons.local_fire_department_rounded,
                      value: '12일',
                      label: '연속 운동',
                      color: CoachFitColors.orange,
                    ),
                  ),
                  const Positioned(
                    left: 2,
                    bottom: 45,
                    child: _MetricChip(
                      icon: Icons.trending_up_rounded,
                      value: '+18%',
                      label: '주간 볼륨',
                      color: CoachFitColors.mint,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'AI PERSONAL COACH',
              style: TextStyle(
                color: CoachFitColors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '내 몸의 변화를\n놓치지 마세요.',
              style: TextStyle(
                color: CoachFitColors.text,
                fontSize: 34,
                height: 1.16,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '운동 기록부터 회복 분석, 맞춤 루틴까지\n코치핏이 매일의 성장을 연결해 드려요.',
              style: TextStyle(
                color: CoachFitColors.textSoft,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('코치핏 시작하기'),
                  SizedBox(width: 7),
                  Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: TextButton.styleFrom(
                foregroundColor: CoachFitColors.textSoft,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('이미 계정이 있어요  로그인'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: CoachFitColors.orange,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 21),
          ),
        ),
        SizedBox(width: 10),
        Text(
          'CoachFit',
          style: TextStyle(
            color: CoachFitColors.text,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CoachFitColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: CoachFitColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(
              color: CoachFitColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Alignment alignment;
  final Color color;

  const _AmbientGlow({required this.alignment, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.12), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
