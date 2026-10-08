import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/auth/app_launch_screen.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';
import 'theme/coachfit_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await AppSettingsService().load();
  final savedUser = await AuthService.instance.loadSavedSession();
  runApp(CoachFitApp(initialLoggedIn: savedUser != null));
}

/// Fleek 벤치마킹 다크 테마.
/// 테마 포인트 색상/글자 크기는 AppSettingsService 에 바인딩되어
/// 메뉴 탭에서 변경 시 즉시 전역 반영 (A/C/K 담당).
class CoachFitApp extends StatefulWidget {
  final bool initialLoggedIn;
  const CoachFitApp({super.key, this.initialLoggedIn = false});

  @override
  State<CoachFitApp> createState() => _CoachFitAppState();
}

class _CoachFitAppState extends State<CoachFitApp> {
  final AppSettingsService _settings = AppSettingsService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final seed = _settings.themeAccent.color;
    final scale = _settings.textScale.factor;
    return MaterialApp(
      title: 'CoachFit',
      debugShowCheckedModeBanner: false,
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(ctx);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child,
        );
      },
      theme: CoachFitTheme.dark(seed),
      home: AppLaunchScreen(initialLoggedIn: widget.initialLoggedIn),
    );
  }
}
