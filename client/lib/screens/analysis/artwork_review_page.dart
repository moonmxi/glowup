import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../../constants/app_constants.dart';
import '../../services/ai_analyzers.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import '../../utils/platform_file_helper.dart';

class ArtworkReviewPage extends StatefulWidget {
  const ArtworkReviewPage({super.key});

  @override
  State<ArtworkReviewPage> createState() => _ArtworkReviewPageState();
}

class _ArtworkReviewPageState extends State<ArtworkReviewPage> {
  final _imageAnalyzer = AiImageAnalyzer();
  String _imageResult = '';
  bool _isAnalyzing = false;
  Uint8List? _selectedImageBytes;

  Future<void> _pickAndAnalyzeImage() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() => _isAnalyzing = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) {
          setState(() => _isAnalyzing = false);
        }
        return;
      }

      final resolved = await resolvePlatformFile(result.files.first);
      if (!mounted) return;
      if (resolved == null) {
        setState(() => _isAnalyzing = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('无法读取所选文件，请重试')),
        );
        return;
      }

      setState(() {
        _selectedImageBytes = resolved.bytes;
      });

      final res = await _imageAnalyzer.analyzeImageBytes(
        imageBytes: resolved.bytes,
        fileName: resolved.name,
        question:
            '请用温暖鼓励的语言点评这幅儿童画作，从色彩运用、构图创意、情感表达等方面给出具体的赞美和建议，让孩子感受到成就感并愿意继续创作。',
      );

      if (!mounted) return;
      setState(() {
        _imageResult = res;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _imageResult = '图片分析失败: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConstants.aiName}的画作点评'),
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
                    color: GlowUpColors.bloom.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.palette, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '智能画作点评',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '让${AppConstants.aiName}用温暖的话语鼓励每一个小艺术家',
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
                    '上传画作',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_selectedImageBytes != null) ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GlowUpColors.outline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isAnalyzing ? null : _pickAndAnalyzeImage,
                      icon: _isAnalyzing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(_isAnalyzing ? '分析中...' : '选择并分析画作'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GlowUpColors.bloom,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_imageResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: GlowUpColors.bloom),
                        const SizedBox(width: 8),
                        Text(
                          '${AppConstants.aiName}的点评',
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
                        _imageResult,
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
                            // TODO: 保存点评到本地
                          },
                          icon: const Icon(Icons.save_alt),
                          label: const Text('保存点评'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            // TODO: 分享功能
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('分享'),
                          style: FilledButton.styleFrom(
                            backgroundColor: GlowUpColors.breeze,
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
                        '点评小贴士',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${AppConstants.aiName}会从多个角度给出温暖的鼓励\n'
                    '• 重点关注孩子的创意和努力过程\n'
                    '• 提供具体可行的改进建议\n'
                    '• 帮助建立孩子的艺术自信心',
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
