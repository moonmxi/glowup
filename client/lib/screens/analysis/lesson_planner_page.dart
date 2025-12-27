import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/ai_analyzers.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class LessonPlannerPage extends StatefulWidget {
  const LessonPlannerPage({super.key});

  @override
  State<LessonPlannerPage> createState() => _LessonPlannerPageState();
}

class _LessonPlannerPageState extends State<LessonPlannerPage> {
  final _lessonPlanner = AiLessonPlanner();
  String _lessonResult = '';
  bool _isGenerating = false;

  final _subjectController = TextEditingController(text: '美术');
  final _gradeController = TextEditingController(text: '三年级');
  final _descriptionController = TextEditingController();

  final List<String> _selectedOptions = [];
  
  final Map<String, List<String>> _subjectOptions = {
    '美术': ['素描', '色彩', '构图', '创意表达', '手工制作'],
    '音乐': ['节奏', '音高', '歌唱', '乐器', '音乐欣赏'],
    '综合': ['跨学科', '项目制', '实践活动', '情感教育', '创新思维'],
  };

  @override
  void initState() {
    super.initState();
    _updateOptionsForSubject('美术');
  }

  void _updateOptionsForSubject(String subject) {
    setState(() {
      _selectedOptions.clear();
    });
  }

  Future<void> _generateLessonPlan() async {
    if (_subjectController.text.trim().isEmpty || 
        _gradeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写学科和年级信息')),
      );
      return;
    }

    try {
      setState(() => _isGenerating = true);
      
      final res = await _lessonPlanner.generateLessonPlan(
        subject: _subjectController.text.trim(),
        grade: _gradeController.text.trim(),
        options: _selectedOptions,
        description: _descriptionController.text.trim(),
      );
      
      setState(() {
        _lessonResult = res;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _lessonResult = '教案生成失败: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _gradeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConstants.aiName}的教案助手'),
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
                    color: GlowUpColors.breeze.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.menu_book, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '智能教案生成',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '让${AppConstants.aiName}帮你制作专业的45分钟教案',
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
                    '课程信息',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: '学科',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.subject),
                          ),
                          onChanged: _updateOptionsForSubject,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _gradeController,
                          decoration: InputDecoration(
                            labelText: '年级',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.school),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    '教学重点',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_subjectOptions[_subjectController.text] ?? _subjectOptions['美术']!)
                        .map((option) => FilterChip(
                              label: Text(option),
                              selected: _selectedOptions.contains(option),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedOptions.add(option);
                                  } else {
                                    _selectedOptions.remove(option);
                                  }
                                });
                              },
                              selectedColor: GlowUpColors.breeze.withValues(alpha: 0.3),
                            ))
                        .toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: '课程描述（可选）',
                      hintText: '描述本节课的具体内容、目标或特殊要求...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateLessonPlan,
                      icon: _isGenerating 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? '生成中...' : '生成45分钟教案'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GlowUpColors.breeze,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_lessonResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: GlowUpColors.breeze),
                        const SizedBox(width: 8),
                        Text(
                          '生成的教案',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GlowUpColors.mist,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GlowUpColors.outline),
                      ),
                      child: Text(
                        _lessonResult,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: 保存教案到本地
                          },
                          icon: const Icon(Icons.save_alt),
                          label: const Text('保存教案'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            // TODO: 导出为PDF或Word
                          },
                          icon: const Icon(Icons.file_download),
                          label: const Text('导出'),
                          style: FilledButton.styleFrom(
                            backgroundColor: GlowUpColors.lavender,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GlowUpColors.breeze.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlowUpColors.breeze.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: GlowUpColors.breeze),
                      const SizedBox(width: 8),
                      Text(
                        '教案生成小贴士',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 选择合适的教学重点，让教案更有针对性\n'
                    '• 详细的课程描述能帮助生成更精准的内容\n'
                    '• 生成的教案包含完整的45分钟课程结构\n'
                    '• 可根据实际情况调整和完善教案内容',
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
}