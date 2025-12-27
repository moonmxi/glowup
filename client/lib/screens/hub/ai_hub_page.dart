import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../theme/glowup_theme.dart';
import '../music/music_studio_page.dart';
import '../video/video_studio_page.dart';
import '../visual/image_studio_page.dart';
import '../analysis/teacher_tools_page.dart';
import '../analysis/image_analysis_page.dart';
import '../analysis/audio_analysis_page.dart';

class AiHubPage extends StatelessWidget {
  const AiHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GlowUpColors.lavender.withValues(alpha: 0.3),
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
                        '${AppConstants.aiName}的AI魔法',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '让AI成为你的教学助手，轻松创造精彩课堂',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: GlowUpColors.dusk.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _HubCard(
              icon: Icons.movie_filter,
              title: '动画魔法盒',
              description: '生成随堂动画，像讲故事一样带孩子走进新主题。',
              gradient: const [Color(0xFFB4E9E2), Color(0xFF7FC6C9)],
              buttonLabel: '开启动画',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VideoStudioPage()),
                );
              },
            ),
            _HubCard(
              icon: Icons.brush,
              title: '小画廊工作台',
              description: '一键生成插画、板书或任务卡背景，适合打印和投影。',
              gradient: const [Color(0xFFF9DDE2), Color(0xFFE6B3C0)],
              buttonLabel: '去画一画',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImageStudioPage()),
                );
              },
            ),
            _HubCard(
              icon: Icons.music_note,
              title: '音乐角伴奏台',
              description: '为早读、律动或情绪调节配上轻松的音乐背景。',
              gradient: const [Color(0xFFD8D6F7), Color(0xFFB7B2E8)],
              buttonLabel: '制作音乐',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MusicStudioPage()),
                );
              },
            ),
            _HubCard(
              icon: Icons.menu_book,
              title: '教师工具箱',
              description: '本地图片AI点评孩子画作，并按需求生成45分钟教案。',
              gradient: const [Color(0xFFFDE6B2), Color(0xFFF5C46B)],
              buttonLabel: '去试用',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TeacherToolsPage()),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              '精准课堂工具',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '不依赖 AI，也能让色彩与音乐课堂更严谨：测颜色、看音高，一步到位。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GlowUpColors.dusk.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            _HubCard(
              icon: Icons.colorize,
              title: '色彩小助手',
              description: '导入作品照片，点击即可得到精准 RGB / 亮度数据，指导孩子调色。',
              gradient: const [Color(0xFFB8E9FF), Color(0xFFA7C7F9)],
              buttonLabel: '分析色彩',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImageAnalysisPage()),
                );
              },
            ),
            _HubCard(
              icon: Icons.graphic_eq,
              title: '节奏实验室',
              description: '导入音频即可查看实时音量与音高曲线，帮助孩子唱准节奏。',
              gradient: const [Color(0xFFB9F3D0), Color(0xFF8BD8B5)],
              buttonLabel: '分析节奏',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AudioAnalysisPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              child: Icon(icon, size: 28, color: GlowUpColors.dusk),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GlowUpColors.dusk,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GlowUpColors.dusk.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: GlowUpColors.dusk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
