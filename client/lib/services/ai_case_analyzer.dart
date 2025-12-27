import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_plan_community.dart';
import 'api_config.dart';

/// AI案例分析服务 - 分析优质教案，反哺模型训练
class AiCaseAnalyzer {
  AiCaseAnalyzer({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// 分析高赞教案案例，提取成功要素
  /// 
  /// 用于识别优质教案的共同特征，优化后续生成
  Future<CaseAnalysisResult> analyzeTopCases({
    required List<LessonPlanCommunityItem> topCases,
    int minLikes = 10,
  }) async {
    // 筛选高质量案例
    final qualifiedCases = topCases
        .where((item) =>
            item.likes >= minLikes &&
            item.rating >= 4.0 &&
            item.ratingCount >= 3)
        .toList();

    if (qualifiedCases.isEmpty) {
      return CaseAnalysisResult(
        totalAnalyzed: 0,
        commonPatterns: [],
        successFactors: [],
        recommendations: [],
      );
    }

    // 构建分析提示
    final caseSummaries = qualifiedCases.map((item) {
      return {
        'title': item.title,
        'theme': item.theme,
        'gradeLevel': item.gradeLevel,
        'duration': item.duration,
        'rating': item.rating,
        'likes': item.likes,
        'tags': item.tags,
        'difficultyLevel': item.difficultyLevel,
      };
    }).toList();

    final prompt = '''
作为教育数据分析专家，请分析以下${qualifiedCases.length}个高赞乡村艺术教案：

${jsonEncode(caseSummaries)}

请识别：
1. 共同模式（commonPatterns）：这些优质教案的共同特征
2. 成功要素（successFactors）：为什么这些教案受欢迎
3. 改进建议（recommendations）：如何优化未来的教案生成

请以JSON格式返回，包含commonPatterns、successFactors、recommendations三个数组字段。
''';

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是教育数据分析专家，擅长从成功案例中提取可复用的模式。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('案例分析失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);

    return _parseAnalysisResult(content, qualifiedCases.length);
  }

  /// 分析用户反馈，识别需要改进的方向
  Future<FeedbackInsights> analyzeFeedback({
    required List<LessonPlanComment> comments,
  }) async {
    if (comments.isEmpty) {
      return FeedbackInsights(
        positiveThemes: [],
        improvementAreas: [],
        commonRequests: [],
      );
    }

    // 提取评论内容
    final commentTexts = comments.map((c) {
      return {
        'content': c.content,
        'rating': c.rating,
        'experience': c.teachingExperience,
        'modifications': c.modifications,
      };
    }).toList();

    final prompt = '''
分析以下教师对乡村艺术教案的反馈评论：

${jsonEncode(commentTexts)}

请提取：
1. 积极主题（positiveThemes）：教师们普遍认可的方面
2. 改进领域（improvementAreas）：需要优化的方面
3. 常见需求（commonRequests）：教师们经常提出的具体需求

请以JSON格式返回，包含positiveThemes、improvementAreas、commonRequests三个数组字段。
''';

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是用户体验研究专家，擅长从反馈中提炼洞察。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('反馈分析失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);

    return _parseFeedbackInsights(content);
  }

  /// 生成内容优化建议
  /// 
  /// 基于分析结果，为AI生成器提供优化提示
  Future<OptimizationPrompt> generateOptimizationPrompt({
    required CaseAnalysisResult caseAnalysis,
    required FeedbackInsights feedbackInsights,
  }) async {
    final prompt = '''
基于以下分析数据，为乡村艺术教案生成器创建优化提示：

成功案例分析：
- 共同模式：${caseAnalysis.commonPatterns.join('、')}
- 成功要素：${caseAnalysis.successFactors.join('、')}

用户反馈洞察：
- 积极方面：${feedbackInsights.positiveThemes.join('、')}
- 改进领域：${feedbackInsights.improvementAreas.join('、')}
- 常见需求：${feedbackInsights.commonRequests.join('、')}

请生成：
1. 系统提示词优化（systemPromptEnhancement）
2. 内容生成规则（contentGenerationRules）
3. 质量检查清单（qualityChecklist）

请以JSON格式返回。
''';

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是AI提示词工程专家，擅长优化生成模型的指令。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.4,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('优化建议生成失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);

    return _parseOptimizationPrompt(content);
  }

  /// 评估教案质量
  /// 
  /// 根据学习到的标准评估新生成的教案
  Future<QualityScore> evaluateLessonPlan({
    required Map<String, dynamic> lessonPlanData,
    required List<String> qualityCriteria,
  }) async {
    final prompt = '''
根据以下质量标准评估这个乡村艺术教案：

教案内容：
${jsonEncode(lessonPlanData)}

质量标准：
${qualityCriteria.map((c) => '- $c').join('\n')}

请评分并给出具体反馈。返回JSON格式，包含：
- overallScore (1-100)
- criteriaScores (每个标准的得分)
- strengths (优点列表)
- weaknesses (不足列表)
- suggestions (改进建议)
''';

    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是教案质量评估专家。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('质量评估失败: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data);

    return _parseQualityScore(content);
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

  CaseAnalysisResult _parseAnalysisResult(String content, int totalAnalyzed) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        return CaseAnalysisResult(
          totalAnalyzed: totalAnalyzed,
          commonPatterns: (parsed['commonPatterns'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          successFactors: (parsed['successFactors'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          recommendations: (parsed['recommendations'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        );
      }
    } catch (e) {
      // JSON解析失败
    }

    return CaseAnalysisResult(
      totalAnalyzed: totalAnalyzed,
      commonPatterns: [],
      successFactors: [],
      recommendations: [],
    );
  }

  FeedbackInsights _parseFeedbackInsights(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        return FeedbackInsights(
          positiveThemes: (parsed['positiveThemes'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          improvementAreas: (parsed['improvementAreas'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          commonRequests: (parsed['commonRequests'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        );
      }
    } catch (e) {
      // JSON解析失败
    }

    return FeedbackInsights(
      positiveThemes: [],
      improvementAreas: [],
      commonRequests: [],
    );
  }

  OptimizationPrompt _parseOptimizationPrompt(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        return OptimizationPrompt(
          systemPromptEnhancement:
              parsed['systemPromptEnhancement']?.toString() ?? '',
          contentGenerationRules: (parsed['contentGenerationRules'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          qualityChecklist: (parsed['qualityChecklist'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        );
      }
    } catch (e) {
      // JSON解析失败
    }

    return OptimizationPrompt(
      systemPromptEnhancement: content,
      contentGenerationRules: [],
      qualityChecklist: [],
    );
  }

  QualityScore _parseQualityScore(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        return QualityScore(
          overallScore: (parsed['overallScore'] as num?)?.toInt() ?? 0,
          criteriaScores:
              (parsed['criteriaScores'] as Map<String, dynamic>?) ?? {},
          strengths: (parsed['strengths'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          weaknesses: (parsed['weaknesses'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          suggestions: (parsed['suggestions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        );
      }
    } catch (e) {
      // JSON解析失败
    }

    return QualityScore(
      overallScore: 0,
      criteriaScores: {},
      strengths: [],
      weaknesses: [],
      suggestions: [],
    );
  }
}

/// 案例分析结果
class CaseAnalysisResult {
  const CaseAnalysisResult({
    required this.totalAnalyzed,
    required this.commonPatterns,
    required this.successFactors,
    required this.recommendations,
  });

  final int totalAnalyzed;
  final List<String> commonPatterns;
  final List<String> successFactors;
  final List<String> recommendations;
}

/// 反馈洞察
class FeedbackInsights {
  const FeedbackInsights({
    required this.positiveThemes,
    required this.improvementAreas,
    required this.commonRequests,
  });

  final List<String> positiveThemes;
  final List<String> improvementAreas;
  final List<String> commonRequests;
}

/// 优化提示
class OptimizationPrompt {
  const OptimizationPrompt({
    required this.systemPromptEnhancement,
    required this.contentGenerationRules,
    required this.qualityChecklist,
  });

  final String systemPromptEnhancement;
  final List<String> contentGenerationRules;
  final List<String> qualityChecklist;
}

/// 质量评分
class QualityScore {
  const QualityScore({
    required this.overallScore,
    required this.criteriaScores,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });

  final int overallScore; // 1-100
  final Map<String, dynamic> criteriaScores;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
}
