/// Comment reply model
class CommentReply {
  final int id;
  final String username;
  final String content;
  final DateTime createdAt;

  CommentReply({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
  });
}

/// Comment data model
class CommentModel {
  final int id;
  final String username;
  final String content;
  final DateTime createdAt;
  final List<CommentReply> replies;

  CommentModel({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
    List<CommentReply>? replies,
  }) : replies = replies ?? [];
}

/// Post data model
class PostModel {
  final String id;
  final String userId;
  final String caption;
  final String? imageUrl;
  int auraScore;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<CommentModel> comments;
  final List<String> hashtags;
  bool hasVoted;

  PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    this.imageUrl,
    required this.auraScore,
    this.authorUsername,
    this.authorAvatarUrl,
    required this.createdAt,
    this.expiresAt,
    List<CommentModel>? comments,
    List<String>? hashtags,
    this.hasVoted = false,
  }) : comments = comments ?? [],
       hashtags = hashtags ?? [];

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    caption: json['caption'] ?? json['content'] ?? '',
    imageUrl: json['image_url'],
    auraScore: json['aura_score'] ?? 0,
    authorUsername: json['author_username'],
    authorAvatarUrl: json['author_avatar_url'],
    createdAt: DateTime.parse(json['created_at']),
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    hashtags: json['hashtags'] != null ? List<String>.from(json['hashtags']) : [],
  );
}

/// Mission definition model
class MissionModel {
  final int id;
  final String title;
  final String description;
  final String type;
  final int auraReward;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.auraReward,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) => MissionModel(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: json['type'],
    auraReward: json['aura_reward'],
  );
}

/// User mission assignment model
class UserMissionModel {
  final int id;
  final String userId;
  final int missionId;
  String status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final MissionModel mission;

  UserMissionModel({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.mission,
  });

  factory UserMissionModel.fromJson(Map<String, dynamic> json) => UserMissionModel(
    id: json['id'],
    userId: json['user_id'].toString(),
    missionId: json['mission_id'],
    status: json['status'],
    completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
    mission: MissionModel.fromJson(json['mission']),
  );
}

/// Achievement model
class AchievementModel {
  final String id;
  final String emoji;
  final String title;
  final String? subtitle;
  final String description;
  final int auraReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  bool isPublic;

  AchievementModel({
    required this.id,
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.description,
    required this.auraReward,
    required this.isUnlocked,
    this.unlockedAt,
    this.isPublic = true,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final achievement = json['achievement'] ?? json;
    return AchievementModel(
      id: achievement['id'].toString(),
      emoji: achievement['emoji'] ?? '🏆',
      title: achievement['title'] ?? '',
      subtitle: achievement['subtitle'] ?? achievement['description'],
      description: achievement['description'] ?? '',
      auraReward: achievement['aura_reward'] ?? 0,
      isUnlocked: json['unlocked_at'] != null || json['is_unlocked'] == true,
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
      isPublic: json['is_public'] ?? true,
    );
  }
}

/// Follower relationship model
class FollowerModel {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  FollowerModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) => FollowerModel(
    id: json['id'].toString(),
    followerId: json['follower_id'].toString(),
    followingId: json['following_id'].toString(),
    createdAt: DateTime.parse(json['created_at']),
  );
}

/// Weekly task model
class WeeklyTaskModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int targetCount;
  int currentCount;
  final int auraReward;
  final DateTime expiresAt;

  WeeklyTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetCount,
    this.currentCount = 0,
    required this.auraReward,
    required this.expiresAt,
  });

  bool get isCompleted => currentCount >= targetCount;
  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}

/// Daily task model
class DailyTaskModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int targetCount;
  int currentCount;
  final int auraReward;

  DailyTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetCount,
    this.currentCount = 0,
    required this.auraReward,
  });

  bool get isCompleted => currentCount >= targetCount;
  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}

/// Milestone task model
class MilestoneTaskModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int targetCount;
  int currentCount;
  final int auraReward;
  bool isClaimed;

  MilestoneTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetCount,
    this.currentCount = 0,
    required this.auraReward,
    this.isClaimed = false,
  });

  bool get isCompleted => currentCount >= targetCount;
  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}

