import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/community_service.dart';
import '../../services/workout_service.dart';
import '../community_post_detail_screen.dart';
import '../widgets/community_challenge_banner.dart';
import '../widgets/community_comment_sheet.dart';
import '../widgets/community_crew_ranking.dart';
import '../widgets/muscle_map_widget.dart';

/// 4. 커뮤니티 탭 (Community Tab)
/// - 오운완 인증 피드 + 리액션/댓글/북마크 영속화
/// - 필터칩 실제 작동 (A), 영속화 (B), 댓글 바텀시트 (C)
/// - 운동 기록 자동 뱃지 (D), 리액션 4종 (E), 크루 랭킹 (F)
/// - 챌린지 (G), 포스트 상세 (H), 북마크 (I)
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

enum _Filter { all, popular, todayOuwan, myCrew, bookmarked }

class _CommunityTabState extends State<CommunityTab> {
  final CommunityService _community = CommunityService();
  final WorkoutService _workout = WorkoutService();
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _community.addListener(_onChange);
  }

  @override
  void dispose() {
    _community.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  List<CommunityPost> _applyFilter(List<CommunityPost> posts) {
    switch (_filter) {
      case _Filter.all:
        return [...posts]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Filter.popular:
        return [...posts]
          ..sort((a, b) => b.totalReactions.compareTo(a.totalReactions));
      case _Filter.todayOuwan:
        final today = DateTime.now();
        return posts
            .where((p) =>
                p.createdAt.year == today.year &&
                p.createdAt.month == today.month &&
                p.createdAt.day == today.day)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Filter.myCrew:
        return posts.where((p) => p.isCrew || p.isMine).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Filter.bookmarked:
        return posts.where((p) => p.isBookmarked).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  /// 오늘 운동 기록을 바탕으로 자동 뱃지 문자열 생성.
  /// 백엔드 조회 실패 시 null 반환.
  Future<String?> _buildAutoBadge() async {
    try {
      final all = await _workout.fetchWorkouts();
      final today = DateTime.now();
      final todays = all.where((w) =>
          w.workoutDate.year == today.year &&
          w.workoutDate.month == today.month &&
          w.workoutDate.day == today.day);
      if (todays.isEmpty) return null;
      double totalVolume = 0;
      final parts = <MuscleGroup>{};
      for (final w in todays) {
        totalVolume += w.volume;
        parts.addAll(MuscleGroupExtension.parseFromText(w.exerciseName));
      }
      final partNames = parts.map((e) => e.koreanName).take(2).join(' & ');
      final fmt = NumberFormat('#,###');
      return '${partNames.isEmpty ? '오늘의 운동' : partNames} • ${fmt.format(totalVolume.toInt())}kg 볼륨';
    } catch (_) {
      return null;
    }
  }

  Future<void> _openCreatePostModal() async {
    final autoBadge = await _buildAutoBadge();
    if (!mounted) return;
    final textCtrl = TextEditingController();
    final badgeCtrl =
        TextEditingController(text: autoBadge ?? '오늘의 운동 인증');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '오운완 인증 작성',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            if (autoBadge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 14, color: Color(0xFF00E5A0)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '오늘 운동 자동 요약: $autoBadge',
                        style: const TextStyle(
                            color: Color(0xFF00E5A0), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: badgeCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                labelText: '뱃지 (수정 가능)',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '오늘 운동 완료 소감과 자극받은 부위를 공유해 보세요! 💪',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (textCtrl.text.trim().isEmpty) return;
                await _community.addPost(
                  CommunityPost(
                    id: DateTime.now().millisecondsSinceEpoch,
                    userName: '나',
                    userAvatar: '⚡',
                    createdAt: DateTime.now(),
                    content: textCtrl.text.trim(),
                    workoutBadge: badgeCtrl.text.trim().isEmpty
                        ? '오늘의 운동 인증'
                        : badgeCtrl.text.trim(),
                    isMine: true,
                  ),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('오운완 인증 피드가 등록되었습니다!')),
                );
              },
              child: const Text('피드에 등록하기'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(CommunityPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailScreen(postId: post.id),
      ),
    );
  }

  void _openComments(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommunityCommentSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '오운완 커뮤니티',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostModal,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('오운완 인증'),
      ),
      body: FutureBuilder<List<CommunityPost>>(
        future: _community.loadAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = _applyFilter(snap.data!);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const CommunityChallengeBanner(),
              const SizedBox(height: 14),
              const CommunityCrewRanking(),
              const SizedBox(height: 14),
              _FilterChipsRow(
                current: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 12),
              if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _emptyMessage(_filter),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ),
                )
              else
                ...posts.map(
                  (post) => _CommunityFeedCard(
                    post: post,
                    onToggleReaction: (e) =>
                        _community.toggleReaction(post.id, e),
                    onToggleBookmark: () =>
                        _community.toggleBookmark(post.id),
                    onOpenComments: () => _openComments(post),
                    onOpenDetail: () => _openDetail(post),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _emptyMessage(_Filter f) {
    switch (f) {
      case _Filter.todayOuwan:
        return '오늘 올라온 오운완이 아직 없어요.\n첫 번째가 되어보세요! 💪';
      case _Filter.myCrew:
        return '내 크루의 오운완이 없어요.';
      case _Filter.bookmarked:
        return '아직 저장한 포스트가 없어요.\n북마크 아이콘을 눌러 저장해보세요.';
      default:
        return '포스트가 없어요.';
    }
  }
}

class _FilterChipsRow extends StatelessWidget {
  final _Filter current;
  final ValueChanged<_Filter> onChanged;
  const _FilterChipsRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = <(_Filter, String)>[
      (_Filter.all, '전체'),
      (_Filter.popular, '🔥 인기'),
      (_Filter.todayOuwan, '🏆 오늘 오운완'),
      (_Filter.myCrew, '👥 내 크루'),
      (_Filter.bookmarked, '🔖 북마크'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: it.$2,
                selected: current == it.$1,
                onTap: () => onChanged(it.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CommunityFeedCard extends StatelessWidget {
  final CommunityPost post;
  final ValueChanged<String> onToggleReaction;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenDetail;

  const _CommunityFeedCard({
    required this.post,
    required this.onToggleReaction,
    required this.onToggleBookmark,
    required this.onOpenComments,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Text(post.userAvatar,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isCrew) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.people_alt_rounded,
                                  size: 12, color: accent),
                            ],
                            if (post.isMine) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ME',
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _relative(post.createdAt),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onToggleBookmark,
                    icon: Icon(
                      post.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: post.isBookmarked ? accent : Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  post.workoutBadge,
                  style: const TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                post.content,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final e in kReactionEmojis)
                    _ReactionPill(
                      emoji: e,
                      count: post.reactions[e] ?? 0,
                      selected: post.myReactions.contains(e),
                      onTap: () => onToggleReaction(e),
                    ),
                  InkWell(
                    onTap: onOpenComments,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('MM/dd').format(t);
  }
}

class _ReactionPill extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _ReactionPill({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? accent : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
