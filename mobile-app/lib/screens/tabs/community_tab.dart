import 'package:flutter/material.dart';

/// 4. 커뮤니티 탭 (Community Tab)
/// - 오운완 (오늘 운동 완료) 인증 피드
/// - 크루 응원 및 좋아요/댓글 인터랙션
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  String _selectedFilter = '전체';

  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'userName': '헬린이탈출중',
      'userAvatar': '🦁',
      'time': '10분 전',
      'content': '오늘 가슴 5세트 완료! 벤치프레스 70kg 10회 찍었습니다. 펌핑감 최고네요 🔥',
      'workoutBadge': '가슴 & 삼두 • 4,800kg 볼륨',
      'likes': 24,
      'isLiked': false,
      'comments': 5,
    },
    {
      'id': 2,
      'userName': '득근요정',
      'userAvatar': '🐰',
      'time': '35분 전',
      'content': '스쿼트 드디어 100kg 8회 성공했습니다! CoachFit AI 코치가 추천해 준 루틴대로 점진적 과부하 하니까 정체기 뚫렸어요 👏',
      'workoutBadge': '하체 메인 • 6,200kg 볼륨',
      'likes': 42,
      'isLiked': true,
      'comments': 12,
    },
    {
      'id': 3,
      'userName': '퇴근후쇠질',
      'userAvatar': '🐺',
      'time': '2시간 전',
      'content': '야근하고 와서 진짜 가기 싫었는데 그래도 오운완 완료했습니다! 역시 운동은 일단 헬스장 가는 게 반이네요.',
      'workoutBadge': '등 & 이두 • 3,900kg 볼륨',
      'likes': 19,
      'isLiked': false,
      'comments': 3,
    },
  ];

  void _toggleLike(int id) {
    setState(() {
      final post = _posts.firstWhere((p) => p['id'] == id);
      if (post['isLiked'] == true) {
        post['isLiked'] = false;
        post['likes'] = (post['likes'] as int) - 1;
      } else {
        post['isLiked'] = true;
        post['likes'] = (post['likes'] as int) + 1;
      }
    });
  }

  void _openCreatePostModal() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              onPressed: () {
                if (textCtrl.text.trim().isEmpty) return;
                setState(() {
                  _posts.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'userName': '나(User_01)',
                    'userAvatar': '⚡',
                    'time': '방금 전',
                    'content': textCtrl.text.trim(),
                    'workoutBadge': '오늘의 운동 인증',
                    'likes': 1,
                    'isLiked': true,
                    'comments': 0,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('오운완 인증 피드가 등록되었습니다!')),
                );
              },
              child: const Text('피드에 등록하기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // 필터 칩 목록
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['전체', '🔥 인기', '🏆 오늘 오운완', '👥 내 크루'].map((chip) {
                final isSelected = chip == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(chip),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedFilter = chip),
                    backgroundColor: const Color(0xFF171B22),
                    selectedColor: scheme.primary.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? scheme.primary : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? scheme.primary : Colors.white12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // 피드 카드 목록
          ..._posts.map((post) => _CommunityFeedCard(
                post: post,
                onToggleLike: () => _toggleLike(post['id'] as int),
              )),
        ],
      ),
    );
  }
}

class _CommunityFeedCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onToggleLike;

  const _CommunityFeedCard({required this.post, required this.onToggleLike});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLiked = post['isLiked'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 정보 헤더
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Text(post['userAvatar'] as String, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        post['time'] as String,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post['workoutBadge'] as String,
                    style: TextStyle(color: scheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 글 본문
            Text(
              post['content'] as String,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),

            // 좋아요 & 댓글 액션 바
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: isLiked ? Colors.redAccent : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post['likes']}',
                          style: TextStyle(
                            color: isLiked ? Colors.redAccent : Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(
                        '${post['comments']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
