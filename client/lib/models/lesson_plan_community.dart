/// 教案社区功能扩展 - 支持教案分享、评分、学习等
class LessonPlanCommunityItem {
  const LessonPlanCommunityItem({
    required this.id,
    required this.lessonPlanId,
    required this.title,
    required this.theme,
    required this.gradeLevel,
    required this.duration,
    required this.teacherName,
    required this.teacherId,
    required this.likes,
    required this.bookmarks,
    required this.views,
    required this.shares,
    required this.rating,
    required this.ratingCount,
    required this.tags,
    required this.createdAt,
    required this.isLiked,
    required this.isBookmarked,
    this.description,
    this.coverImageUrl,
    this.difficultyLevel,
    this.resourceCount,
    this.comments = const [],
  });

  final String id;
  final String lessonPlanId; // 关联的LessonPlan ID
  final String title;
  final String theme;
  final String gradeLevel;
  final int duration;
  final String teacherName;
  final String teacherId;
  final int likes;
  final int bookmarks; // 收藏数
  final int views;
  final int shares; // 分享次数
  final double rating; // 平均评分（1-5星）
  final int ratingCount; // 评分人数
  final List<String> tags; // 标签（如"音乐"、"绘画"、"新手友好"）
  final DateTime createdAt;
  final bool isLiked;
  final bool isBookmarked;
  final String? description;
  final String? coverImageUrl;
  final String? difficultyLevel; // 难度等级（easy/medium/hard）
  final int? resourceCount; // 包含的资源数量
  final List<LessonPlanComment> comments;

  LessonPlanCommunityItem copyWith({
    int? likes,
    int? bookmarks,
    int? views,
    int? shares,
    double? rating,
    int? ratingCount,
    bool? isLiked,
    bool? isBookmarked,
    List<LessonPlanComment>? comments,
  }) {
    return LessonPlanCommunityItem(
      id: id,
      lessonPlanId: lessonPlanId,
      title: title,
      theme: theme,
      gradeLevel: gradeLevel,
      duration: duration,
      teacherName: teacherName,
      teacherId: teacherId,
      likes: likes ?? this.likes,
      bookmarks: bookmarks ?? this.bookmarks,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      tags: tags,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      description: description,
      coverImageUrl: coverImageUrl,
      difficultyLevel: difficultyLevel,
      resourceCount: resourceCount,
      comments: comments ?? this.comments,
    );
  }

  factory LessonPlanCommunityItem.fromJson(Map<String, dynamic> json) {
    return LessonPlanCommunityItem(
      id: json['id'] as String,
      lessonPlanId: json['lessonPlanId'] as String,
      title: (json['title'] as String?) ?? '',
      theme: (json['theme'] as String?) ?? '',
      gradeLevel: (json['gradeLevel'] as String?) ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 40,
      teacherName: (json['teacherName'] as String?) ?? '',
      teacherId: (json['teacherId'] as String?) ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      bookmarks: (json['bookmarks'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      difficultyLevel: json['difficultyLevel'] as String?,
      resourceCount: (json['resourceCount'] as num?)?.toInt(),
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) =>
                  LessonPlanComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonPlanId': lessonPlanId,
      'title': title,
      'theme': theme,
      'gradeLevel': gradeLevel,
      'duration': duration,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'likes': likes,
      'bookmarks': bookmarks,
      'views': views,
      'shares': shares,
      'rating': rating,
      'ratingCount': ratingCount,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      if (description != null) 'description': description,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
      if (resourceCount != null) 'resourceCount': resourceCount,
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}

/// 教案评论
class LessonPlanComment {
  const LessonPlanComment({
    required this.id,
    required this.teacherName,
    required this.teacherId,
    required this.content,
    required this.rating,
    required this.createdAt,
    this.teachingExperience, // 使用心得
    this.modifications, // 改进建议
    this.likes = 0,
  });

  final String id;
  final String teacherName;
  final String teacherId;
  final String content;
  final int? rating; // 1-5星评分（可选）
  final DateTime createdAt;
  final String? teachingExperience; // 使用后的教学体验
  final String? modifications; // 对教案的改进建议
  final int likes;

  factory LessonPlanComment.fromJson(Map<String, dynamic> json) {
    return LessonPlanComment(
      id: json['id'] as String,
      teacherName: (json['teacherName'] as String?) ?? '',
      teacherId: (json['teacherId'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      teachingExperience: json['teachingExperience'] as String?,
      modifications: json['modifications'] as String?,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'content': content,
      if (rating != null) 'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      if (teachingExperience != null) 'teachingExperience': teachingExperience,
      if (modifications != null) 'modifications': modifications,
      'likes': likes,
    };
  }
}

/// 教案收藏夹
class LessonPlanCollection {
  const LessonPlanCollection({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.lessonPlanIds,
    required this.createdAt,
    this.description,
    this.isPublic = false,
  });

  final String id;
  final String name;
  final String teacherId;
  final List<String> lessonPlanIds;
  final DateTime createdAt;
  final String? description;
  final bool isPublic; // 是否公开收藏夹

  factory LessonPlanCollection.fromJson(Map<String, dynamic> json) {
    return LessonPlanCollection(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      teacherId: (json['teacherId'] as String?) ?? '',
      lessonPlanIds: (json['lessonPlanIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacherId': teacherId,
      'lessonPlanIds': lessonPlanIds,
      'createdAt': createdAt.toIso8601String(),
      if (description != null) 'description': description,
      'isPublic': isPublic,
    };
  }
}
