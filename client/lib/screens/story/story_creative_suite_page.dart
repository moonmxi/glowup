import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/story_orchestrator_state.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/lesson_plan_preview.dart';
import '../visual/image_studio_page.dart';
import '../video/video_studio_page.dart';
import '../music/music_studio_page.dart';

class StoryCreativeSuitePage extends StatelessWidget {
  const StoryCreativeSuitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小光创作工作室'),
        backgroundColor: GlowUpColors.card,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: const [
          _CreativeSuiteHeader(),
          SizedBox(height: 16),
          _CreativeToolCard(
            icon: Icons.brush,
            title: 'AI 生图画坊',
            description: '输入主题即可生成插画、板书或任务卡背景，适合投影或打印使用。',
            buttonLabel: '去生成插画',
            builder: ImageStudioPage.new,
          ),
          _CreativeToolCard(
            icon: Icons.movie_filter,
            title: '动画示范舱',
            description: '一键合成 30 秒课堂动画，让孩子先看到情境再参与讨论。',
            buttonLabel: '生成动画',
            builder: VideoStudioPage.new,
          ),
          _CreativeToolCard(
            icon: Icons.music_note,
            title: '音乐灵感角',
            description: '根据课堂主题自动配乐，支持自定义描述与氛围设置。',
            buttonLabel: '制作音乐',
            builder: MusicStudioPage.new,
          ),
          _LessonPlanGeneratorCard(),
        ],
      ),
    );
  }
}

class _CreativeSuiteHeader extends StatelessWidget {
  const _CreativeSuiteHeader();

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlowUpColors.sunset.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '小光创作工作室',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '插画、动画、音乐一站式生成，老师可以按课堂需要自定提示词。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: GlowUpColors.dusk.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreativeToolCard extends StatelessWidget {
  const _CreativeToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: GlowUpColors.primary.withValues(alpha: 0.12),
                  child: Icon(icon, color: GlowUpColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => builder()),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// 教案生成卡片
class _LessonPlanGeneratorCard extends StatelessWidget {
  const _LessonPlanGeneratorCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryOrchestratorState>(
      builder: (context, storyState, _) {
        final hasActiveStory = storyState.activeStory != null;
        final hasAssets = storyState.assets.isNotEmpty;
        final isGenerating = storyState.isGeneratingLesson;

        return GlowCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: GlowUpColors.secondary.withValues(alpha: 0.12),
                      child: Icon(Icons.article, color: GlowUpColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI 教案生成器',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '根据已生成的资源，自动创建完整教案，包含教学目标、步骤和资源使用建议。',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!hasActiveStory)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '请先在"小光助教台"创建教学故事',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!hasAssets)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '建议先生成一些媒体资源（图片、视频、音乐），教案会更丰富',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: hasActiveStory && !isGenerating
                      ? () => _generateLessonPlan(context, storyState)
                      : null,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(isGenerating ? '生成中...' : '生成教案'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateLessonPlan(
    BuildContext context,
    StoryOrchestratorState storyState,
  ) async {
    // 显示配置对话框
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _LessonConfigDialog(
        storyTitle: storyState.activeStory?.title ?? '',
      ),
    );

    if (config == null || !context.mounted) return;

    final gradeLevel = config['gradeLevel'] as String;
    final duration = config['duration'] as int;

    // 生成教案
    final success = await storyState.generateFullLessonPlan(
      gradeLevel: gradeLevel,
      duration: duration,
    );

    if (!context.mounted) return;

    if (success && storyState.currentLessonPlan != null) {
      // 跳转到预览页面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonPlanPreviewPage(
            lessonPlan: storyState.currentLessonPlan!,
            assets: storyState.assets,
            onEdit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('编辑功能即将推出')),
              );
            },
            onPrint: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('打印功能开发中')),
              );
            },
            onPublish: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('发布功能开发中')),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(storyState.error ?? '教案生成失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 教案配置对话框
class _LessonConfigDialog extends StatefulWidget {
  const _LessonConfigDialog({required this.storyTitle});

  final String storyTitle;

  @override
  State<_LessonConfigDialog> createState() => _LessonConfigDialogState();
}

class _LessonConfigDialogState extends State<_LessonConfigDialog> {
  String _gradeLevel = '三年级';
  int _duration = 40;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('教案配置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '为"${widget.storyTitle}"生成教案',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Text(
            '年级',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _gradeLevel,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: '一年级', child: Text('一年级')),
              DropdownMenuItem(value: '二年级', child: Text('二年级')),
              DropdownMenuItem(value: '三年级', child: Text('三年级')),
              DropdownMenuItem(value: '四年级', child: Text('四年级')),
              DropdownMenuItem(value: '五年级', child: Text('五年级')),
              DropdownMenuItem(value: '六年级', child: Text('六年级')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _gradeLevel = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            '课程时长',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _duration,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 35, child: Text('35分钟')),
              DropdownMenuItem(value: 40, child: Text('40分钟')),
              DropdownMenuItem(value: 45, child: Text('45分钟')),
              DropdownMenuItem(value: 60, child: Text('60分钟')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _duration = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'gradeLevel': _gradeLevel,
              'duration': _duration,
            });
          },
          child: const Text('生成'),
        ),
      ],
    );
  }
}
