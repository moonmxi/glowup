import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../state/ai_generation_state.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import '../analysis/image_analysis_page.dart';

class ImageStudioPage extends StatefulWidget {
  const ImageStudioPage({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  State<ImageStudioPage> createState() => _ImageStudioPageState();
}

class _ImageStudioPageState extends State<ImageStudioPage> {
  late final TextEditingController _promptController;
  String _size = '1024x1024';
  int _selectedIdea = -1;
  final _ideas = const [
    '操场晨练的缤纷海报背景',
    '儿童节班级合影的手绘彩旗框架',
    '自然探险主题的插画故事卡',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<ImageGenerationState>();
    final initial = widget.initialPrompt;
    _promptController = TextEditingController(
      text: initial?.trim().isNotEmpty == true ? initial!.trim() : state.prompt,
    );
    _size = state.size;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视觉素材工坊'),
      ),
      body: SafeArea(
        child: Consumer<ImageGenerationState>(
          builder: (context, state, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderCard(
                    title: '视觉素材工坊',
                    subtitle: '孩子们喜欢看的图，就从这里冒出来。板书、讲义封面、作品墙都能用。',
                    icon: Icons.brush,
                  ),
                  const SizedBox(height: 18),
                  GlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '创作设置',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _IdeaChips(
                          ideas: _ideas,
                          selectedIndex: _selectedIdea,
                          onSelected: (index, selected) {
                            setState(() {
                              _selectedIdea = selected ? index : -1;
                              if (selected) {
                                _promptController.text = _ideas[index];
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _promptController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: '创作提示',
                          hintText: '描述对象、风格与光线，例如“秋日运动会黑板海报”',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DropdownField(
                          label: '图片尺寸',
                          value: _size,
                          items: const [
                            DropdownMenuItem(
                              value: '1024x1024',
                              child: Text('1024 × 1024'),
                            ),
                            DropdownMenuItem(
                              value: '512x512',
                              child: Text('512 × 512'),
                            ),
                            DropdownMenuItem(
                              value: '256x256',
                              child: Text('256 × 256'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _size = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: state.status == GenerationStatus.submitting ||
                                  state.status == GenerationStatus.running
                              ? null
                              : () => _submit(state),
                          icon: state.status == GenerationStatus.submitting ||
                                  state.status == GenerationStatus.running
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.brush_outlined),
                          label: Text(
                            state.status == GenerationStatus.completed
                                ? '重新生成'
                                : '生成插画',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StatusInfo(status: state.status, error: state.error),
                        if (state.status == GenerationStatus.running)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(value: state.progress),
                          ),
                      ],
                    ),
                  ),
                  if (state.remoteUrl != null && state.remoteUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GlowCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '素材预览',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            _ImagePreview(remoteUrl: state.remoteUrl),
                            const SizedBox(height: 8),
                            Text(
                              '提示：下载后的图片可直接用于打印或插入 PPT。',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: GlowUpColors.dusk.withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final success = await state.downloadImage();
                                    if (!mounted) return;
                                    if (success) {
                                      _showSnack('浏览器已开始下载图片。');
                                    } else {
                                      _showSnack(
                                        state.error?.message ?? '下载失败，请稍后再试。',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('下载 PNG'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _openColorAnalysis(state),
                                  icon: const Icon(Icons.palette),
                                  label: const Text('色彩分析'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(ImageGenerationState state) async {
    await state.generateImage(
      promptText: _promptController.text.trim(),
      sizeValue: _size,
    );
    if (!mounted) return;
    if (state.status == GenerationStatus.completed) {
      _showSnack('生成完成，可直接预览或下载。');
    } else if (state.status == GenerationStatus.failed) {
      _showSnack(state.error?.message ?? '生成失败，请稍后再试。');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openColorAnalysis(ImageGenerationState state) async {
    final url = state.remoteUrl;
    if (url == null || url.isEmpty) {
      _showSnack('请先生成插画。');
      return;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('下载失败：${response.statusCode}');
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageAnalysisPage(
            initialImageBytes: response.bodyBytes,
            initialLabel: state.prompt,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('加载图片失败：$e');
    }
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  const _StatusInfo({
    required this.status,
    this.error,
  });

  final GenerationStatus status;
  final GenerationError? error;

  @override
  Widget build(BuildContext context) {
    late final String message;
    late final Color color;

    switch (status) {
      case GenerationStatus.idle:
        message = '尚未生成，填写提示语后即可开始。';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.submitting:
        message = '正在创作，请稍候…';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.running:
        message = '系统处理中，即将返回插画。';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.completed:
        message = '生成完成，可直接预览或下载保存。';
        color = GlowUpColors.success.withValues(alpha: 0.18);
        break;
      case GenerationStatus.failed:
        message = error?.message ?? '生成失败，请稍后重试。';
        color = GlowUpColors.bloom.withValues(alpha: 0.3);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.remoteUrl});

  final String? remoteUrl;

  @override
  Widget build(BuildContext context) {
    final url = remoteUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: GlowUpColors.lavender.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('暂无可展示的图片')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stack) {
            return Container(
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, size: 40),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBDDE2), Color(0xFFE7B7C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: Icon(icon, color: GlowUpColors.dusk, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GlowUpColors.dusk,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeaChips extends StatelessWidget {
  const _IdeaChips({
    required this.ideas,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> ideas;
  final int selectedIndex;
  final void Function(int index, bool selected) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ideas.asMap().entries.map((entry) {
        final index = entry.key;
        final idea = entry.value;
        return FilterChip(
          label: Text(idea),
          selected: selectedIndex == index,
          onSelected: (value) => onSelected(index, value),
        );
      }).toList(),
    );
  }
}
