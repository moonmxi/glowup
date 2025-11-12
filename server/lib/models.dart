import 'dart:convert';

String _string(Map<String, dynamic> json, String key, [String fallback = '']) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

bool _bool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final value = json[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}

DateTime _date(Map<String, dynamic> json, String key, [DateTime? fallback]) {
  final value = json[key];
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  return (fallback ?? DateTime.now().toUtc());
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}

class User {
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    DateTime? createdAt,
    List<String>? managedClassroomIds,
    String? joinedClassroomId,
    Map<String, dynamic>? profile,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        managedClassroomIds = managedClassroomIds ?? <String>[],
        joinedClassroomId = joinedClassroomId,
        profile = profile ?? <String, dynamic>{};

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _string(json, 'id'),
      username: _string(json, 'username'),
      password: _string(json, 'password'),
      role: _string(json, 'role'),
      createdAt: _date(json, 'createdAt'),
      managedClassroomIds: _stringList(json, 'managedClassroomIds'),
      joinedClassroomId: json['joinedClassroomId'] as String?,
      profile:
          (json['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  String id;
  String username;
  String password;
  String role;
  DateTime createdAt;
  List<String> managedClassroomIds;
  String? joinedClassroomId;
  Map<String, dynamic> profile;

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'managedClassroomIds': managedClassroomIds,
      if (joinedClassroomId != null) 'joinedClassroomId': joinedClassroomId,
      if (profile.isNotEmpty) 'profile': profile,
    };
  }
}

class Classroom {
  Classroom({
    required this.id,
    required this.code,
    required this.name,
    required this.teacherId,
    DateTime? createdAt,
    List<String>? studentIds,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        studentIds = studentIds ?? <String>[];

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: _string(json, 'id'),
      code: _string(json, 'code'),
      name: _string(json, 'name'),
      teacherId: _string(json, 'teacherId'),
      createdAt: _date(json, 'createdAt'),
      studentIds: _stringList(json, 'studentIds'),
    );
  }

  String id;
  String code;
  String name;
  String teacherId;
  DateTime createdAt;
  List<String> studentIds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
      'studentIds': studentIds,
    };
  }
}

class StoryStep {
  StoryStep({
    required this.kind,
    required this.label,
    this.summary,
    Map<String, dynamic>? payload,
    bool? completed,
  })  : payload = payload ?? <String, dynamic>{},
        completed = completed ?? false;

  factory StoryStep.fromJson(Map<String, dynamic> json) {
    return StoryStep(
      kind: _string(json, 'kind'),
      label: _string(json, 'label'),
      summary: json['summary'] as String?,
      payload:
          (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      completed: _bool(json, 'completed'),
    );
  }

  String kind;
  String label;
  String? summary;
  Map<String, dynamic> payload;
  bool completed;

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'label': label,
      if (summary != null) 'summary': summary,
      'payload': payload,
      'completed': completed,
    };
  }
}

class Story {
  Story({
    required this.id,
    required this.teacherId,
    required this.classroomIds,
    required this.title,
    this.theme,
    this.status = 'draft',
    DateTime? createdAt,
    List<StoryStep>? steps,
    Map<String, dynamic>? metadata,
  })  : steps = steps ?? <StoryStep>[],
        metadata = metadata ?? <String, dynamic>{},
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: _string(json, 'id'),
      teacherId: _string(json, 'teacherId'),
      classroomIds: _stringList(json, 'classroomIds'),
      title: _string(json, 'title'),
      theme: json['theme'] as String?,
      status: _string(json, 'status', 'draft'),
      createdAt: _date(json, 'createdAt'),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((step) => StoryStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  String id;
  String teacherId;
  List<String> classroomIds;
  String title;
  String? theme;
  String status;
  DateTime createdAt;
  List<StoryStep> steps;
  Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'classroomIds': classroomIds,
      'title': title,
      if (theme != null) 'theme': theme,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'steps': steps.map((s) => s.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

class ContentComment {
  ContentComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = (createdAt ?? DateTime.now()).toUtc();

  factory ContentComment.fromJson(Map<String, dynamic> json) {
    return ContentComment(
      id: _string(json, 'id'),
      userId: _string(json, 'userId'),
      username: _string(json, 'username'),
      content: _string(json, 'content'),
      createdAt: _date(json, 'createdAt'),
    );
  }

  String id;
  String userId;
  String username;
  String content;
  DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ContentEntry {
  ContentEntry({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerRole,
    required this.kind,
    required this.title,
    required this.description,
    required this.visibility,
    required this.classroomIds,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
    List<String>? likeUserIds,
    List<ContentComment>? comments,
    bool? teacherGenerated,
    bool? aiGenerated,
    String? storyId,
    DateTime? createdAt,
  })  : preview = preview ?? <String, dynamic>{},
        metadata = metadata ?? <String, dynamic>{},
        likeUserIds = likeUserIds ?? <String>[],
        comments = comments ?? <ContentComment>[],
        teacherGenerated = teacherGenerated ?? false,
        aiGenerated = aiGenerated ?? false,
        storyId = storyId,
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  factory ContentEntry.fromJson(Map<String, dynamic> json) {
    return ContentEntry(
      id: _string(json, 'id'),
      ownerId: _string(json, 'ownerId'),
      ownerName: _string(json, 'ownerName'),
      ownerRole: _string(json, 'ownerRole'),
      kind: _string(json, 'kind'),
      title: _string(json, 'title'),
      description: _string(json, 'description'),
      visibility: _string(json, 'visibility', 'private'),
      classroomIds: _stringList(json, 'classroomIds'),
      preview:
          (json['preview'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      likeUserIds: _stringList(json, 'likeUserIds'),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => ContentComment.fromJson(c as Map<String, dynamic>))
          .toList(),
      teacherGenerated: _bool(json, 'teacherGenerated'),
      aiGenerated: _bool(json, 'aiGenerated'),
      storyId: json['storyId'] as String?,
      createdAt: _date(json, 'createdAt'),
    );
  }

  String id;
  String ownerId;
  String ownerName;
  String ownerRole;
  String kind;
  String title;
  String description;
  String visibility; // 'global' | 'classes'
  List<String> classroomIds;
  Map<String, dynamic> preview;
  Map<String, dynamic> metadata;
  List<String> likeUserIds;
  List<ContentComment> comments;
  bool teacherGenerated;
  bool aiGenerated;
  String? storyId;
  DateTime createdAt;

  int get likeCount => likeUserIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerRole': ownerRole,
      'kind': kind,
      'title': title,
      'description': description,
      'visibility': visibility,
      'classroomIds': classroomIds,
      if (preview.isNotEmpty) 'preview': preview,
      if (metadata.isNotEmpty) 'metadata': metadata,
      'likeUserIds': likeUserIds,
      'comments': comments.map((c) => c.toJson()).toList(),
      'teacherGenerated': teacherGenerated,
      'aiGenerated': aiGenerated,
      if (storyId != null) 'storyId': storyId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

String encodeJson(dynamic data) =>
    const JsonEncoder.withIndent('  ').convert(data);
