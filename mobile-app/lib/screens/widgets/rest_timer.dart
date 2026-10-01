import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 세트 사이 휴식 카운트다운 타이머 바텀시트.
///
/// - 60 / 90 / 120초 프리셋
/// - 시작 / 일시정지 / 리셋
/// - 0에 도달하면 원이 primary 색으로 채워지고 "완료" 상태로 전환
/// - 모바일에선 haptic + 시스템 알림음, 웹에선 시각 피드백만
class RestTimerSheet extends StatefulWidget {
  final int initialSeconds;
  const RestTimerSheet({super.key, this.initialSeconds = 90});

  static Future<void> show(BuildContext context, {int initialSeconds = 90}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RestTimerSheet(initialSeconds: initialSeconds),
    );
  }

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  static const List<int> _presets = [60, 90, 120];

  Timer? _ticker;
  late int _totalSeconds;
  late int _remaining;
  bool _running = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _remaining = _totalSeconds;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectPreset(int seconds) {
    _ticker?.cancel();
    setState(() {
      _totalSeconds = seconds;
      _remaining = seconds;
      _running = false;
      _finished = false;
    });
  }

  void _start() {
    if (_running || _remaining == 0) return;
    setState(() {
      _running = true;
      _finished = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _remaining = 0;
          _running = false;
          _finished = true;
          _ticker?.cancel();
          _notifyDone();
        }
      });
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = _totalSeconds;
      _running = false;
      _finished = false;
    });
  }

  void _notifyDone() {
    // 모바일: 진동 + 시스템 alert 사운드
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  String get _timeLabel {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return 1 - (_remaining / _totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = _finished ? scheme.primary : scheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '⏱️ 휴식 타이머',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timeLabel,
                      style: TextStyle(
                        color: _finished ? scheme.primary : Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_finished)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '휴식 완료!',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: _presets
                .map((s) => _PresetChip(
                      seconds: s,
                      selected: _totalSeconds == s,
                      onTap: () => _selectPreset(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('리셋'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _running ? _pause : _start,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    _running ? '일시정지' : (_finished ? '다시' : '시작'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int seconds;
  final bool selected;
  final VoidCallback onTap;
  const _PresetChip({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            color: selected ? scheme.primary : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
