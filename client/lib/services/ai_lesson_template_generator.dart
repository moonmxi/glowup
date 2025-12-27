import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// 教案模板生成器 - 为教师生成结构化教案和使用建议
class AiLessonTemplateGenerator {
  AiLessonTemplateGenerator({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// 生成完整的教案模板
  /// 
  /// 包含：教学目标、教学步骤、资源使用建议、课堂互动设计
  Future<LessonTemplate> generateLessonTemplate({
    required String theme,
    required String gradeLevel,
    required int duration, // 课程时长（分钟）
    required List<String> availableResources, // 可用的媒体资源类型
  }) async {
    final prompt = _buildTemplatePrompt(
      theme: theme,
      gradeLevel: gradeLevel,
      duration: duration,
      resources: availableResources,
    );

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是一位经验丰富的乡村艺术教育专家，擅长为资源有限的教师设计简单易行的教案。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('教案生成失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);
    
    return _parseLessonTemplate(content, theme, gradeLevel, duration);
  }

  /// 生成资源使用建议
  /// 
  /// 针对生成的视频、音频、图片等资源，给出具体的课堂使用方法
  Future<ResourceUsageGuide> generateResourceUsageGuide({
    required String resourceType, // video, audio, image
    required String resourceDescription,
    required String lessonContext,
  }) async {
    final prompt = '''
作为艺术教育顾问，请为以下资源提供详细的课堂使用建议：

资源类型：$resourceType
资源描述：$resourceDescription
课程背景：$lessonContext

请提供：
1. 使用时机（课程的哪个环节）
2. 使用方式（如何展示和引导）
3. 互动设计（如何让学生参与）
4. 注意事项（可能的问题和解决方案）

请以JSON格式返回，包含timing、method、interaction、tips四个字段。
''';

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是艺术教育资源使用专家，擅长帮助教师最大化利用多媒体资源。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.6,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('使用建议生成失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);
    
    return _parseUsageGuide(content, resourceType);
  }

  /// 生成简化版教案（适合新手教师）
  Future<SimplifiedLesson> generateSimplifiedLesson({
    required String theme,
    required List<String> availableResources,
  }) async {
    final prompt = '''
为乡村新手艺术教师设计一个极简教案：

主题：$theme
可用资源：${availableResources.join('、')}

要求：
1. 三步教学法（导入-展开-总结）
2. 每步不超过15分钟
3. 步骤清晰、易于执行
4. 包含资源使用提示

请以JSON格式返回，包含steps数组，每个step有title、duration、actions、resourceTips字段。
''';

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': '你是乡村教育简化专家。'},
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.5,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('简化教案生成失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);
    
    return _parseSimplifiedLesson(content, theme);
  }

  String _buildTemplatePrompt({
    required String theme,
    required String gradeLevel,
    required int duration,
    required List<String> resources,
  }) {
    return '''
请为乡村小学艺术课设计一个完整的教案：

课程主题：$theme
年级：$gradeLevel
课程时长：$duration分钟
可用资源：${resources.join('、')}

请设计包含以下内容的教案：
1. 教学目标（知识、技能、情感态度）
2. 教学重难点
3. 教学准备（资源使用清单）
4. 教学步骤（详细的时间分配和活动设计）
5. 课堂互动设计
6. 作业布置
7. 教学反思要点

要求：
- 适合农村教学环境，设备简单
- 步骤清晰，容易实施
- 注重学生参与和体验
- 考虑大班教学（30-50人）

请以JSON格式返回，包含objectives、keyPoints、preparation、steps、homework、reflection字段。
''';
  }

  String _extractContent(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      final message = first['message'];
      if (message is Map<String, dynamic>) {
        final content = message['content'];
        if (content is String) {
          return content.trim();
        }
      }
    }
    return '';
  }

  LessonTemplate _parseLessonTemplate(
    String content,
    String theme,
    String gradeLevel,
    int duration,
  ) {
    try {
      // 尝试提取JSON内容
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        return LessonTemplate(
          theme: theme,
          gradeLevel: gradeLevel,
          duration: duration,
          objectives: (parsed['objectives'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          keyPoints: parsed['keyPoints']?.toString() ?? '',
          preparation: (parsed['preparation'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          steps: (parsed['steps'] as List?)
                  ?.map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          homework: parsed['homework']?.toString() ?? '',
          reflection: parsed['reflection']?.toString() ?? '',
          rawContent: content,
        );
      }
    } catch (e) {
      // JSON解析失败，返回原始内容
    }

    // 如果JSON解析失败，返回基础模板
    return LessonTemplate(
      theme: theme,
      gradeLevel: gradeLevel,
      duration: duration,
      objectives: [],
      keyPoints: '',
      preparation: [],
      steps: [],
      homework: '',
      reflection: '',
      rawContent: content,
    );
  }

  ResourceUsageGuide _parseUsageGuide(String content, String resourceType) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        return ResourceUsageGuide(
          resourceType: resourceType,
          timing: parsed['timing']?.toString() ?? '',
          method: parsed['method']?.toString() ?? '',
          interaction: parsed['interaction']?.toString() ?? '',
          tips: parsed['tips']?.toString() ?? '',
        );
      }
    } catch (e) {
      // JSON解析失败
    }

    return ResourceUsageGuide(
      resourceType: resourceType,
      timing: '',
      method: '',
      interaction: '',
      tips: content,
    );
  }

  SimplifiedLesson _parseSimplifiedLesson(String content, String theme) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        return SimplifiedLesson(
          theme: theme,
          steps: (parsed['steps'] as List?)
                  ?.map((e) => SimpleLessonStep.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );
      }
    } catch (e) {
      // JSON解析失败
    }

    return SimplifiedLesson(theme: theme, steps: []);
  }
}

/// 完整教案模板
class LessonTemplate {
  const LessonTemplate({
    required this.theme,
    required this.gradeLevel,
    required this.duration,
    required this.objectives,
    required this.keyPoints,
    required this.preparation,
    required this.steps,
    required this.homework,
    required this.reflection,
    required this.rawContent,
  });

  final String theme;
  final String gradeLevel;
  final int duration;
  final List<String> objectives;
  final String keyPoints;
  final List<String> preparation;
  final List<LessonStep> steps;
  final String homework;
  final String reflection;
  final String rawContent;

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'gradeLevel': gradeLevel,
      'duration': duration,
      'objectives': objectives,
      'keyPoints': keyPoints,
      'preparation': preparation,
      'steps': steps.map((e) => e.toJson()).toList(),
      'homework': homework,
      'reflection': reflection,
    };
  }
}

