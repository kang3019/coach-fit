import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';

/// 메뉴 탭의 프로필 카드 또는 "신체 스펙" 그리드를 탭하면 열리는
/// 프로필 편집 화면. 닉네임/성별/신장/체중/목표 체중/운동 구력
/// 필드를 입력받아 ProfileService 에 저장한다.
class ProfileEditScreen extends StatefulWidget {
  final UserProfile initial;
  const ProfileEditScreen({super.key, required this.initial});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _targetWeightCtrl;
  late Gender _gender;
  late ExperienceLevel _experience;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.initial.nickname);
    _heightCtrl = TextEditingController(
      text: _fmtNullable(widget.initial.heightCm),
    );
    _weightCtrl = TextEditingController(
      text: _fmtNullable(widget.initial.weightKg),
    );
    _targetWeightCtrl = TextEditingController(
      text: _fmtNullable(widget.initial.targetWeightKg),
    );
    _gender = widget.initial.gender;
    _experience = widget.initial.experience;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  String _fmtNullable(double? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1));

  double? _parseNullable(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = widget.initial.copyWith(
        nickname: _nicknameCtrl.text.trim(),
        gender: _gender,
        heightCm: _parseNullable(_heightCtrl.text),
        weightKg: _parseNullable(_weightCtrl.text),
        targetWeightKg: _parseNullable(_targetWeightCtrl.text),
        experience: _experience,
      );
      await ProfileService().save(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '프로필 편집',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // 닉네임
            const _SectionLabel('닉네임'),
            TextFormField(
              controller: _nicknameCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(hintText: '예: 김운동'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '닉네임을 입력하세요';
                if (v.trim().length > 20) return '20자 이내';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 성별
            const _SectionLabel('성별'),
            Wrap(
              spacing: 8,
              children: Gender.values
                  .map((g) => _ChoiceChipTile(
                        label: g.label,
                        selected: _gender == g,
                        onTap: () => setState(() => _gender = g),
                        accent: accent,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // 신장 / 체중 / 목표 체중
            const _SectionLabel('신체 정보 (선택)'),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _heightCtrl,
                    label: '신장(cm)',
                    max: 250,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _weightCtrl,
                    label: '현재 체중(kg)',
                    max: 300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _targetWeightCtrl,
              label: '목표 체중(kg)',
              max: 300,
            ),
            const SizedBox(height: 20),

            // 운동 경력
            const _SectionLabel('운동 경력'),
            Column(
              children: ExperienceLevel.values
                  .map((e) => _RadioRow(
                        title: e.label,
                        subtitle: e.description,
                        selected: _experience == e,
                        onTap: () => setState(() => _experience = e),
                        accent: accent,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),

            // 저장
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? '저장 중…' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final double max;
  const _NumberField({
    required this.controller,
    required this.label,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null; // optional
        final parsed = double.tryParse(v.trim());
        if (parsed == null) return '숫자만';
        if (parsed <= 0) return '> 0';
        if (parsed > max) return '≤ $max';
        return null;
      },
    );
  }
}

class _ChoiceChipTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  const _ChoiceChipTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  const _RadioRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? accent : Colors.white24,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
