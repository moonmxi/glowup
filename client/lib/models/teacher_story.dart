class StoryStepModel {
  const StoryStepModel({
    required this.kind,
    required this.label,
    this.summary,
    this.completed = false,
    this.payload = const <String, dynamic>{},
  });

  final String kind;
  final String label;
  final String? summary;
  final bool completed;
  final Map<String, dynamic> payload;

  StoryStepModel copyWith({
    bool? completed,
    String? summary,
    Map<String, dynamic>? payload,
  }) {
    return StoryStepModel(
      kind: kind,
      label: label,
      summary: summary ?? this.summary,
      completed: completed ?? this.completed,
      payload: payload ?? this.payload,
    );
  }

  factory StoryStepModel.fromJson(Map<String, dynamic> json) {
    return StoryStepModel(
      kind: (json['kind'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      summary: json['summary'] as String?,
      completed: json['completed'] as bool? ?? false,
      payload:
          (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'label': label,
      if (summary != null) 'summary': summary,
      'completed': completed,
      'payload': payload,
    };
  }
}

class TeacherStory {
  const TeacherStory({
    required this.id,
    required this.title,
    this.theme,
    required this.classroomIds,
    required this.status,
    required this.createdAt,
    required this.steps,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final String? theme;
  final List<String> classroomIds;
  final String status;
  final DateTime createdAt;
  final List<StoryStepModel> steps;
  final Map<String, dynamic> metadata;

  TeacherStory copyWith({
    String? title,
    String? theme,
    List<String>? classroomIds,
    String? status,
    List<StoryStepModel>? steps,
    Map<String, dynamic>? metadata,
  }) {
    return TeacherStory(
      id: id,
      title: title ?? this.title,
      theme: theme ?? this.theme,
      classroomIds: classroomIds ?? this.classroomIds,
      status: status ?? this.status,
      createdAt: createdAt,
      steps: steps ?? this.steps,
      metadata: metadata ?? this.metadata,
    );
  }

  factory TeacherStory.fromJson(Map<String, dynamic> json) {
    return TeacherStory(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      theme: json['theme'] as String?,
      classroomIds: (json['classroomIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      status: (json['status'] as String?) ?? 'draft',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((step) => StoryStepModel.fromJson(step as Map<String, dynamic>))
          .toList(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (theme != null) 'theme': theme,
      'classroomIds': classroomIds,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'steps': steps.map((step) => step.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}
