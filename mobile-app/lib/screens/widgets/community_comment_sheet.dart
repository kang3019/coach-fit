import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/community_service.dart';

/// 댓글 리스트 + 입력 바텀시트.
/// 호출부에서 showModalBottomSheet 로 띄우고, 저장은 서비스가 직접 처리.
class CommunityCommentSheet extends StatefulWidget {
  final CommunityPost post;
  const CommunityCommentSheet({super.key, required this.post});

  @override
  State<CommunityCommentSheet> createState() => _CommunityCommentSheetState();
}

class _CommunityCommentSheetState extends State<CommunityCommentSheet> {
  final CommunityService _service = CommunityService();
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  CommunityPost get _current {
    final cached = _service.loadAll();
    // ignore: discarded_futures
    cached;
    // loadAll 이미 캐시된 상태 — 동기적으로 service 상태 사용 가능하지만 안전하게 widget.post 보완.
    return widget.post;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final comment = CommunityComment(
        id: DateTime.now().millisecondsSinceEpoch,
        userName: '나',
        userAvatar: '⚡',
        createdAt: DateTime.now(),
        content: text,
      );
      await _service.addComment(widget.post.id, comment);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CommunityPost>>(
      future: _service.loadAll(),
      builder: (ctx, snap) {
        final posts = snap.data ?? [];
        final post = posts.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => _current,
        );
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      '댓글 ${post.comments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: post.comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            '첫 댓글을 남겨보세요 💬',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: post.comments.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (ctx, i) =>
                              _CommentTile(comment: post.comments[i]),
                        ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '댓글 남기기…',
                          hintStyle: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF1E232C),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Color(0xFF00E5A0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white10,
            child: Text(comment.userAvatar,
                style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relative(comment.createdAt),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
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
