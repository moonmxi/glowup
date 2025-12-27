/// 教案模型 - 扩展TeacherStory，添加教案特定字段
class LessonPlan {
  const LessonPlan({
    required this.storyId,
    required this.gradeLevel,
    required this.duration,
    required this.objectives,
    required this.keyPoints,
    required this.preparation,
    required this.teachingSteps,
    this.homework,
    this.reflectionNotes,
    this.usageGuides = const {},
    this.teacherNotes,
    this.printLayout,
    this.isPublished = false,
    this.publishedAt,
  });

  final String storyId; // 关联的TeacherStory ID
  final String gradeLevel; // 年级（如"三年级"）
  final int duration; // 课程时长（分钟）
  final List<String> objectives; // 教学目标
  final String keyPoints; // 教学重难点
  final List<String> preparation; // 教学准备清单
  final List<TeachingStep> teachingSteps; // 教学步骤
  final String? homework; // 课后作业
  final String? reflectionNotes; // 教学反思
  final Map<String, ResourceGuide> usageGuides; // 资源使用指南（资源ID -> 指南）
  final String? teacherNotes; // 教师备注
  final PrintLayout? printLayout; // 打印布局设置
  final bool isPublished; // 是否已发布到橱窗
  final DateTime? publishedAt; // 发布时间

  LessonPlan copyWith({
    String? gradeLevel,
    int? duration,
    List<String>? objectives,
    String? keyPoints,
    List<String>? preparation,
    List<TeachingStep>? teachingSteps,
    String? homework,
    String? reflectionNotes,
    Map<String, ResourceGuide>? usageGuides,
    String? teacherNotes,
    PrintLayout? printLayout,
    bool? isPublished,
    DateTime? publishedAt,
  }) {
    return LessonPlan(
      storyId: storyId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      duration: duration ?? this.duration,
      objectives: objectives ?? this.objectives,
      keyPoints: keyPoints ?? this.keyPoints,
      preparation: preparation ?? this.preparation,
      teachingSteps: teachingSteps ?? this.teachingSteps,
      homework: homework ?? this.homework,
      reflectionNotes: reflectionNotes ?? this.reflectionNotes,
      usageGuides: usageGuides ?? this.usageGuides,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      printLayout: printLayout ?? this.printLayout,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  factory LessonPlan.fromJson(Map<String, dynamic> json) {
    return LessonPlan(
      storyId: json['storyId'] as String,
      gradeLevel: (json['gradeLevel'] as String?) ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 40,
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      keyPoints: (json['keyPoints'] as String?) ?? '',
      preparation: (json['preparation'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      teachingSteps: (json['teachingSteps'] as List<dynamic>?)
              ?.map((e) => TeachingStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      homework: json['homework'] as String?,
      reflectionNotes: json['reflectionNotes'] as String?,
      usageGuides: (json['usageGuides'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, ResourceGuide.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      teacherNotes: json['teacherNotes'] as String?,
      printLayout: json['printLayout'] != null
          ? PrintLayout.fromJson(json['printLayout'] as Map<String, dynamic>)
          : null,
      isPublished: json['isPublished'] as bool? ?? false,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'gradeLevel': gradeLevel,
      'duration': duration,
      'objectives': objectives,
      'keyPoints': keyPoints,
      'preparation': preparation,
      'teachingSteps': teachingSteps.map((e) => e.toJson()).toList(),
      if (homework != null) 'homework': homework,
      if (reflectionNotes != null) 'reflectionNotes': reflectionNotes,
      'usageGuides':
          usageGuides.map((k, v) => MapEntry(k, v.toJson())),
      if (teacherNotes != null) 'teacherNotes': teacherNotes,
      if (printLayout != null) 'printLayout': printLayout!.toJson(),
      'isPublished': isPublished,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    };
  }
}

/// 教学步骤
class TeachingStep {
  const TeachingStep({
    required this.title,
    required this.duration,
    required this.activities,
    required this.resourceIds,
    this.interactionTips,
    this.teacherActions,
    this.studentActivities,
  });

  final String title; // 步骤标题（如"导入环节"）
  final int duration; // 时长（分钟）
  final List<String> activities; // 活动列表
  final List<String> resourceIds; // 使用的资源ID列表
  final String? interactionTips; // 互动提示
  final List<String>? teacherActions; // 教师行为
  final List<String>? studentActivities; // 学生活动

  factory TeachingStep.fromJson(Map<String, dynamic> json) {
    return TeachingStep(
      title: (json['title'] as String?) ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 10,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resourceIds: (json['resourceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      interactionTips: json['interactionTips'] as String?,
      teacherActions: (json['teacherActions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      studentActivities: (json['studentActivities'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'activities': activities,
      'resourceIds': resourceIds,
      if (interactionTips != null) 'interactionTips': interactionTips,
      if (teacherActions != null) 'teacherActions': teacherActions,
      if (studentActivities != null) 'studentActivities': studentActivities,
    };
  }
}

/// 资源使用指南
class ResourceGuide {
  const ResourceGuide({
    required this.resourceId,
    required this.timing,
    required this.method,
    required this.interaction,
    required this.tips,
  });

  final String resourceId;
  final String timing; // 使用时机
  final String method; // 使用方式
  final String interaction; // 互动设计
  final String tips; // 注意事项

  factory ResourceGuide.fromJson(Map<String, dynamic> json) {
    return ResourceGuide(
      resourceId: (json['resourceId'] as String?) ?? '',
      timing: (json['timing'] as String?) ?? '',
      method: (json['method'] as String?) ?? '',
      interaction: (json['interaction'] as String?) ?? '',
      tips: (json['tips'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resourceId': resourceId,
      'timing': timing,
      'method': method,
      'interaction': interaction,
      'tips': tips,
    };
  }
}

/// 打印布局设置
class PrintLayout {
  const PrintLayout({
    this.includeCover = true,
    this.includeObjectives = true,
    this.includeSteps = true,
    this.includeResourceGuides = true,
    this.includeHomework = true,
    this.pageSize = 'A4',
    this.fontSize = 'medium',
  });

  final bool includeCover; // 包含封面
  final bool includeObjectives; // 包含教学目标
  final bool includeSteps; // 包含教学步骤
  final bool includeResourceGuides; // 包含资源指南
  final bool includeHomework; // 包含作业
  final String pageSize; // 页面大小
  final String fontSize; // 字体大小

  factory PrintLayout.fromJson(Map<String, dynamic> json) {
    return PrintLayout(
      includeCover: json['includeCover'] as bool? ?? true,
      includeObjectives: json['includeObjectives'] as bool? ?? true,
      includeSteps: json['includeSteps'] as bool? ?? true,
      includeResourceGuides: json['includeResourceGuides'] as bool? ?? true,
      includeHomework: json['includeHomework'] as bool? ?? true,
      pageSize: (json['pageSize'] as String?) ?? 'A4',
      fontSize: (json['fontSize'] as String?) ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeCover': includeCover,
      'includeObjectives': includeObjectives,
      'includeSteps': includeSteps,
      'includeResourceGuides': includeResourceGuides,
      'includeHomework': includeHomework,
      'pageSize': pageSize,
      'fontSize': fontSize,
    };
  }
}
