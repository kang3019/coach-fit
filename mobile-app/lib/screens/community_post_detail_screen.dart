import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/community_service.dart';
import 'widgets/community_comment_sheet.dart';

/// 포스트 상세 화면 (H).
/// 피드에서 탭하면 전체 글 + 리액션 상세 + 댓글 목록을 한 화면에서 본다.
class CommunityPostDetailScreen extends StatefulWidget {
  final int postId;
  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final CommunityService _service = CommunityService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _openCommentSheet(CommunityPost post) {
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
    const accent = Color(0xFF00E5A0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('포스트'),
      ),
      body: FutureBuilder<List<CommunityPost>>(
        future: _service.loadAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snap.data!.firstWhere(
            (p) => p.id == widget.postId,
            orElse: () => _notFound,
          );
          if (post.id == _notFound.id) {
            return const Center(
              child: Text('포스트를 찾을 수 없어요',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white10,
                    child: Text(post.userAvatar,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (post.isCrew) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.people_alt_rounded,
                                  size: 14, color: accent),
                            ],
                          ],
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(post.createdAt),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _service.toggleBookmark(post.id),
                    icon: Icon(
                      post.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: post.isBookmarked ? accent : Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  post.workoutBadge,
                  style: const TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                post.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF171B22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('리액션',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final e in kReactionEmojis)
                          _ReactionButton(
                            emoji: e,
                            count: post.reactions[e] ?? 0,
                            selected: post.myReactions.contains(e),
                            onTap: () =>
                                _service.toggleReaction(post.id, e),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '댓글 ${post.comments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openCommentSheet(post),
                    icon: const Icon(Icons.add_comment_outlined, size: 16),
                    label: const Text('댓글 쓰기',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (post.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '아직 댓글이 없어요. 첫 댓글을 남겨보세요.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                )
              else
                ...post.comments.map(
                  (c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171B22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white10,
                          child: Text(c.userAvatar,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.userName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(c.content,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static final CommunityPost _notFound = CommunityPost(
    id: -1,
    userName: '',
    userAvatar: '',
    createdAt: DateTime(2000),
    content: '',
    workoutBadge: '',
  );
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _ReactionButton({
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
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: selected ? accent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
