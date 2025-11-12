import 'package:flutter/material.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import '../../constants/app_constants.dart';
import '../analysis/lesson_planner_page.dart';
import '../analysis/audio_analysis_page.dart';
import 'music_studio_page.dart';

class MusicPipelinePage extends StatefulWidget {
  const MusicPipelinePage({super.key});

  @override
  State<MusicPipelinePage> createState() => _MusicPipelinePageState();
}

class _MusicPipelinePageState extends State<MusicPipelinePage> {
  int _currentStep = 0;
  final List<PipelineStep> _steps = [
    PipelineStep(
      title: '备课准备',
      description: '生成音乐课教案',
      icon: Icons.edit_note,
      color: GlowUpColors.bloom,
      isCompleted: false,
    ),
    PipelineStep(
      title: '音准练习',
      description: '分析音频节奏',
      icon: Icons.graphic_eq,
      color: GlowUpColors.breeze,
      isCompleted: false,
    ),
    PipelineStep(
      title: 'AI作曲',
      description: '创作课堂音乐',
      icon: Icons.music_note,
      color: GlowUpColors.lavender,
      isCompleted: false,
    ),
    PipelineStep(
      title: '教学实践',
      description: '带领同学们唱歌',
      icon: Icons.school,
      color: GlowUpColors.sage,
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.musicPipelineName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              _buildStepsList(),
              const SizedBox(height: 24),
              _buildCurrentStepCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlowCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GlowUpColors.lavender.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.queue_music,
              size: 32,
              color: GlowUpColors.lavender,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.musicPipelineName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '从备课到上课的完整音乐课流程',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GlowUpColors.dusk.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '课程进度',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_steps.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = _steps[index].isCompleted;
              
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? GlowUpColors.sage
                            : isActive
                                ? _steps[index].color
                                : GlowUpColors.mist,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : _steps[index].icon,
                        size: 18,
                        color: isCompleted || isActive
                            ? Colors.white
                            : GlowUpColors.dusk.withValues(alpha: 0.5),
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: _steps[index].isCompleted
                                ? GlowUpColors.sage
                                : GlowUpColors.mist,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '流程步骤',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_steps.length, (index) {
          final step = _steps[index];
          final isActive = index == _currentStep;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlowCard(
              onTap: () => _navigateToStep(index),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: step.isCompleted
                          ? GlowUpColors.sage.withValues(alpha: 0.2)
                          : isActive
                              ? step.color.withValues(alpha: 0.2)
                              : GlowUpColors.mist.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      step.isCompleted ? Icons.check : step.icon,
                      color: step.isCompleted
                          ? GlowUpColors.sage
                          : isActive
                              ? step.color
                              : GlowUpColors.dusk.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? step.color
                                    : step.isCompleted
                                        ? GlowUpColors.sage
                                        : null,
                              ),
                        ),
                        Text(
                          step.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: GlowUpColors.dusk.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '进行中',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: step.color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  if (step.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: GlowUpColors.sage.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '已完成',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: GlowUpColors.sage,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCurrentStepCard() {
    final currentStep = _steps[_currentStep];
    
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                currentStep.icon,
                color: currentStep.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '当前步骤：${currentStep.title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: currentStep.color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentStep.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToStep(_currentStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentStep.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_getStepButtonText(_currentStep)),
            ),
          ),
          const SizedBox(height: 12),
          if (_currentStep > 0)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = (_currentStep - 1).clamp(0, _steps.length - 1);
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: currentStep.color),
                  foregroundColor: currentStep.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('上一步'),
              ),
            ),
        ],
      ),
    );
  }

  String _getStepButtonText(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return '生成教案';
      case 1:
        return '分析音频';
      case 2:
        return '创作音乐';
      case 3:
        return '开始教学';
      default:
        return '开始';
    }
  }

  void _navigateToStep(int stepIndex) {
    Widget? targetPage;
    
    switch (stepIndex) {
      case 0:
        targetPage = const LessonPlannerPage();
        break;
      case 1:
        targetPage = const AudioAnalysisPage();
        break;
      case 2:
        targetPage = const MusicStudioPage();
        break;
      case 3:
        _showTeachingDialog();
        return;
    }
    
    if (targetPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => targetPage!),
      ).then((_) {
        setState(() {
          _steps[stepIndex].isCompleted = true;
          if (stepIndex == _currentStep && _currentStep < _steps.length - 1) {
            _currentStep++;
          }
        });
      });
    }
  }

  void _showTeachingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开始教学'),
        content: const Text('现在可以使用准备好的教案和音乐，带领同学们开始音乐课了！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _steps[3].isCompleted = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('音乐课流程已完成！')),
              );
            },
            child: const Text('完成教学'),
          ),
        ],
      ),
    );
  }
}

class PipelineStep {
  PipelineStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isCompleted,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  bool isCompleted;
}