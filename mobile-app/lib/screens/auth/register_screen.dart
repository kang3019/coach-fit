import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';

/// 짐워크(GymWork) 스타일의 대화형 인터랙티브 온보딩 화면
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 6;

  // 수집할 사용자 데이터
  String _selectedGender = 'male'; // male, female, undisclosed
  final _nicknameController = TextEditingController(text: '헬린이');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '70');
  final _targetWeightController = TextEditingController(text: '68');
  String _selectedExperience = 'beginner'; // beginner, intermediate, advanced
  String _selectedGoal = '근비대 및 전신 근력 증진';

  // 최종 계정 정보
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    // 스텝별 검증
    if (_currentStep == 1) {
      if (_nicknameController.text.trim().isEmpty) {
        setState(() => _errorMessage = '회원님의 닉네임을 입력해 주세요.');
        return;
      }
    } else if (_currentStep == 2) {
      final h = double.tryParse(_heightController.text.trim());
      final w = double.tryParse(_weightController.text.trim());
      if (h == null || h <= 50 || w == null || w <= 20) {
        setState(() => _errorMessage = '키와 체중을 올바른 숫자로 입력해 주세요.');
        return;
      }
    } else if (_currentStep == 5) {
      final email = _emailController.text.trim();
      final pwd = _passwordController.text;
      final pwdConfirm = _passwordConfirmController.text;
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _errorMessage = '올바른 이메일 주소를 입력해 주세요.');
        return;
      }
      if (pwd.length < 6) {
        setState(() => _errorMessage = '비밀번호는 최소 6자 이상이어야 합니다.');
        return;
      }
      if (pwd != pwdConfirm) {
        setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
        return;
      }
      _handleRegister();
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      final targetWeight = double.tryParse(_targetWeightController.text.trim());

      await AuthService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
        heightCm: height,
        weightKg: weight,
        targetWeightKg: targetWeight,
        experience: _selectedExperience,
        workoutGoal: _selectedGoal,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nicknameController.text.trim()}님 환영합니다! AI 맞춤 트레이닝이 준비되었습니다. 🎉'),
          backgroundColor: const Color(0xFF00E5A0),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0D14);
    const accentOrange = Color(0xFFFF4820);
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. 배경 앰비언트 글로우 (오렌지-레드 메인 컬러 악센트)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentOrange.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5A0).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. 메인 컨텐츠 영역 (화면 작아짐 및 키보드 오버플로우 방지 LayoutBuilder)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단 네비게이션 & 프로그레스 바
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                                  onPressed: _prevStep,
                                ),
                                const Spacer(),
                                Text(
                                  '${_currentStep + 1} / $_totalSteps',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                tween: Tween<double>(begin: 0, end: progress),
                                builder: (context, value, _) => LinearProgressIndicator(
                                  value: value,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  valueColor: const AlwaysStoppedAnimation<Color>(accentOrange),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 에러 배너 (존재할 때)
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 질문 & 인터랙션 본문 (AnimatedSwitcher 로 스무스한 트랜지션)
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.04, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_currentStep),
                                  child: _buildCurrentStep(),
                                ),
                              ),
                            ),

                            // 하단 완료 버튼 (Step 1~5에서 확인/다음 필요 시)
                            if (_shouldShowBottomButton()) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26), // 알약 캡슐형 버튼
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _currentStep == _totalSteps - 1 ? 'CoachFit 시작하기 🚀' : '다음으로 확인',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowBottomButton() {
    // 성별(Step 0), 경력(Step 3), 목표(Step 4)는 알약 버튼 터치 시 바로 자동 다음 스텝 진행
    // 입력창이 있는 Step 1(닉네임), Step 2(신체), Step 5(계정)는 하단 버튼 표시
    return _currentStep == 1 || _currentStep == 2 || _currentStep == 5;
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepGender();
      case 1:
        return _buildStepNickname();
      case 2:
        return _buildStepBodySpec();
      case 3:
        return _buildStepExperience();
      case 4:
        return _buildStepGoal();
      case 5:
        return _buildStepAccount();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // Step 0: 성별 질문 (사용자 첨부 이미지 스타일 완벽 구현)
  // =========================================================================
  Widget _buildStepGender() {
    const accent = Color(0xFFFF4820);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          '안녕하세요, 코치핏 코치예요!\n함께 운동을 시작하게 돼서 정말 기뻐요.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.45,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '먼저, '),
              TextSpan(
                text: '성별',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: '이 어떻게 되나요?'),
            ],
          ),
        ),
        const Spacer(),

        // 우측 정렬된 캡슐 알약 버튼 목록
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPillButton(
                title: '남성',
                isSelected: _selectedGender == 'male',
                onTap: () {
                  setState(() => _selectedGender = 'male');
                  _delayedNextStep();
                },
              ),
              const SizedBox(height: 12),
              _buildPillButton(
                title: '여성',
                isSelected: _selectedGender == 'female',
                onTap: () {
                  setState(() => _selectedGender = 'female');
                  _delayedNextStep();
                },
              ),
              const SizedBox(height: 12),
              _buildPillButton(
                title: '비공개',
                isSelected: _selectedGender == 'undisclosed',
                onTap: () {
                  setState(() => _selectedGender = 'undisclosed');
                  _delayedNextStep();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // =========================================================================
  // Step 1: 닉네임 입력
  // =========================================================================
  Widget _buildStepNickname() {
    const accent = Color(0xFFFF4820);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '반가워요! 앞으로 트레이닝하면서\n회원님을 '),
              TextSpan(
                text: '어떻게 불러드릴까요?',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '운동 기록과 AI 코칭 리포트에 표시될 닉네임입니다.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 40),

        // 세련된 캡슐형 입력창
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161A23),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: TextField(
            controller: _nicknameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: '닉네임',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              hintText: '예: 벤치마스터, 헬린이',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.badge_outlined, color: accent, size: 22),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // =========================================================================
  // Step 2: 키 & 체중 & 목표 체중 입력
  // =========================================================================
  Widget _buildStepBodySpec() {
    const accent = Color(0xFFFF4820);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '정확한 AI 운동 강도 설정을 위해\n회원님의 '),
              TextSpan(
                text: '키와 몸무게',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: '를 알려주세요.'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '1RM 추정치 및 권장 칼로리 소모량 계산에 사용됩니다.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 30),

        _buildSpecInputField(
          controller: _heightController,
          label: '키 (신장)',
          unit: 'cm',
          icon: Icons.height_rounded,
        ),
        const SizedBox(height: 14),
        _buildSpecInputField(
          controller: _weightController,
          label: '현재 체중',
          unit: 'kg',
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 14),
        _buildSpecInputField(
          controller: _targetWeightController,
          label: '목표 체중',
          unit: 'kg',
          icon: Icons.flag_outlined,
        ),
        const Spacer(),
      ],
    );
  }

  // =========================================================================
  // Step 3: 운동 경력 선택 (Pill 카드)
  // =========================================================================
  Widget _buildStepExperience() {
    const accent = Color(0xFFFF4820);

    final expList = [
      {
        'key': 'beginner',
        'title': '🌱 헬스 입문 (0 ~ 6개월)',
        'sub': '기초 머신 사용법과 바른 자세 습득이 필요해요.',
      },
      {
        'key': 'intermediate',
        'title': '⚡ 중급자 (6개월 ~ 2년)',
        'sub': '부위별 분할 루틴과 점진적 과부하를 적용해요.',
      },
      {
        'key': 'advanced',
        'title': '🔥 숙련자 (2년 이상)',
        'sub': '고중량 스트렝스와 타겟 부위 고립 훈련에 익숙해요.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '현재 운동 경험은\n'),
              TextSpan(
                text: '어느 정도',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: '이신가요?'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '경력에 맞추어 부상 없는 최적의 세트 수를 제안해 드립니다.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 28),

        ...expList.map((item) {
          final isSelected = _selectedExperience == item['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() => _selectedExperience = item['key']!);
                _delayedNextStep();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.14) : const Color(0xFF161A23),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accent : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['sub']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: isSelected ? accent : Colors.white.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
      ],
    );
  }

  // =========================================================================
  // Step 4: 메인 목표 선택 (Pill 카드)
  // =========================================================================
  Widget _buildStepGoal() {
    const accentMint = Color(0xFF00E5A0);

    final goalList = [
      {
        'goal': '근비대 및 전신 근력 증진',
        'icon': '💪',
        'sub': '근육량 증가와 탄탄한 체격 완성',
      },
      {
        'goal': '체지방 감량 및 다이어트',
        'icon': '🔥',
        'sub': '칼로리 소모와 린매스업 체형 관리',
      },
      {
        'goal': '스트렝스(3대 500) 강화',
        'icon': '⚡',
        'sub': '스쿼트·벤치·데드 고중량 파워 증진',
      },
      {
        'goal': '기초 체력 및 코어 밸런스',
        'icon': '🧘',
        'sub': '일상 활력과 바른 체형 교정',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '이번 트레이닝에서 가장 달성하고 싶은\n'),
              TextSpan(
                text: '핵심 목표',
                style: TextStyle(color: accentMint, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: '는 무엇인가요?'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '목표에 따라 3D 근육 맵과 AI 추천 루틴이 실시간 세팅됩니다.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 24),

        ...goalList.map((item) {
          final isSelected = _selectedGoal == item['goal'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                setState(() => _selectedGoal = item['goal']!);
                _delayedNextStep();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? accentMint.withValues(alpha: 0.14) : const Color(0xFF161A23),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentMint : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['goal']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['sub']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: isSelected ? accentMint : Colors.white.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
      ],
    );
  }

  // =========================================================================
  // Step 5: 계정 정보 (이메일 & 비밀번호) 및 완료
  // =========================================================================
  Widget _buildStepAccount() {
    const accent = Color(0xFFFF4820);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '모든 준비가 끝났습니다! 🎉\n마지막으로 '),
              TextSpan(
                text: '로그인에 사용할 계정',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: '을 설정해 주세요.'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '운동 기록이 안전하게 클라우드 DB에 영구 보관됩니다.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 26),

        _buildTextField(
          controller: _emailController,
          label: '이메일 주소',
          hint: 'example@coachfit.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          label: '비밀번호',
          hint: '최소 6자 이상',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordConfirmController,
          label: '비밀번호 확인',
          hint: '비밀번호를 한 번 더 입력해 주세요',
          icon: Icons.lock_reset_rounded,
          obscureText: _obscurePassword,
        ),
        const Spacer(),
      ],
    );
  }

  // =========================================================================
  // 공통 헬퍼 위젯들
  // =========================================================================

  void _delayedNextStep() {
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _nextStep();
    });
  }

  /// 짐워크 스타일의 우측 정렬 캡슐 알약 버튼 (Pill Button)
  Widget _buildPillButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const accent = Color(0xFFFF4820);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.2) : const Color(0xFF161A23),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? accent : Colors.white.withValues(alpha: 0.16),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFFFF4820), size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSpecInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF4820), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              unit,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
