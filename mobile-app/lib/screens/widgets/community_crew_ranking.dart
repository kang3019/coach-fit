import 'package:flutter/material.dart';

import '../../services/community_service.dart';
import '../../services/workout_service.dart';

/// 주간 크루 볼륨 랭킹 위젯 (F).
/// 더미 사용자 + 나(실제 운동 기록 집계) 혼합.
class CommunityCrewRanking extends StatefulWidget {
  const CommunityCrewRanking({super.key});

  @override
  State<CommunityCrewRanking> createState() => _CommunityCrewRankingState();
}

class _CommunityCrewRankingState extends State<CommunityCrewRanking> {
  final WorkoutService _workoutService = WorkoutService();
  final CommunityService _community = CommunityService();
  List<CrewMember>? _members;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    double myVolume = 0;
    try {
      final weekly = await _workoutService.fetchWeeklyVolume();
      myVolume = weekly.values.fold<double>(0, (a, b) => a + b);
    } catch (_) {
      // 백엔드 불가 시 0 유지
    }
    if (!mounted) return;
    setState(() => _members = _community.buildCrewRanking(myVolume));
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    final members = _members;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              const Text(
                '이번 주 크루 랭킹',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Text(
                '총 볼륨',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            ...members.asMap().entries.map(
                  (e) => _RankRow(
                    rank: e.key + 1,
                    member: e.value,
                    accent: accent,
                  ),
                ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final CrewMember member;
  final Color accent;
  const _RankRow({
    required this.rank,
    required this.member,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank == 2
            ? const Color(0xFF94A3B8)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.white38;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor:
                member.isMe ? accent.withValues(alpha: 0.2) : Colors.white10,
            child:
                Text(member.avatar, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.name + (member.isMe ? ' (나)' : ''),
              style: TextStyle(
                color: member.isMe ? accent : Colors.white,
                fontWeight: member.isMe ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _fmtVolume(member.weeklyVolume),
            style: TextStyle(
              color: member.isMe ? accent : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtVolume(double v) {
    if (v <= 0) return '0 kg';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k kg';
    return '${v.toInt()} kg';
  }
}
