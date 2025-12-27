import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import 'artwork_review_page.dart';
import 'lesson_planner_page.dart';
import '../music/music_pipeline_page.dart';

class TeacherToolsPage extends StatelessWidget {
  const TeacherToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.teacherToolsModule),
        backgroundColor: GlowUpColors.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  child: const Icon(Icons.school, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '教师专用工具',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '专为老师设计的教学辅助工具',
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
            
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI辅助工具',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildToolCard(
                    context,
                    icon: Icons.auto_awesome,
                    title: '作品点评助手',
                    description: '让${AppConstants.aiName}帮你点评学生作品',
                    color: GlowUpColors.breeze,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ArtworkReviewPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildToolCard(
                    context,
                    icon: Icons.menu_book,
                    title: '智能教案生成',
                    description: '快速生成45分钟完整教案',
                    color: GlowUpColors.lavender,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LessonPlannerPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildToolCard(
                    context,
                    icon: Icons.queue_music,
                    title: AppConstants.musicPipelineName,
                    description: '从备课到上课的完整音乐课流程指导',
                    color: GlowUpColors.bloom,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MusicPipelinePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '课堂管理工具',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildToolCard(
                    context,
                    icon: Icons.timer,
                    title: '课堂计时器',
                    description: '管理课堂时间，提高教学效率',
                    color: GlowUpColors.peach,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('课堂计时器功能即将上线')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildToolCard(
                    context,
                    icon: Icons.groups,
                    title: '分组助手',
                    description: '智能分组，促进合作学习',
                    color: GlowUpColors.mint,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('分组助手功能即将上线')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildToolCard(
                    context,
                    icon: Icons.assessment,
                    title: '课堂评价',
                    description: '记录学生表现，生成评价报告',
                    color: GlowUpColors.sunset,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('课堂评价功能即将上线')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GlowUpColors.lavender.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlowUpColors.lavender.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: GlowUpColors.lavender),
                      const SizedBox(width: 8),
                      Text(
                        '教师工具使用提示',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• AI辅助工具可以帮助您更好地评价学生作品\n'
                    '• 智能教案生成器提供完整的45分钟课程结构\n'
                    '• 课堂管理工具让教学更加高效有序\n'
                    '• 所有工具都针对真实课堂环境优化设计',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
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

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GlowUpColors.dusk.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlowUpColors.dusk.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
