import 'package:flutter/material.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import '../analysis/audio_analysis_page.dart';
import '../analysis/image_analysis_page.dart';

class ClassroomToolsPage extends StatelessWidget {
  const ClassroomToolsPage({super.key});

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
                    color: GlowUpColors.breeze.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '精准课堂工具',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '不依赖AI，也能让色彩与音乐课堂更严谨',
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
            _ToolCard(
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
            _ToolCard(
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GlowUpColors.mist,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GlowUpColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: GlowUpColors.bloom),
                      const SizedBox(width: 8),
                      Text(
                        '使用小贴士',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 色彩分析：拍摄学生作品后，点击画面任意位置获取颜色数据\n'
                    '• 音频分析：录制或导入音频文件，实时查看音高和节拍变化\n'
                    '• 离线使用：所有工具均支持离线模式，无需网络连接',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: GlowUpColors.dusk.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
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
      margin: const EdgeInsets.only(bottom: 16),
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: GlowUpColors.dusk.withValues(alpha: 0.75),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: gradient.first,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}