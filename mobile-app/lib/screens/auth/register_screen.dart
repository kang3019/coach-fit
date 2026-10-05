import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  // Step 0: 계정 정보
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;

  // Step 1: 닉네임 & 성별
  final _nicknameController = TextEditingController(text: '헬린이');
  String _selectedGender = 'male'; // male, female, undisclosed

  // Step 2: 신체 스펙
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '70');
  final _targetWeightController = TextEditingController(text: '68');

  // Step 3: 운동 경력
  String _selectedExperience = 'beginner'; // beginner, intermediate, advanced

  // Step 4: 운동 목표
  String _selectedGoal = '근비대 및 전신 근력 증진';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    // Step별 유효성 검사
    if (_currentStep == 0) {
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
    } else if (_currentStep == 1) {
      if (_nicknameController.text.trim().isEmpty) {
        setState(() => _errorMessage = '닉네임을 입력해 주세요.');
        return;
      }
    } else if (_currentStep == 2) {
      final h = double.tryParse(_heightController.text.trim());
      final w = double.tryParse(_weightController.text.trim());
      if (h == null || h <= 0 || w == null || w <= 0) {
        setState(() => _errorMessage = '키와 체중을 올바른 숫자로 입력해 주세요.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
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
          content: Text('${_nicknameController.text.trim()}님 환영합니다! 맞춤 설정이 완료되었습니다. 🎉'),
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
    const bgColor = Color(0xFF0E1116);
    const accentOrange = Color(0xFFFF4820);

    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 & 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: _prevStep,
                  ),
                  const Spacer(),
                  Text(
                    '${_currentStep + 1} / $_totalSteps',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(accentOrange),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 에러 메시지 배너
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Container(
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
              ),

            // 짐워크 스타일 PageView (슬라이드 애니메이션)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0Account(),
                  _buildStep1Profile(),
                  _buildStep2BodySpec(),
                  _buildStep3Experience(),
                  _buildStep4Goal(),
                ],
              ),
            ),

            // 하단 액션 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == _totalSteps - 1 ? _handleRegister : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1 ? 'CoachFit 시작하기 🚀' : '다음으로 확인',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Step 0: 계정 생성 (이메일 & 비밀번호)
  // ==========================================
  Widget _buildStep0Account() {
    return _buildStepLayout(
      emoji: '🎉',
      title: 'CoachFit에 오신 것을 환영해요!',
      subtitle: '로그인 및 클라우드 동기화에 사용할\n계정 정보를 입력해 주세요.',
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: '이메일 주소',
            hint: 'example@coachfit.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordConfirmController,
            label: '비밀번호 확인',
            hint: '비밀번호를 한 번 더 입력해 주세요',
            icon: Icons.lock_reset_rounded,
            obscureText: _obscurePassword,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Step 1: 닉네임 & 성별
  // ==========================================
  Widget _buildStep1Profile() {
    return _buildStepLayout(
      emoji: '👤',
      title: '회원님을 어떻게 불러드릴까요?',
      subtitle: '트레이너가 회원님을 부를 친근한 닉네임과\n성별을 선택해 주세요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nicknameController,
            label: '닉네임',
            hint: '예: 벤치마스터, 헬린이',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 24),
          const Text(
            '성별',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectCard(
                  title: '남성',
                  icon: '👨',
                  isSelected: _selectedGender == 'male',
                  onTap: () => setState(() => _selectedGender = 'male'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSelectCard(
                  title: '여성',
                  icon: '👩',
                  isSelected: _selectedGender == 'female',
                  onTap: () => setState(() => _selectedGender = 'female'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSelectCard(
                  title: '비공개',
                  icon: '🔒',
                  isSelected: _selectedGender == 'undisclosed',
                  onTap: () => setState(() => _selectedGender = 'undisclosed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Step 2: 신체 스펙 (키 & 체중 & 목표 체중)
  // ==========================================
  Widget _buildStep2BodySpec() {
    return _buildStepLayout(
      emoji: '📏',
      title: '신체 스펙을 알려주세요',
      subtitle: '정확한 1RM 계산 및 AI 트레이닝 강도 설정을 위해\n키와 체중 정보를 사용합니다.',
      child: Column(
        children: [
          _buildUnitInputField(
            controller: _heightController,
            label: '키 (신장)',
            unit: 'cm',
            icon: Icons.height_rounded,
          ),
          const SizedBox(height: 14),
          _buildUnitInputField(
            controller: _weightController,
            label: '현재 체중',
            unit: 'kg',
            icon: Icons.monitor_weight_outlined,
          ),
          const SizedBox(height: 14),
          _buildUnitInputField(
            controller: _targetWeightController,
            label: '목표 체중',
            unit: 'kg',
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Step 3: 운동 경력 (Experience)
  // ==========================================
  Widget _buildStep3Experience() {
    final experiences = [
      {
        'key': 'beginner',
        'badge': '🌱 입문 / 초보',
        'title': '헬스 시작 0 ~ 6개월',
        'desc': '기본적인 머신 사용법과 기초 체력 증진이 필요해요.',
      },
      {
        'key': 'intermediate',
        'badge': '⚡ 중급자',
        'title': '헬스 경력 6개월 ~ 2년',
        'desc': '부위별 분할 루틴과 점진적 과부하 원리를 이해하고 있어요.',
      },
      {
        'key': 'advanced',
        'badge': '🔥 숙련자 / 고수',
        'title': '헬스 경력 2년 이상',
        'desc': '고중량 프리웨이트와 자신만의 루틴 노하우가 확립되어 있어요.',
      },
    ];

    return _buildStepLayout(
      emoji: '🏋️',
      title: '운동 경험이 얼마나 되시나요?',
      subtitle: '경력에 맞추어 부상 없이 성장할 수 있는\n최적의 루틴을 제안해 드립니다.',
      child: Column(
        children: experiences.map((exp) {
          final isSelected = _selectedExperience == exp['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedExperience = exp['key']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF4820).withValues(alpha: 0.12) : const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF4820) : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF4820).withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exp['badge']!,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFFF4820) : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            exp['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exp['desc']!,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFFFF4820) : Colors.white.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // Step 4: 메인 운동 목표 (Goal)
  // ==========================================
  Widget _buildStep4Goal() {
    final goals = [
      {
        'goal': '근비대 및 전신 근력 증진',
        'icon': '💪',
        'desc': '근육량 증가와 탄탄한 몸매 완성',
      },
      {
        'goal': '체지방 감량 및 다이어트',
        'icon': '🔥',
        'desc': '칼로리 소모와 린매스업 체형 관리',
      },
      {
        'goal': '스트렝스(3대 500) 강화',
        'icon': '⚡',
        'desc': '스쿼트·벤치·데드 고중량 파워 증진',
      },
      {
        'goal': '기초 체력 및 코어 밸런스',
        'icon': '🧘',
        'desc': '일상 활력과 바른 자세, 코어 안정성',
      },
    ];

    return _buildStepLayout(
      emoji: '🎯',
      title: '가장 달성하고 싶은 핵심 목표는?',
      subtitle: '목표에 맞추어 3D 근육 맵과 AI 추천 루틴이\n실시간으로 커스터마이징됩니다.',
      child: Column(
        children: goals.map((item) {
          final isSelected = _selectedGoal == item['goal'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedGoal = item['goal']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00E5A0).withValues(alpha: 0.12) : const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E5A0) : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(item['icon']!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['goal']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['desc']!,
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
                      color: isSelected ? const Color(0xFF00E5A0) : Colors.white.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // 공통 헬퍼 위젯들
  // ==========================================

  Widget _buildStepLayout({
    required String emoji,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
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
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUnitInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _buildSelectCard({
    required String title,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4820).withValues(alpha: 0.15) : const Color(0xFF151922),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4820) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
