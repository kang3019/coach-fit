import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 커뮤니티 댓글 1건.
class CommunityComment {
  final int id;
  final String userName;
  final String userAvatar;
  final DateTime createdAt;
  final String content;

  const CommunityComment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'userAvatar': userAvatar,
        'createdAt': createdAt.toIso8601String(),
        'content': content,
      };

  factory CommunityComment.fromJson(Map<String, dynamic> j) => CommunityComment(
        id: j['id'] as int,
        userName: j['userName'] as String,
        userAvatar: j['userAvatar'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        content: j['content'] as String,
      );
}

/// 지원하는 리액션 이모지 4종.
const List<String> kReactionEmojis = ['❤', '💪', '🔥', '👏'];

/// 커뮤니티 포스트 1건.
class CommunityPost {
  final int id;
  final String userName;
  final String userAvatar;
  final DateTime createdAt;
  final String content;
  final String workoutBadge;
  final Map<String, int> reactions;
  final Set<String> myReactions;
  final List<CommunityComment> comments;
  final bool isBookmarked;
  final bool isMine;
  final bool isCrew;

  CommunityPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.content,
    required this.workoutBadge,
    Map<String, int>? reactions,
    Set<String>? myReactions,
    List<CommunityComment>? comments,
    this.isBookmarked = false,
    this.isMine = false,
    this.isCrew = false,
  })  : reactions = reactions ?? {},
        myReactions = myReactions ?? {},
        comments = comments ?? [];

  int get totalReactions =>
      reactions.values.fold<int>(0, (sum, v) => sum + v);

  CommunityPost copyWith({
    Map<String, int>? reactions,
    Set<String>? myReactions,
    List<CommunityComment>? comments,
    bool? isBookmarked,
  }) =>
      CommunityPost(
        id: id,
        userName: userName,
        userAvatar: userAvatar,
        createdAt: createdAt,
        content: content,
        workoutBadge: workoutBadge,
        reactions: reactions ?? Map.of(this.reactions),
        myReactions: myReactions ?? Set.of(this.myReactions),
        comments: comments ?? List.of(this.comments),
        isBookmarked: isBookmarked ?? this.isBookmarked,
        isMine: isMine,
        isCrew: isCrew,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'userAvatar': userAvatar,
        'createdAt': createdAt.toIso8601String(),
        'content': content,
        'workoutBadge': workoutBadge,
        'reactions': reactions,
        'myReactions': myReactions.toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'isBookmarked': isBookmarked,
        'isMine': isMine,
        'isCrew': isCrew,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id: j['id'] as int,
        userName: j['userName'] as String,
        userAvatar: j['userAvatar'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        content: j['content'] as String,
        workoutBadge: j['workoutBadge'] as String,
        reactions: (j['reactions'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
            {},
        myReactions:
            ((j['myReactions'] as List<dynamic>?) ?? []).cast<String>().toSet(),
        comments: ((j['comments'] as List<dynamic>?) ?? [])
            .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
            .toList(),
        isBookmarked: j['isBookmarked'] as bool? ?? false,
        isMine: j['isMine'] as bool? ?? false,
        isCrew: j['isCrew'] as bool? ?? false,
      );
}

/// 챌린지 1건.
class CommunityChallenge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int targetCount;
  final String unit;

  const CommunityChallenge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.unit,
  });
}

/// 크루 랭킹용 사용자 1명.
class CrewMember {
  final String name;
  final String avatar;
  final double weeklyVolume;
  final bool isMe;
  const CrewMember({
    required this.name,
    required this.avatar,
    required this.weeklyVolume,
    this.isMe = false,
  });
}

/// 커뮤니티 포스트/리액션/댓글/북마크를 로컬에 영속화하는 싱글톤.
class CommunityService extends ChangeNotifier {
  static const String _prefKey = 'community.posts.v1';
  static const String _joinedChallengesKey = 'community.challenges.joined.v1';

  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  List<CommunityPost>? _cache;
  Set<String>? _joinedChallenges;

