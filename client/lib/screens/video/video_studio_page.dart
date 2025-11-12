import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../state/ai_generation_state.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class VideoStudioPage extends StatefulWidget {
  const VideoStudioPage({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  State<VideoStudioPage> createState() => _VideoStudioPageState();
}

class _VideoStudioPageState extends State<VideoStudioPage> {
  late final TextEditingController _promptController;
  String _orientation = 'portrait';
  String _size = 'small';
  int _selectedIdea = -1;
  final _storyIdeas = const [
    '春天的校园音乐会，小朋友用彩纸和风铃布置舞台',
    '科技小课堂：纸板机器人带孩子认识图形',
    '体育课热身：彩虹跑道上大家一起蹦跳',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<VideoGenerationState>();
    final initial = widget.initialPrompt;
    _promptController = TextEditingController(
      text: initial?.trim().isNotEmpty == true ? initial!.trim() : state.prompt,
    );
    _orientation = state.orientation;
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
        title: const Text('动画演示工坊'),
      ),
      body: SafeArea(
        child: Consumer<VideoGenerationState>(
          builder: (context, state, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderCard(
                    title: '动画演示工坊',
                    subtitle:
                        '让孩子先看到，再开口分享。故事、节日、自然课堂都能用动画开场。',
                    icon: Icons.movie_filter,
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
                          ideas: _storyIdeas,
                          selectedIndex: _selectedIdea,
                          onSelected: (index, selected) {
                            setState(() {
                              _selectedIdea = selected ? index : -1;
                              if (selected) {
                                _promptController.text = _storyIdeas[index];
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
                            hintText: '描述希望出现的场景、角色与氛围',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DropdownField(
                                label: '画面方向',
                                value: _orientation,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'portrait',
                                    child: Text('竖屏 · 适合手机演示'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'landscape',
                                    child: Text('横屏 · 适合投影'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _orientation = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DropdownField(
                                label: '分辨率',
                                value: _size,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'small',
                                    child: Text('轻量（推荐）'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'large',
                                    child: Text('高清'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _size = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: state.status == GenerationStatus.running ||
                                  state.status == GenerationStatus.submitting
                              ? null
                              : () => _submit(state),
                          icon: state.status == GenerationStatus.running ||
                                  state.status == GenerationStatus.submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            state.status == GenerationStatus.completed
                                ? '重新生成'
                                : '生成示范视频',
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
                  if (state.status == GenerationStatus.completed &&
                      state.remoteUrl != null && state.remoteUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GlowCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '预览与下载',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            _VideoPreview(remoteUrl: state.remoteUrl),
                            const SizedBox(height: 8),
                            Text(
                              '小贴士：下载后可离线播放，适合课堂中弱网环境。',
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
                                    final success = await state.downloadVideo();
                                    if (!mounted) return;
                                    if (success) {
                                      _showSnack('浏览器已开始下载视频。');
                                    } else {
                                      _showSnack(
                                        state.error?.message ?? '下载失败，请稍后再试。',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('下载视频'),
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

  Future<void> _submit(VideoGenerationState state) async {
    await state.generate(
      promptText: _promptController.text.trim(),
      orientationValue: _orientation,
      sizeValue: _size,
    );
    if (!mounted) return;
    if (state.status == GenerationStatus.submitting ||
        state.status == GenerationStatus.running) {
      _showSnack('已提交生成请求，后台轮询中…');
    } else if (state.status == GenerationStatus.failed) {
      _showSnack(state.error?.message ?? '生成失败，请稍后再试');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          colors: [Color(0xFFB4E9E2), Color(0xFF7FC6C9)],
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
        message = '正在提交任务到服务器…';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.running:
        message = '任务已受理，系统正在合成内容。';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.completed:
        message = '生成完成，可直接预览或下载离线播放。';
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

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({
    required this.remoteUrl,
  });

  final String? remoteUrl;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initializing;

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  @override
  void didUpdateWidget(covariant _VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remoteUrl != widget.remoteUrl) {
      _loadController();
    }
  }

  Future<void> _loadController() async {
    final source = await _resolveSource();
    if (source == null) {
      await _controller?.dispose();
      setState(() {
        _controller = null;
        _initializing = null;
      });
      return;
    }

    final previous = _controller;
    final controller = source;
    _initializing = controller.initialize().then((_) {
      controller.setLooping(true);
      setState(() {});
    });

    setState(() {
      _controller = controller;
    });

    await previous?.dispose();
  }

  Future<VideoPlayerController?> _resolveSource() async {
    if (widget.remoteUrl != null) {
      return VideoPlayerController.networkUrl(Uri.parse(widget.remoteUrl!));
    }
    return null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: GlowUpColors.lavender.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('暂无可播放的视频'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FutureBuilder<void>(
            future: _initializing,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return SizedBox(
                  height: 200,
                  child: Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              return AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(controller),
                    _VideoControls(controller: controller),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.controller.value.isPlaying;
    widget.controller.addListener(_playerListener);
  }

  void _playerListener() {
    final playing = widget.controller.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_playerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomCenter,
      child: FloatingActionButton.small(
        heroTag: null,
        backgroundColor: GlowUpColors.dusk.withValues(alpha: 0.8),
        onPressed: () {
          if (_isPlaying) {
            widget.controller.pause();
          } else {
            widget.controller.play();
          }
        },
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }
}
