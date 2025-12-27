class ShowcaseItem {
  const ShowcaseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.visibility,
    required this.classroomIds,
    required this.preview,
    required this.metadata,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.ownerId,
    required this.ownerName,
    required this.ownerRole,
    required this.isLiked,
    required this.teacherGenerated,
    required this.aiGenerated,
    required this.commentDetails,
  });

  final String id;
  final String title;
  final String description;
  final String kind;
  final String visibility;
  final List<String> classroomIds;
  final Map<String, dynamic> preview;
  final Map<String, dynamic> metadata;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final String ownerId;
  final String ownerName;
  final String ownerRole;
  final bool isLiked;
  final bool teacherGenerated;
  final bool aiGenerated;
  final List<ShowcaseComment> commentDetails;

  ShowcaseItem copyWith({
    int? likes,
    int? comments,
    bool? isLiked,
    List<ShowcaseComment>? commentDetails,
  }) {
    return ShowcaseItem(
      id: id,
      title: title,
      description: description,
      kind: kind,
      visibility: visibility,
      classroomIds: classroomIds,
      preview: preview,
      metadata: metadata,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerRole: ownerRole,
      isLiked: isLiked ?? this.isLiked,
      teacherGenerated: teacherGenerated,
      aiGenerated: aiGenerated,
      commentDetails: commentDetails ?? this.commentDetails,
    );
  }

  factory ShowcaseItem.fromJson(Map<String, dynamic> json) {
    return ShowcaseItem(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'general',
      visibility: (json['visibility'] as String?) ?? 'classes',
      classroomIds: (json['classroomIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      preview:
          (json['preview'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      ownerId: (json['ownerId'] as String?) ?? '',
      ownerName: (json['ownerName'] as String?) ?? '',
      ownerRole: (json['ownerRole'] as String?) ?? '',
      isLiked: json['isLiked'] as bool? ?? false,
      teacherGenerated: json['teacherGenerated'] as bool? ?? false,
      aiGenerated: json['aiGenerated'] as bool? ?? false,
      commentDetails: (json['commentDetails'] as List<dynamic>? ?? [])
          .map((item) => ShowcaseComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShowcaseComment {
  const ShowcaseComment({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String content;
  final DateTime createdAt;

  factory ShowcaseComment.fromJson(Map<String, dynamic> json) {
    return ShowcaseComment(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ShowcaseCategory {
  const ShowcaseCategory({
    required this.id,
    required this.name,
    required this.count,
  });

  final String id;
  final String name;
  final int count;

  factory ShowcaseCategory.fromJson(Map<String, dynamic> json) {
    return ShowcaseCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

extension ShowcaseMediaHelpers on ShowcaseItem {
  String? get previewImageUrl {
    return _firstNonEmpty([
      preview['imageUrl'],
      preview['thumbnailUrl'],
      if ((_string(preview['subtype']) == 'image') || kind == 'image')
        preview['fileUrl'],
    ]);
  }

  String? get previewVideoUrl {
    if (_string(preview['subtype']) != 'video' && kind != 'video') return null;
    return _firstNonEmpty([
      preview['videoUrl'],
      preview['fileUrl'],
    ]);
  }

  String? get previewAudioUrl {
    if (_string(preview['subtype']) != 'audio' && kind != 'music') return null;
    return _firstNonEmpty([
      preview['audioUrl'],
      preview['fileUrl'],
    ]);
  }

  String? get downloadUrl {
    return _firstNonEmpty([
      preview['fileUrl'],
      metadata['fileUrl'],
      if (previewImageUrl != null) previewImageUrl,
      if (previewVideoUrl != null) previewVideoUrl,
      if (previewAudioUrl != null) previewAudioUrl,
    ]);
  }

  String get displayFileName {
    return _firstNonEmpty([
          preview['fileName'],
          metadata['fileName'],
          metadata['originalFileName'],
          title,
        ]) ??
        '未命名作品';
  }

  String? _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }

  String _string(dynamic value) {
    if (value is String) return value.toLowerCase();
    return value?.toString().toLowerCase() ?? '';
  }
}
