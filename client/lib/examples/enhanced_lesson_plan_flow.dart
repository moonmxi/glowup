import 'package:flutter/material.dart';
import '../models/lesson_plan.dart';
import '../models/lesson_plan_community.dart';
import '../models/story_asset.dart';
import '../models/teacher_story.dart';
import '../services/ai_case_analyzer.dart';
import '../services/ai_lesson_template_generator.dart';
import '../widgets/lesson_plan_preview.dart';

/// 教案创建增强流程 - 集成所有优化功能的示例
class EnhancedLessonPlanCreationFlow {
  final AiLessonTemplateGenerator _templateGenerator =
      AiLessonTemplateGenerator();
  final AiCaseAnalyzer _caseAnalyzer = AiCaseAnalyzer();

  /// 完整流程：从创意到发布
  /// 
  /// 1. 教师输入想法
  /// 2. AI生成教案模板
  /// 3. 生成资源使用指南
  /// 4. 预览和编辑
  /// 5. 发布到社区
  Future<void> runCompleteFlow({
    required BuildContext context,
    required String theme,
    required String gradeLevel,
    required TeacherStory story,
    required Map<String, StoryAsset> assets,
  }) async {
    // ========== 步骤1: 生成教案模板 ==========
    print('📝 步骤1：根据教师想法生成教案模板...');
    
    final lessonTemplate = await _templateGenerator.generateLessonTemplate(
      theme: theme,
      gradeLevel: gradeLevel,
      duration: 40, // 一节课
      availableResources: assets.values.map((a) => a.kind).toList(),
    );

    print('✅ 教案模板生成完成！');
    print('   - 教学目标: ${lessonTemplate.objectives.length}条');
    print('   - 教学步骤: ${lessonTemplate.steps.length}个');

    // ========== 步骤2: 为每个资源生成使用指南 ==========
    print('\n🎯 步骤2：生成资源使用指南...');
    
    final resourceGuides = <String, ResourceGuide>{};
    
    for (final entry in assets.entries) {
      final assetId = entry.key;
      final asset = entry.value;
      final guide = await _templateGenerator.generateResourceUsageGuide(
        resourceType: asset.kind,
        resourceDescription: asset.preview['summary']?.toString() ?? '',
        lessonContext: theme,
      );

      resourceGuides[assetId] = ResourceGuide(
        resourceId: assetId,
        timing: guide.timing,
        method: guide.method,
        interaction: guide.interaction,
        tips: guide.tips,
      );

      print('   ✓ ${asset.kind}资源使用指南已生成');
    }

    // ========== 步骤3: 创建LessonPlan对象 ==========
    print('\n📋 步骤3：整合教案数据...');
    
    final lessonPlan = LessonPlan(
      storyId: story.id,
      gradeLevel: gradeLevel,
      duration: lessonTemplate.duration,
      objectives: lessonTemplate.objectives,
      keyPoints: lessonTemplate.keyPoints,
      preparation: lessonTemplate.preparation,
      teachingSteps: _convertToTeachingSteps(lessonTemplate.steps, assets),
      homework: lessonTemplate.homework,
      usageGuides: resourceGuides,
    );

    // ========== 步骤4: 预览教案 ==========
    print('\n👀 步骤4：显示教案预览...');
    
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonPlanPreviewPage(
            lessonPlan: lessonPlan,
            assets: assets,
            onEdit: () {
              print('📝 教师选择编辑教案');
            },
            onPrint: () {
              print('🖨️ 打印教案');
              _printLessonPlan(lessonPlan);
            },
            onPublish: () {
              print('🌐 发布到社区');
              _publishToShowcase(lessonPlan, story);
            },
          ),
        ),
      );
    }
  }

  /// 新手教师快速模式
  /// 
  /// 提供简化版教案，降低使用门槛
  Future<SimplifiedLesson> runSimplifiedFlow({
    required String theme,
    required List<String> availableResources,
  }) async {
    print('🚀 新手模式：生成简化教案...');
    
    final simplifiedLesson =
        await _templateGenerator.generateSimplifiedLesson(
      theme: theme,
      availableResources: availableResources,
    );

    print('✅ 简化教案生成完成！');
    print('   三步教学法：');
    for (var i = 0; i < simplifiedLesson.steps.length; i++) {
      final step = simplifiedLesson.steps[i];
      print('   ${i + 1}. ${step.title} (${step.duration}分钟)');
    }

    return simplifiedLesson;
  }

  /// 分析社区优质案例
  /// 
  /// 定期运行，优化AI生成质量
  Future<void> runCaseAnalysisJob({
    required List<LessonPlanCommunityItem> topCases,
  }) async {
    print('\n📊 数据分析：分析优质教案案例...');
    
    // 分析高赞案例
    final caseAnalysis = await _caseAnalyzer.analyzeTopCases(
      topCases: topCases,
      minLikes: 10,
    );

    print('✅ 案例分析完成！');
    print('   分析案例数: ${caseAnalysis.totalAnalyzed}');
    print('   发现共同模式: ${caseAnalysis.commonPatterns.length}个');
    print('   成功要素: ${caseAnalysis.successFactors.length}个');

    // 收集用户反馈
    final allComments = topCases.expand((item) => item.comments).toList();
    
    if (allComments.isNotEmpty) {
      final feedbackInsights = await _caseAnalyzer.analyzeFeedback(
        comments: allComments,
      );

      print('\n💬 反馈分析完成！');
      print('   积极主题: ${feedbackInsights.positiveThemes.join(", ")}');
      print('   改进领域: ${feedbackInsights.improvementAreas.join(", ")}');

      // 生成优化建议
      final optimizationPrompt =
          await _caseAnalyzer.generateOptimizationPrompt(
        caseAnalysis: caseAnalysis,
        feedbackInsights: feedbackInsights,
      );

      print('\n🎯 优化建议已生成！');
      print('   系统提示词增强: ${optimizationPrompt.systemPromptEnhancement.substring(0, 100)}...');
      print('   内容生成规则: ${optimizationPrompt.contentGenerationRules.length}条');
      print('   质量检查清单: ${optimizationPrompt.qualityChecklist.length}项');

      // TODO: 将优化建议应用到AI生成器配置
      _applyOptimizationPrompt(optimizationPrompt);
    }
  }

  /// 评估新生成的教案质量
  Future<QualityScore> evaluateNewLessonPlan({
    required LessonPlan lessonPlan,
    required List<String> qualityCriteria,
  }) async {
    print('\n⚖️ 质量评估：评估教案质量...');
    
    final qualityScore = await _caseAnalyzer.evaluateLessonPlan(
      lessonPlanData: lessonPlan.toJson(),
      qualityCriteria: qualityCriteria,
    );

    print('✅ 质量评估完成！');
    print('   总分: ${qualityScore.overallScore}/100');
    print('   优点: ${qualityScore.strengths.length}个');
    print('   改进建议: ${qualityScore.suggestions.length}条');

    return qualityScore;
  }

  // ========== 辅助方法 ==========

  List<TeachingStep> _convertToTeachingSteps(
    List<LessonStep> templateSteps,
    Map<String, StoryAsset> assets,
  ) {
    return templateSteps.map((step) {
      return TeachingStep(
        title: step.title,
        duration: step.duration,
        activities: step.activities,
        resourceIds: _matchResourceIds(step.resources, assets),
        teacherActions: step.activities,
        studentActivities: [],
      );
    }).toList();
  }

  List<String> _matchResourceIds(
    List<String> resourceNames,
    Map<String, StoryAsset> assets,
  ) {
    // 简单匹配：根据资源类型匹配
    return assets.entries
        .where((entry) => resourceNames.any((name) =>
            name.toLowerCase().contains(entry.value.kind.toLowerCase())))
        .map((entry) => entry.key)
        .toList();
  }

  void _printLessonPlan(LessonPlan lessonPlan) {
    // TODO: 实现打印功能
    // 可以生成PDF或HTML格式
    print('🖨️ 打印教案：${lessonPlan.toJson()}');
  }

  void _publishToShowcase(LessonPlan lessonPlan, TeacherStory story) {
    // TODO: 调用API发布到Showcase
    print('🌐 发布教案到社区橱窗');
    print('   标题: ${story.title}');
    print('   主题: ${story.theme}');
  }

  void _applyOptimizationPrompt(OptimizationPrompt prompt) {
    // TODO: 将优化建议持久化并应用到AI生成器
    print('💾 保存优化配置...');
    // 可以保存到本地或云端配置
  }
}

/// 使用示例
class LessonPlanCreationExample {
  static Future<void> example() async {
    final flow = EnhancedLessonPlanCreationFlow();

    // 示例：创建一个音乐教案
    print('========== 示例：创建音乐教案 ==========\n');

    final simplifiedLesson = await flow.runSimplifiedFlow(
      theme: '认识中国传统乐器',
      availableResources: ['音频', '图片', '视频'],
    );

    print('\n========== 生成的简化教案 ==========');
    for (var i = 0; i < simplifiedLesson.steps.length; i++) {
      final step = simplifiedLesson.steps[i];
      print('\n第${i + 1}步：${step.title} (${step.duration}分钟)');
      print('活动：');
      for (final action in step.actions) {
        print('  • $action');
      }
      print('资源提示：${step.resourceTips}');
    }
  }
}