/// 教学步骤
class LessonStep {
  const LessonStep({
    required this.title,
    required this.duration,
    required this.activities,
    required this.resources,
  });

  final String title;
  final int duration; // 分钟
  final List<String> activities;
  final List<String> resources;

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      title: json['title']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 10,
      activities: (json['activities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resources: (json['resources'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'activities': activities,
      'resources': resources,
    };
  }
}

/// 资源使用指南
class ResourceUsageGuide {
  const ResourceUsageGuide({
    required this.resourceType,
    required this.timing,
    required this.method,
    required this.interaction,
    required this.tips,
  });

  final String resourceType;
  final String timing; // 使用时机
  final String method; // 使用方式
  final String interaction; // 互动设计
  final String tips; // 注意事项

  Map<String, dynamic> toJson() {
    return {
      'resourceType': resourceType,
      'timing': timing,
      'method': method,
      'interaction': interaction,
      'tips': tips,
    };
  }
}

/// 简化教案
class SimplifiedLesson {
  const SimplifiedLesson({
    required this.theme,
    required this.steps,
  });

  final String theme;
  final List<SimpleLessonStep> steps;

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }
}

/// 简化教学步骤
class SimpleLessonStep {
  const SimpleLessonStep({
    required this.title,
    required this.duration,
    required this.actions,
    required this.resourceTips,
  });

  final String title;
  final int duration;
  final List<String> actions;
  final String resourceTips;

  factory SimpleLessonStep.fromJson(Map<String, dynamic> json) {
    return SimpleLessonStep(
      title: json['title']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 15,
      actions: (json['actions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resourceTips: json['resourceTips']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'actions': actions,
      'resourceTips': resourceTips,
    };
  }
}
