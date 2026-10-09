import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/coachfit_theme.dart';
import '../main_navigation_screen.dart';
import 'app_launch_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  int _step = 0;
  String _experience = '';
  String _goal = '';
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _moveNext() {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _errorMessage = '서비스 이용약관에 동의해 주세요.');
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_goal.isEmpty || _experience.isEmpty) {
      setState(() => _errorMessage = '운동 목표와 현재 운동 경력을 선택해 주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
        heightCm: double.tryParse(_heightController.text.trim()),
        weightKg: double.tryParse(_weightController.text.trim()),
        targetWeightKg: double.tryParse(_targetWeightController.text.trim()),
        experience: _experience,
        workoutGoal: _goal,
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
      body: SafeArea(
        child: Column(
          children: [
            _RegisterTopBar(
              step: _step,
              onBack: () {
                if (_step == 1) {
                  setState(() {
                    _step = 0;
                    _errorMessage = null;
                  });
                } else {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppLaunchScreen(initialLoggedIn: false),
                      ),
                    );
                  }
                }
              },
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _step == 0
                        ? _buildAccountStep()
                        : _buildProfileStep(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return Column(
      key: const ValueKey('account'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIntro(
          eyebrow: 'ACCOUNT',
          title: '운동 기록을 안전하게\n보관해 드릴게요.',
          caption: '로그인에 사용할 기본 정보만 입력해 주세요.',
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.018),
            border: Border.all(color: CoachFitColors.divider),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FieldLabel('이름'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '이름 또는 닉네임을 입력해 주세요',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '사용할 이름을 입력해 주세요.'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('이메일'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'coachfit@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? '올바른 이메일을 입력해 주세요.'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('비밀번호'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '6자 이상 입력해 주세요',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.length < 6
                    ? '비밀번호는 6자 이상이어야 합니다.'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: CoachFitColors.surface,
            border: Border.all(color: CoachFitColors.divider),
            borderRadius: BorderRadius.circular(13),
          ),
          child: CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            dense: true,
            activeColor: CoachFitColors.orange,
            title: const Text(
              '서비스 이용약관 및 개인정보 처리방침에 동의합니다.',
              style: TextStyle(color: CoachFitColors.textMuted, fontSize: 11),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          _ErrorBanner(message: _errorMessage!),
        ],
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: _moveNext,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('다음 단계'),
              SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIntro(
          eyebrow: 'PERSONALIZE',
          title: '어떤 운동을 원하는지\n알려주세요.',
          caption: '선택한 내용은 맞춤 루틴에 반영되며 언제든 변경할 수 있어요.',
        ),
        const SizedBox(height: 32),
        const _ChoiceHeading(title: '운동 목표', caption: '하나를 선택해 주세요'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: 2.35,
          children: [
            _GoalCard(
              icon: Icons.fitness_center_rounded,
              label: '근육 증가',
              selected: _goal == '근비대 및 전신 근력 증진',
              onTap: () => setState(() => _goal = '근비대 및 전신 근력 증진'),
            ),
            _GoalCard(
              icon: Icons.local_fire_department_rounded,
              label: '체지방 감소',
              selected: _goal == '체지방 감소',
              onTap: () => setState(() => _goal = '체지방 감소'),
            ),
            _GoalCard(
              icon: Icons.trending_up_rounded,
              label: '체력 향상',
              selected: _goal == '체력 향상',
              onTap: () => setState(() => _goal = '체력 향상'),
            ),
            _GoalCard(
              icon: Icons.favorite_outline_rounded,
              label: '건강 유지',
              selected: _goal == '건강 유지',
              onTap: () => setState(() => _goal = '건강 유지'),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const _ChoiceHeading(title: '운동 경력', caption: '현재 수준에 가까운 항목'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: CoachFitColors.surface,
            border: Border.all(color: CoachFitColors.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _ExperienceButton(
                label: '입문',
                value: 'novice',
                selected: _experience,
                onTap: (value) => setState(() => _experience = value),
              ),
              _ExperienceButton(
                label: '초급',
                value: 'beginner',
                selected: _experience,
                onTap: (value) => setState(() => _experience = value),
              ),
              _ExperienceButton(
                label: '중급',
                value: 'intermediate',
                selected: _experience,
                onTap: (value) => setState(() => _experience = value),
              ),
              _ExperienceButton(
                label: '고급',
                value: 'advanced',
                selected: _experience,
                onTap: (value) => setState(() => _experience = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: '키',
                unit: 'cm',
                controller: _heightController,
                minimum: 50,
                optional: true,
                hintText: '예: 175',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                label: '현재 체중',
                unit: 'kg',
                controller: _weightController,
                minimum: 20,
                optional: true,
                hintText: '예: 72',
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _NumberField(
          label: '목표 체중',
          unit: 'kg',
          controller: _targetWeightController,
          minimum: 20,
          optional: true,
          hintText: '예: 68',
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: _errorMessage!),
        ],
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _isLoading || _goal.isEmpty || _experience.isEmpty
              ? null
              : _register,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : const Text('코치핏 시작하기'),
        ),
      ],
    );
  }
}

class _RegisterTopBar extends StatelessWidget {
  final int step;
  final VoidCallback onBack;

  const _RegisterTopBar({required this.step, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: CoachFitColors.surface,
              foregroundColor: CoachFitColors.textSoft,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _ProgressSegment(active: true)),
                const SizedBox(width: 6),
                Expanded(child: _ProgressSegment(active: step == 1)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${step + 1} / 2',
            style: const TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final bool active;
  const _ProgressSegment({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 4,
      decoration: BoxDecoration(
        color: active ? CoachFitColors.orange : CoachFitColors.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String caption;

  const _StepIntro({
    required this.eyebrow,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: CoachFitColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: CoachFitColors.text,
            fontSize: 31,
            height: 1.22,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          caption,
          style: const TextStyle(
            color: CoachFitColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
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

class _ChoiceHeading extends StatelessWidget {
  final String title;
  final String caption;

  const _ChoiceHeading({required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FieldLabel(title),
        const Spacer(),
        Text(
          caption,
          style: const TextStyle(color: CoachFitColors.textMuted, fontSize: 9),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? CoachFitColors.orange.withValues(alpha: 0.13)
          : CoachFitColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? CoachFitColors.orange.withValues(alpha: 0.55)
              : CoachFitColors.divider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected
                    ? CoachFitColors.orange
                    : CoachFitColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? CoachFitColors.text
                        : CoachFitColors.textSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: CoachFitColors.orange,
                  size: 17,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperienceButton extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _ExperienceButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? CoachFitColors.surfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? CoachFitColors.text
                  : CoachFitColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final double minimum;
  final bool optional;
  final String? hintText;

  const _NumberField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.minimum,
    this.optional = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FieldLabel(label),
            if (optional) ...[
              const SizedBox(width: 4),
              const Text(
                '선택',
                style: TextStyle(
                  color: CoachFitColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hintText, suffixText: unit),
          validator: (value) {
            final normalized = value?.trim() ?? '';
            if (optional && normalized.isEmpty) return null;
            final parsed = double.tryParse(normalized);
            if (parsed == null || parsed < minimum) return '값을 확인해 주세요.';
            return null;
          },
        ),
      ],
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