/// User profile model (for viewing other users)
class UserProfileModel {
  final String id;
  final String username;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final int auraPoints;
  final int level;
  final bool isPremium;
  final List<AchievementModel> achievements;
  final List<PostModel> posts;
  final List<UserMissionModel> missions;
  final DateTime createdAt;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  UserProfileModel({
    required this.id,
    required this.username,
    this.email,
    this.bio,
    this.avatarUrl,
    required this.auraPoints,
    this.level = 1,
    this.isPremium = false,
    List<AchievementModel>? achievements,
    List<PostModel>? posts,
    List<UserMissionModel>? missions,
    required this.createdAt,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  }) : achievements = achievements ?? [],
       posts = posts ?? [],
       missions = missions ?? [];

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
    id: json['id'].toString(),
    username: json['username'] ?? 'buddy',
    email: json['email'],
    avatarUrl: json['avatar_url'],
    bio: json['bio'],
    auraPoints: json['aura_points'] ?? json['aura_balance'] ?? 0,
    level: json['level'] ?? 1,
    isPremium: json['is_premium'] ?? false,
    achievements: json['achievements'] != null
        ? (json['achievements'] as List)
            .map((a) => AchievementModel.fromJson(a))
            .toList()
        : [],
    posts: json['posts'] != null
        ? (json['posts'] as List).map((p) => PostModel.fromJson(p)).toList()
        : [],
    missions: json['missions'] != null
        ? (json['missions'] as List)
            .map((m) => UserMissionModel.fromJson(m))
            .toList()
        : [],
    createdAt: DateTime.parse(json['created_at']),
    postsCount: json['posts_count'] ?? 0,
    followersCount: json['followers_count'] ?? 0,
    followingCount: json['following_count'] ?? 0,
  );
}

/// User data model
class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final int auraPoints;
  final int level;
  final int currentStreak;
  final DateTime? lastStreakClaimedAt;
  final bool isPremium;
  final DateTime createdAt;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final String? bio;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.bio,
    required this.auraPoints,
    this.level = 1,
    this.currentStreak = 0,
    this.lastStreakClaimedAt,
    required this.isPremium,
    required this.createdAt,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'].toString(),
    email: json['email'] ?? '',
    username: json['username'],
    avatarUrl: json['avatar_url'],
    bio: json['bio'],
    auraPoints: json['aura_points'] ?? json['aura_balance'] ?? 0,
    level: json['level'] ?? 1,
    currentStreak: json['current_streak'] ?? 0,
    lastStreakClaimedAt: json['last_streak_claimed_at'] != null ? DateTime.parse(json['last_streak_claimed_at']) : null,
    isPremium: json['is_premium'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
    postsCount: json['posts_count'] ?? 0,
    followersCount: json['followers_count'] ?? 0,
    followingCount: json['following_count'] ?? 0,
  );
}

/// Aura transaction history entry
class AuraTransaction {
  final String id;
  final String title;
  final String description;
  final int amount;
  final String emoji;
  final DateTime createdAt;

  bool get isPositive => amount > 0;

  AuraTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.emoji,
    required this.createdAt,
  });

  factory AuraTransaction.fromJson(Map<String, dynamic> json) => AuraTransaction(
    id: json['id'].toString(),
    title: json['type'] as String? ?? 'Aura Transfer',
    description: json['description'] as String,
    amount: json['amount'] as int,
    emoji: json['emoji'] as String? ?? '✨',
    createdAt: DateTime.parse(json['timestamp'] as String),
  );
}
/// Daily login reward tracker
class DailyLoginReward {
  int currentStreak;
  DateTime? lastClaimDate;
  bool claimedToday;

  DailyLoginReward({
    this.currentStreak = 0,
    this.lastClaimDate,
    this.claimedToday = false,
  });

  static const List<int> rewards = [20, 30, 40, 50, 60, 80, 150];

  int get todayReward => rewards[(currentStreak).clamp(0, 6)];
  int get nextDayIndex => (currentStreak).clamp(0, 6);
  bool get isDay7 => currentStreak == 6;
}

/// Aura streak tracking
class AuraStreak {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int currentDays;
  final int targetDays;
  final int bonusAura;
  bool claimed;

  AuraStreak({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.currentDays,
    required this.targetDays,
    required this.bonusAura,
    this.claimed = false,
  });

  bool get isCompleted => currentDays >= targetDays;
  double get progress => (currentDays / targetDays).clamp(0.0, 1.0);
}

/// Notification item model
class NotificationItem {
  final String id;
  final String
  type; // 'aura_received', 'hated', 'reply', 'validated', 'task_complete', 'streak'
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  String get emoji {
    switch (type) {
      case 'aura_received':
        return '✨';
      case 'hated':
        return '🔥';
      case 'reply':
        return '💬';
      case 'validated':
        return '✅';
      case 'task_complete':
        return '🎯';
      case 'streak':
        return '🔥';
      default:
        return '🔔';
    }
  }
}

