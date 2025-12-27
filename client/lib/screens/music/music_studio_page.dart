import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../state/ai_generation_state.dart';
import '../analysis/audio_analysis_page.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class MusicStudioPage extends StatefulWidget {
  const MusicStudioPage({super.key, this.initialPrompt, this.initialDescription});

  final String? initialPrompt;
  final String? initialDescription;

  @override
  State<MusicStudioPage> createState() => _MusicStudioPageState();
}

class _MusicStudioPageState extends State<MusicStudioPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _instrumental = false;
  String _style = 'country';
  int _selectedIdea = -1;
  final _ideas = const [
    '轻快的晨读伴奏，像清晨鸟叫一样温柔',
    '欢快的运动会背景音乐，鼓励孩子跑步',
    '午后安静写作业的舒缓琴声',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<MusicGenerationState>();
    final prompt = widget.initialPrompt;
    final description = widget.initialDescription;
    _titleController = TextEditingController(text: state.prompt);
    final combined = [description, prompt]
        .where((element) => element != null && element.trim().isNotEmpty)
        .map((e) => e!.trim())
        .join('\n');
    _descriptionController = TextEditingController(
      text: combined.isNotEmpty ? combined : state.description,
    );
    _instrumental = state.instrumental;
    _style = state.style;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐角工坊'),
      ),
      body: SafeArea(
        child: Consumer<MusicGenerationState>(
          builder: (context, state, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderCard(
                    title: '音乐角工坊',
                    subtitle: '给课堂换个“背景色”。孩子写作、律动、午休时都有贴心音乐陪伴。',
                    icon: Icons.music_note,
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
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '音乐标题',
                            hintText: '例如：Cat Dance',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: '风格描述',
                            hintText: '描述节奏、情绪或参考曲风',
                            border: OutlineInputBorder(),
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
                                _descriptionController.text = _ideas[index];
                                _titleController.text = '小小旋律';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _DropdownField(
                          label: '音乐风格',
                          value: _style,
                          items: const [
                            DropdownMenuItem(
                              value: 'country',
                              child: Text('乡村'),
                            ),
                            DropdownMenuItem(
                              value: 'pop',
                              child: Text('流行'),
                            ),
                            DropdownMenuItem(
                              value: 'classical',
                              child: Text('古典'),
                            ),
                            DropdownMenuItem(
                              value: 'electronic',
                              child: Text('电子'),
                            ),
                            DropdownMenuItem(
                              value: 'hiphop',
                              child: Text('Hip-hop'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _style = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _instrumental,
                          onChanged: (value) {
                            setState(() => _instrumental = value);
                          },
                          title: const Text('只要伴奏'),
                          subtitle: const Text('勾选后不含人声，更适合作为背景音乐'),
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
                              : const Icon(Icons.graphic_eq),
                          label: Text(
                            state.status == GenerationStatus.completed
                                ? '重新生成'
                                : '生成音乐',
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
                  if (state.tracks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '试听与下载',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          ...state.tracks.map(
                            (track) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: GlowCard(
                                child: _TrackPlayerTile(
                                  track: track,
                                  onDownloadAudio: () =>
                                      context.read<MusicGenerationState>()
                                          .downloadAudio(track.id),
                                  onDownloadCover: () =>
                                      context.read<MusicGenerationState>()
                                          .downloadCover(track.id),
                                  onAnalyze: () => _openAudioAnalysis(track),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '贴士：孩子如果喜欢这段音乐，可在“下载音频”后做成班级铃声或手工节目背景。',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: GlowUpColors.dusk.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
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

  Future<void> _submit(MusicGenerationState state) async {
    await state.generateMusic(
      promptText: _titleController.text.trim(),
      descriptionText: _descriptionController.text.trim(),
      styleValue: _style,
      instrumentalValue: _instrumental,
    );
    if (!mounted) return;
    if (state.status == GenerationStatus.running) {
      _showSnack('已提交生成请求，大约 30 秒完成。');
    } else if (state.status == GenerationStatus.failed) {
      _showSnack(state.error?.message ?? '生成失败，请稍后再试。');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAudioAnalysis(GeneratedTrack track) async {
    final bytes = await context.read<MusicGenerationState>().ensureAudioBytes(track.id);
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      _showSnack('音频加载失败，请稍后再试。');
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioAnalysisPage(
            initialAudioBytes: bytes,
            initialLabel: track.title,
          ),
        ),
      );
    } catch (e) {
      _showSnack('打开音频分析失败：$e');
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
        message = '正在提交任务到服务器…';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.running:
        message = '系统正在合成音轨，请稍候。';
        color = GlowUpColors.lavender.withValues(alpha: 0.25);
        break;
      case GenerationStatus.completed:
        message = '生成完成，可直接试听或下载保存。';
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

class _TrackPlayerTile extends StatefulWidget {
  const _TrackPlayerTile({
    required this.track,
    required this.onDownloadAudio,
    required this.onDownloadCover,
    required this.onAnalyze,
  });

  final GeneratedTrack track;
  final Future<void> Function() onDownloadAudio;
  final Future<void> Function() onDownloadCover;
  final VoidCallback onAnalyze;

  @override
  State<_TrackPlayerTile> createState() => _TrackPlayerTileState();
}

class _TrackPlayerTileState extends State<_TrackPlayerTile> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isLoading = false;
  bool _isReady = false;
  bool _isPlaying = false;
  static bool _sessionConfigured = false;

  @override
  void initState() {
    super.initState();
    _setup();
    _playerStateSub = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (playing != _isPlaying) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  Future<void> _setup() async {
    if (!_sessionConfigured) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _sessionConfigured = true;
    }

    final source = _resolveSource();
    if (source == null) {
      setState(() {
        _isReady = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _player.setAudioSource(source);
      setState(() {
        _isReady = true;
      });
    } catch (_) {
      setState(() {
        _isReady = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  AudioSource? _resolveSource() {
    if (widget.track.audioUrl != null) {
      return AudioSource.uri(Uri.parse(widget.track.audioUrl!));
    }
    if (widget.track.audioBytes != null) {
      final dataUri = Uri.dataFromBytes(
        widget.track.audioBytes!,
        mimeType: 'audio/mpeg',
      );
      return AudioSource.uri(dataUri);
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant _TrackPlayerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.audioUrl != widget.track.audioUrl ||
        oldWidget.track.audioBytes != widget.track.audioBytes) {
      _player.stop();
      _setup();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.track.imageUrl != null
        ? '配套封面可用于海报或任务卡'
        : '可作为课堂配乐或节奏练习';
    final hasAudioUrl = widget.track.audioUrl != null && widget.track.audioUrl!.isNotEmpty;
    final hasAudioBytes = widget.track.audioBytes != null;
    final canAnalyze = (hasAudioUrl || hasAudioBytes) && !_isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.track.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: GlowUpColors.dusk.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: _isPlaying ? '暂停' : '播放',
                onPressed: _isReady
                    ? () {
                        if (_isPlaying) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      }
                    : null,
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 32,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isReady)
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = _player.duration ?? Duration.zero;
              final progress = total.inMilliseconds == 0
                  ? 0.0
                  : (position.inMilliseconds / total.inMilliseconds)
                      .clamp(0.0, 1.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(position, total),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          )
        else
          const Text('暂无可播放的音轨'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: widget.onDownloadAudio,
              icon: const Icon(Icons.download),
              label: const Text('下载音频'),
            ),
            OutlinedButton.icon(
              onPressed: canAnalyze ? widget.onAnalyze : null,
              icon: const Icon(Icons.analytics),
              label: const Text('节奏分析'),
            ),
            if (widget.track.imageUrl != null)
              OutlinedButton.icon(
                onPressed: widget.onDownloadCover,
                icon: const Icon(Icons.download),
                label: const Text('下载封面'),
              ),
          ],
        ),
        if (widget.track.isCachingAudio)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(minHeight: 4),
          ),
        if (widget.track.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.track.coverBytes != null
                  ? Image.memory(
                      widget.track.coverBytes!,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      widget.track.imageUrl!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration position, Duration total) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final posMinutes = twoDigits(position.inMinutes.remainder(60));
    final posSeconds = twoDigits(position.inSeconds.remainder(60));
    final totalMinutes = twoDigits(total.inMinutes.remainder(60));
    final totalSeconds = twoDigits(total.inSeconds.remainder(60));
    return '$posMinutes:$posSeconds / $totalMinutes:$totalSeconds';
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
          colors: [Color(0xFFD9D7F8), Color(0xFFB7B3E8)],
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
