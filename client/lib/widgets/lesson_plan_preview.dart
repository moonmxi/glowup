import 'package:flutter/material.dart';
import '../models/lesson_plan.dart';
import '../models/story_asset.dart';

/// 教案预览页面 - 提供打印友好的教案预览
class LessonPlanPreviewPage extends StatelessWidget {
  const LessonPlanPreviewPage({
    super.key,
    required this.lessonPlan,
    required this.assets,
    this.onEdit,
    this.onPrint,
    this.onPublish,
  });

  final LessonPlan lessonPlan;
  final Map<String, StoryAsset> assets;
  final VoidCallback? onEdit;
  final VoidCallback? onPrint;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教案预览'),
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: '编辑教案',
            ),
          if (onPrint != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: onPrint,
              tooltip: '打印教案',
            ),
          if (onPublish != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onPublish,
              tooltip: '发布到橱窗',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCover(context),
                  const SizedBox(height: 40),
                  _buildBasicInfo(context),
                  const SizedBox(height: 32),
                  _buildObjectives(context),
                  const SizedBox(height: 32),
                  _buildKeyPoints(context),
                  const SizedBox(height: 32),
                  _buildPreparation(context),
                  const SizedBox(height: 32),
                  _buildTeachingSteps(context),
                  const SizedBox(height: 32),
                  if (lessonPlan.homework != null) ...[
                    _buildHomework(context),
                    const SizedBox(height: 32),
                  ],
                  if (lessonPlan.usageGuides.isNotEmpty) ...[
                    _buildResourceGuides(context),
                    const SizedBox(height: 32),
                  ],
                  if (lessonPlan.teacherNotes != null) ...[
                    _buildTeacherNotes(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '艺术教案',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '主题', // 这里应该从TeacherStory获取标题
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.school,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                lessonPlan.gradeLevel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.access_time,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '${lessonPlan.duration}分钟',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '基本信息'),
        const SizedBox(height: 12),
        _buildInfoRow('年级', lessonPlan.gradeLevel),
        _buildInfoRow('课时', '${lessonPlan.duration}分钟'),
      ],
    );
  }

  Widget _buildObjectives(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '教学目标'),
        const SizedBox(height: 12),
        ...lessonPlan.objectives.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}. ',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildKeyPoints(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '教学重难点'),
        const SizedBox(height: 12),
        Text(
          lessonPlan.keyPoints,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPreparation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '教学准备'),
        const SizedBox(height: 12),
        ...lessonPlan.preparation.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTeachingSteps(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '教学步骤'),
        const SizedBox(height: 16),
        ...lessonPlan.teachingSteps.asMap().entries.map((entry) {
          return _buildStepCard(context, entry.key + 1, entry.value);
        }),
      ],
    );
  }

  Widget _buildStepCard(BuildContext context, int stepNumber, TeachingStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${step.duration}分钟'),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (step.teacherActions != null &&
                step.teacherActions!.isNotEmpty) ...[
              Text(
                '教师活动:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              ...step.teacherActions!.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(action)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (step.studentActivities != null &&
                step.studentActivities!.isNotEmpty) ...[
              Text(
                '学生活动:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 8),
              ...step.studentActivities!.map((activity) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(activity)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (step.activities.isNotEmpty) ...[
              Text(
                '活动内容:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...step.activities.map((activity) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(activity)),
                      ],
                    ),
                  )),
            ],
            if (step.interactionTips != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.interactionTips!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (step.resourceIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: step.resourceIds.map((resourceId) {
                  final asset = assets[resourceId];
                  return Chip(
                    avatar: Icon(
                      _getResourceIcon(asset?.kind ?? 'general'),
                      size: 18,
                    ),
                    label: Text(asset?.kind ?? '资源'),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomework(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '课后作业'),
        const SizedBox(height: 12),
        Text(
          lessonPlan.homework!,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildResourceGuides(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '资源使用指南'),
        const SizedBox(height: 16),
        ...lessonPlan.usageGuides.entries.map((entry) {
          final guide = entry.value;
          final asset = assets[entry.key];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getResourceIcon(asset?.kind ?? 'general')),
                      const SizedBox(width: 8),
                      Text(
                        asset?.kind ?? '资源',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideItem('使用时机', guide.timing, Icons.schedule),
                  _buildGuideItem('使用方式', guide.method, Icons.play_circle),
                  _buildGuideItem('互动设计', guide.interaction, Icons.groups),
                  _buildGuideItem('注意事项', guide.tips, Icons.info_outline),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGuideItem(String label, String content, IconData icon) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherNotes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                '教师备注',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lessonPlan.teacherNotes!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String kind) {
    switch (kind) {
      case 'video':
        return Icons.videocam;
      case 'audio':
      case 'music':
        return Icons.music_note;
      case 'image':
        return Icons.image;
      case 'visual':
        return Icons.palette;
      default:
        return Icons.attach_file;
    }
  }
}