  Future<List<CommunityPost>> loadAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) {
      _cache = _seedPosts();
      await _persist();
      return List.unmodifiable(_cache!);
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache = list;
      return List.unmodifiable(list);
    } catch (_) {
      _cache = _seedPosts();
      return List.unmodifiable(_cache!);
    }
  }

  Future<Set<String>> loadJoinedChallenges() async {
    if (_joinedChallenges != null) return Set.of(_joinedChallenges!);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_joinedChallengesKey) ?? [];
    _joinedChallenges = raw.toSet();
    return Set.of(_joinedChallenges!);
  }

  Future<void> toggleChallenge(String id) async {
    final set = await loadJoinedChallenges();
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    _joinedChallenges = set;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_joinedChallengesKey, set.toList());
    notifyListeners();
  }

  Future<void> addPost(CommunityPost post) async {
    final list = [post, ...await loadAll()];
    _cache = list;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleReaction(int postId, String emoji) async {
    final list = [...await loadAll()];
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = list[idx];
    final my = Set.of(post.myReactions);
    final counts = Map.of(post.reactions);
    if (my.contains(emoji)) {
      my.remove(emoji);
      final c = (counts[emoji] ?? 1) - 1;
      if (c <= 0) {
        counts.remove(emoji);
      } else {
        counts[emoji] = c;
      }
    } else {
      my.add(emoji);
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    list[idx] =
        post.copyWith(reactions: counts, myReactions: my);
    _cache = list;
    await _persist();
    notifyListeners();
  }

  Future<void> addComment(int postId, CommunityComment comment) async {
    final list = [...await loadAll()];
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = list[idx];
    list[idx] =
        post.copyWith(comments: [...post.comments, comment]);
    _cache = list;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleBookmark(int postId) async {
    final list = [...await loadAll()];
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = list[idx];
    list[idx] = post.copyWith(isBookmarked: !post.isBookmarked);
    _cache = list;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_cache!.map((p) => p.toJson()).toList()),
    );
  }

  /// 처음 사용 시 더미 포스트 3건 시드.
  List<CommunityPost> _seedPosts() {
    final now = DateTime.now();
    return [
      CommunityPost(
        id: 1,
        userName: '헬린이탈출중',
        userAvatar: '🦁',
        createdAt: now.subtract(const Duration(minutes: 10)),
        content: '오늘 가슴 5세트 완료! 벤치프레스 70kg 10회 찍었습니다. 펌핑감 최고네요 🔥',
        workoutBadge: '가슴 & 삼두 • 4,800kg 볼륨',
        reactions: {'❤': 24, '💪': 8},
        comments: [
          CommunityComment(
            id: 101,
            userName: '득근요정',
            userAvatar: '🐰',
            createdAt: now.subtract(const Duration(minutes: 5)),
            content: '벤치 70kg 10회… 부럽습니다 👏',
          ),
        ],
        isCrew: true,
      ),
      CommunityPost(
        id: 2,
        userName: '득근요정',
        userAvatar: '🐰',
        createdAt: now.subtract(const Duration(minutes: 35)),
        content:
            '스쿼트 드디어 100kg 8회 성공했습니다! CoachFit AI 코치가 추천해 준 루틴대로 점진적 과부하 하니까 정체기 뚫렸어요 👏',
        workoutBadge: '하체 메인 • 6,200kg 볼륨',
        reactions: {'❤': 42, '🔥': 15, '💪': 20},
        myReactions: {'❤'},
        comments: [],
        isCrew: true,
      ),
      CommunityPost(
        id: 3,
        userName: '퇴근후쇠질',
        userAvatar: '🐺',
        createdAt: now.subtract(const Duration(hours: 2)),
        content:
            '야근하고 와서 진짜 가기 싫었는데 그래도 오운완 완료했습니다! 역시 운동은 일단 헬스장 가는 게 반이네요.',
        workoutBadge: '등 & 이두 • 3,900kg 볼륨',
        reactions: {'❤': 19, '💪': 7},
        comments: [],
      ),
      CommunityPost(
        id: 4,
        userName: '아침러너',
        userAvatar: '🦌',
        createdAt: DateTime(now.year, now.month, now.day - 1, 7, 30),
        content: '어제 비 와서 못 뛰어서 오늘 아침 10km 러닝으로 커버. 종아리 터질 것 같아요 🏃',
        workoutBadge: '유산소 • 60분',
        reactions: {'❤': 11, '🔥': 4},
        comments: [],
        isCrew: true,
      ),
    ];
  }

  // ===== Crew Ranking (더미) =====
  List<CrewMember> buildCrewRanking(double myWeeklyVolume) {
    final list = <CrewMember>[
      const CrewMember(name: '득근요정', avatar: '🐰', weeklyVolume: 42500),
      const CrewMember(name: '헬린이탈출중', avatar: '🦁', weeklyVolume: 28400),
      const CrewMember(name: '퇴근후쇠질', avatar: '🐺', weeklyVolume: 21300),
      const CrewMember(name: '아침러너', avatar: '🦌', weeklyVolume: 15700),
      CrewMember(
        name: '나',
        avatar: '⚡',
        weeklyVolume: myWeeklyVolume,
        isMe: true,
      ),
    ]..sort((a, b) => b.weeklyVolume.compareTo(a.weeklyVolume));
    return list;
  }

  // ===== Challenges (정적 목록) =====
  List<CommunityChallenge> get challenges => const [
        CommunityChallenge(
          id: 'streak7',
          emoji: '🔥',
          title: '7일 연속 운동',
          description: '한 주 동안 매일 한 세트 이상',
          targetCount: 7,
          unit: '일',
        ),
        CommunityChallenge(
          id: 'legs5',
          emoji: '🦵',
          title: '주 5회 하체',
          description: '한 주 안에 하체 세트 5회 이상',
          targetCount: 5,
          unit: '회',
        ),
        CommunityChallenge(
          id: 'volume10k',
          emoji: '💪',
          title: '주간 10,000kg',
          description: '한 주 총 볼륨 10,000kg 돌파',
          targetCount: 10000,
          unit: 'kg',
        ),
      ];
}
