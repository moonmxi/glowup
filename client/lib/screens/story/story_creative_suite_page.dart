import 'package:flutter/material.dart';

import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
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
