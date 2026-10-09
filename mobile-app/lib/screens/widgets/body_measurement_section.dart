import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_profile.dart';
import '../../services/body_record_service.dart';
import '../../services/profile_service.dart';

/// 신체 측정 섹션. 더미 데이터 대신 로컬 저장소 사용.
/// H: 체중/골격근량/체지방률 입력 + 체중 추이 라인 그래프.
/// G: 프로필의 targetWeightKg 와 비교한 감량/증량 목표 진행도 바.
class BodyMeasurementSection extends StatefulWidget {
  const BodyMeasurementSection({super.key});

  @override
  State<BodyMeasurementSection> createState() => _BodyMeasurementSectionState();
}

class _BodyMeasurementSectionState extends State<BodyMeasurementSection> {
  final BodyRecordService _service = BodyRecordService();
  final ProfileService _profileService = ProfileService();
  List<BodyRecord> _records = const [];
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _service.addListener(_reload);
    _profileService.addListener(_loadProfile);
    _reload();
    _loadProfile();
  }

  @override
  void dispose() {
    _service.removeListener(_reload);
    _profileService.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await _service.loadAll();
    if (mounted) setState(() => _records = list);
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.load();
    if (mounted) setState(() => _profile = p);
  }

  Future<void> _openInput() async {
    await InputBodyRecordSheet.show(context, service: _service);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final latest = _records.isEmpty ? null : _records.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '신체 측정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _openInput,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('기록 추가', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (latest == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text(
              '아직 기록이 없어요. 첫 측정값을 추가해보세요.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _LatestTile(
                      label: '체중',
                      value: _fmt(latest.weightKg),
                      suffix: 'kg',
                      color: accent,
                    ),
                    _LatestTile(
                      label: '골격근량',
                      value: _fmt(latest.muscleKg),
                      suffix: 'kg',
                      color: const Color(0xFF60A5FA),
                    ),
                    _LatestTile(
                      label: '체지방',
                      value: _fmt(latest.bodyFatPercent),
                      suffix: '%',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '최근 측정: ${DateFormat('yyyy-MM-dd').format(latest.date)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        // G: 목표 체중 진행도 (프로필에 목표 체중 있고 최신 체중 있을 때)
        if (latest?.weightKg != null &&
            (_profile?.targetWeightKg ?? 0) > 0) ...[
          const SizedBox(height: 10),
          _TargetProgressCard(
            currentKg: latest!.weightKg!,
            targetKg: _profile!.targetWeightKg!,
          ),
        ],
        if (_records.length >= 2) ...[
          const SizedBox(height: 10),
          _WeightChart(records: _records),
        ],
      ],
    );
  }

  String _fmt(double? v) =>
      v == null ? '-' : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1));
}

/// G: 감량/증량 목표 체중 진행도 카드.
/// 프로필의 targetWeightKg 와 최신 체중을 비교해 진행률(%)과 남은 kg 를 표시.
class _TargetProgressCard extends StatelessWidget {
  final double currentKg;
  final double targetKg;
  const _TargetProgressCard({required this.currentKg, required this.targetKg});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final diff = currentKg - targetKg;
    final isReducing = diff > 0; // 감량 목표
    final absDiff = diff.abs();
    // 진행도 근사 — 시작점을 "현재 + 3kg 거리" 로 가정 (목표 세팅 시점의 체중 미기록 상태)
    final startDist = absDiff + 3.0;
    final progress =
        absDiff < 0.1 ? 1.0 : (1.0 - (absDiff / startDist)).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    final goalText =
        isReducing ? '감량 목표' : (diff < 0 ? '증량 목표' : '유지 목표');
    final diffText = absDiff < 0.1
        ? '목표 달성!'
        : isReducing
            ? '${absDiff.toStringAsFixed(1)}kg 남음'
            : '+${absDiff.toStringAsFixed(1)}kg 필요';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                '🎯 $goalText',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '현재 ${currentKg.toStringAsFixed(1)}kg',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                diffText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '목표 ${targetKg.toStringAsFixed(1)}kg',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatestTile extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;
  const _LatestTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: ' $suffix',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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

class _WeightChart extends StatelessWidget {
  final List<BodyRecord> records;
  const _WeightChart({required this.records});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    // 날짜 오름차순 + weight 있는 것만
    final sorted = records
        .where((r) => r.weightKg != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < 2) return const SizedBox.shrink();

    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].weightKg!),
    ];
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(1.0, 10.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '체중 추이',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: minY - pad,
                maxY: maxY + pad,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.25),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InputBodyRecordSheet extends StatefulWidget {
  final BodyRecordService service;
  const InputBodyRecordSheet({super.key, required this.service});

  static Future<void> show(BuildContext context, {required BodyRecordService service}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: InputBodyRecordSheet(service: service),
      ),
    );
  }

  @override
  State<InputBodyRecordSheet> createState() => _InputBodyRecordSheetState();
}

class _InputBodyRecordSheetState extends State<InputBodyRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _muscleCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _muscleCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final rec = BodyRecord(
        date: DateTime.now(),
        weightKg: _parseOrNull(_weightCtrl.text),
        muscleKg: _parseOrNull(_muscleCtrl.text),
        bodyFatPercent: _parseOrNull(_fatCtrl.text),
      );
      await widget.service.add(rec);
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _parseOrNull(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '오늘의 신체 측정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _NumField(controller: _weightCtrl, label: '체중 (kg)'),
            const SizedBox(height: 10),
            _NumField(controller: _muscleCtrl, label: '골격근량 (kg)'),
            const SizedBox(height: 10),
            _NumField(controller: _fatCtrl, label: '체지방률 (%)'),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
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

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _NumField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (double.tryParse(v.trim()) == null) return '숫자';
        return null;
      },
    );
  }
}
