class UserPreferences {
  const UserPreferences({
    required this.theme,
    required this.language,
    required this.notificationsEnabled,
  });

  final String theme;
  final String language;
  final bool notificationsEnabled;

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserPreferences(
        theme: 'light',
        language: 'zh-CN',
        notificationsEnabled: true,
      );
    }
    final notifications = json['notifications'];
    bool notificationsEnabled = true;
    if (notifications is Map<String, dynamic>) {
      notificationsEnabled = notifications['push'] as bool? ?? true;
    } else if (notifications is bool) {
      notificationsEnabled = notifications;
    }
    return UserPreferences(
      theme: json['theme'] as String? ?? 'light',
      language: json['language'] as String? ?? 'zh-CN',
      notificationsEnabled: notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'notifications': {
        'push': notificationsEnabled,
      },
    };
  }
}

class UserStats {
  const UserStats({
    required this.worksCreated,
    required this.lessonsCompleted,
    required this.pointsEarned,
  });

  final int worksCreated;
  final int lessonsCompleted;
  final int pointsEarned;

  factory UserStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserStats(worksCreated: 0, lessonsCompleted: 0, pointsEarned: 0);
    }
    return UserStats(
      worksCreated: (json['worksCreated'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (json['lessonsCompleted'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.username,
    required this.role,
    required this.bio,
    required this.avatar,
    required this.preferences,
    required this.stats,
  });

  final String userId;
  final String username;
  final String role;
  final String bio;
  final String? avatar;
  final UserPreferences preferences;
  final UserStats stats;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'teacher',
      bio: json['bio'] as String? ?? '',
      avatar: json['avatar'] as String?,
      preferences: UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>?),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>?),
    );
  }
}
