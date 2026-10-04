import 'package:flutter/material.dart';

import '../../services/community_service.dart';

/// 챌린지 가로 스크롤 배너 (G).
/// 참여/해제 토글, 더미 진행도 표시.
class CommunityChallengeBanner extends StatefulWidget {
  const CommunityChallengeBanner({super.key});

  @override
  State<CommunityChallengeBanner> createState() =>
      _CommunityChallengeBannerState();
}

class _CommunityChallengeBannerState extends State<CommunityChallengeBanner> {
  final CommunityService _service = CommunityService();
  Set<String> _joined = {};

  @override
  void initState() {
    super.initState();
    _service.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _service.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final j = await _service.loadJoinedChallenges();
    if (mounted) setState(() => _joined = j);
  }

  @override
  Widget build(BuildContext context) {
    final challenges = _service.challenges;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final c = challenges[i];
          final isJoined = _joined.contains(c.id);
          return _ChallengeCard(
            challenge: c,
            isJoined: isJoined,
            onTap: () => _service.toggleChallenge(c.id),
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final CommunityChallenge challenge;
  final bool isJoined;
  final VoidCallback onTap;
  const _ChallengeCard({
    required this.challenge,
    required this.isJoined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF4820);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isJoined
              ? accent.withValues(alpha: 0.12)
              : const Color(0xFF171B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isJoined ? accent : Colors.white10,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(challenge.emoji,
                    style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (isJoined)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '참여 중',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              challenge.description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              isJoined ? '탭해서 해제' : '탭해서 참여',
              style: TextStyle(
                color: isJoined ? accent : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
