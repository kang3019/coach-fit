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
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(),
                  const SizedBox(height: 64),
                  const Text(
                    'START YOUR JOURNEY',
                    style: TextStyle(
                      color: CoachFitColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '나에게 맞는 운동,\n오늘부터 시작해요.',
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
                    '목표와 운동 경험을 알려주면\nAI 코치가 첫 루틴부터 함께 준비해 드려요.',
                    style: TextStyle(
                      color: CoachFitColors.textSoft,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _FeaturePanel(),
                  const Spacer(),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: CoachFitColors.textSoft,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('이미 계정이 있어요  로그인'),
                  ),
                ],
              ),
            ),
          ),
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

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CoachFitColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoachFitColors.divider),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CoachFitColors.orange.withValues(alpha: 0.08),
            CoachFitColors.surface,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COACHFIT FEATURES',
            style: TextStyle(
              color: CoachFitColors.orange,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '운동의 시작부터 성장까지 함께해요',
            style: TextStyle(
              color: CoachFitColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _FeatureItem(
                  icon: Icons.track_changes_rounded,
                  title: '맞춤 루틴',
                  caption: '목표에 맞게',
                  color: CoachFitColors.orange,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FeatureItem(
                  icon: Icons.bar_chart_rounded,
                  title: '성장 기록',
                  caption: '변화를 한눈에',
                  color: CoachFitColors.mint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: CoachFitColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CoachFitColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: const TextStyle(
                    color: CoachFitColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
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
