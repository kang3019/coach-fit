import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/coachfit_theme.dart';
import '../main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? email, String? password}) async {
    if (email == null && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.login(
        email: email ?? _emailController.text.trim(),
        password: password ?? _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(welcomeNickname: user.nickname),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: -130,
            right: -100,
            child: _AuthGlow(color: CoachFitColors.orange, size: 330),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).vertical -
                        50,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: CoachFitColors.surface,
                              foregroundColor: CoachFitColors.textSoft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'WELCOME BACK',
                          style: TextStyle(
                            color: CoachFitColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '다시 운동을\n이어가 볼까요?',
                          style: TextStyle(
                            color: CoachFitColors.text,
                            fontSize: 32,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '저장된 기록과 오늘의 맞춤 루틴을 불러올게요.',
                          style: TextStyle(
                            color: CoachFitColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const _FieldLabel('이메일'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            hintText: 'coachfit@example.com',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return '올바른 이메일을 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('비밀번호'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) {
                            if (!_isLoading) _handleLogin();
                          },
                          decoration: InputDecoration(
                            hintText: '비밀번호를 입력해 주세요',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text('로그인'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _handleLogin(
                                  email: 'demo@coachfit.com',
                                  password: 'password123',
                                ),
                          icon: const Icon(Icons.bolt_rounded, size: 19),
                          label: const Text('데모 계정으로 바로 둘러보기'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: CoachFitColors.mint,
                            side: BorderSide(
                              color: CoachFitColors.mint.withValues(
                                alpha: 0.35,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '아직 계정이 없나요?',
                                style: TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    color: CoachFitColors.orange,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CoachFitColors.textSoft,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AuthGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.13), Colors.transparent],
        ),
      ),
    );
  }
}
