import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/showcase.dart';
import '../../state/auth_state.dart';
import '../../state/showcase_state.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class ShowcaseDetailPage extends StatefulWidget {
  const ShowcaseDetailPage({
    super.key,
    required this.item,
  });

  final ShowcaseItem item;

  @override
  State<ShowcaseDetailPage> createState() => _ShowcaseDetailPageState();
}

class _UserUploadPreview extends StatefulWidget {
  const _UserUploadPreview({
    required this.preview,
    this.downloadUrl,
    this.fileName,
  });

  final Map<String, dynamic> preview;
  final String? downloadUrl;
  final String? fileName;

  @override
  State<_UserUploadPreview> createState() => _UserUploadPreviewState();
}

class _UserUploadPreviewState extends State<_UserUploadPreview> {
  VideoPlayerController? _videoController;
  Future<void>? _videoFuture;
  AudioPlayer? _audioPlayer;
  StreamSubscription<PlayerState>? _audioSubscription;
  bool _isAudioReady = false;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant _UserUploadPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.preview, widget.preview)) {
      _disposeControllers();
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _videoController = null;
    _videoFuture = null;
    _audioSubscription?.cancel();
    _audioSubscription = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isAudioReady = false;
    _isAudioPlaying = false;
  }

  void _initializeControllers() {
    final subtype = _subtype;
    if (subtype == 'video') {
      final url = _videoUrl;
      if (url != null) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        _videoController = controller;
        _videoFuture = controller.initialize().then((_) {
          if (mounted) setState(() {});
        }).catchError((error) {
          debugPrint('视频加载失败: $error');
        });
      }
    } else if (subtype == 'audio') {
      final url = _audioUrl;
      if (url != null) {
        final player = AudioPlayer();
        _audioPlayer = player;
        _audioSubscription = player.playerStateStream.listen((state) {
          if (!mounted) return;
          final playing = state.playing &&
              state.processingState != ProcessingState.completed;
          setState(() {
            _isAudioPlaying = playing;
          });
          if (state.processingState == ProcessingState.completed) {
            player.seek(Duration.zero);
          }
        });
        player.setUrl(url).then((_) {
          if (mounted) {
            setState(() {
              _isAudioReady = true;
            });
          }
        }).catchError((error) {
          debugPrint('音频加载失败: $error');
        });
      }
    }
  }

  String get _subtype =>
      (widget.preview['subtype'] as String? ?? '').toLowerCase();

  String? get _fileUrl {
    final provided = widget.downloadUrl;
    if (provided != null && provided.trim().isNotEmpty) {
      return provided.trim();
    }
    return _stringValue(widget.preview['fileUrl']);
  }

  String? get _imageUrl => _stringValue(widget.preview['imageUrl']) ?? _fileUrl;
  String? get _videoUrl => _stringValue(widget.preview['videoUrl']) ?? _fileUrl;
  String? get _audioUrl => _stringValue(widget.preview['audioUrl']) ?? _fileUrl;

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fileName =
        widget.fileName ?? _stringValue(widget.preview['fileName']) ?? '用户上传作品';
    switch (_subtype) {
      case 'image':
        return _buildImagePreview(fileName);
      case 'video':
        return _buildVideoPreview(fileName);
      case 'audio':
        return _buildAudioPreview(fileName);
      default:
        return _buildFallbackPreview(fileName);
    }
  }

  Widget _buildImagePreview(String fileName) {
    final url = _imageUrl;
    if (url == null) {
      return _buildFallbackPreview(fileName);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => _showImageDialog(url, fileName),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, value) => Container(
                  color: GlowUpColors.mist,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, value, error) => Container(
                  color: GlowUpColors.mist,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image,
                          size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        '$fileName（图片加载失败）',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _openExternal(url),
          icon: const Icon(Icons.open_in_new),
          label: const Text('查看 / 下载'),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(String fileName) {
    final controller = _videoController;
    final future = _videoFuture;
    final url = _videoUrl;
    if (controller == null || future == null || url == null) {
      return _buildFallbackPreview(fileName);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FutureBuilder<void>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              }
              return AspectRatio(
                aspectRatio: controller.value.isInitialized
                    ? controller.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(controller),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              iconSize: 36,
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
              onPressed: () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openExternal(url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('外部播放'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioPreview(String fileName) {
    final url = _audioUrl;
    final player = _audioPlayer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlowUpColors.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 40,
            icon:
                Icon(_isAudioPlaying ? Icons.pause_circle : Icons.play_circle),
            onPressed: _isAudioReady ? () => _toggleAudio(player!) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (url != null)
            TextButton.icon(
              onPressed: () => _openExternal(url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('外部播放'),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackPreview(String fileName) {
    final url = _fileUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlowUpColors.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (url != null)
            TextButton(
              onPressed: () => _openExternal(url),
              child: const Text('打开'),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleAudio(AudioPlayer player) async {
    if (_isAudioPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> _openExternal(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return;
      }
    } catch (_) {
      // Swallow and fall through to user feedback.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('无法打开链接')),
    );
  }

  Future<void> _showImageDialog(String url, String fileName) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, value) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, value, error) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openExternal(url),
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          '保存',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShowcaseDetailPageState extends State<ShowcaseDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _isImportingStory = false;
  late ShowcaseItem _currentItem;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  @override
  void didUpdateWidget(covariant ShowcaseDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _currentItem = widget.item;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ShowcaseState, AuthState>(
      builder: (context, showcaseState, auth, _) {
        final canDelete = _canManageItem(auth, _currentItem);
        final isTeacherView = auth.user?.isTeacher ?? false;
        final appBarColor = isTeacherView
            ? GlowUpColors.primary
            : GlowUpColors.secondary;
        final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            );
        return Scaffold(
          appBar: AppBar(
            title: Text(_currentItem.title),
            backgroundColor: appBarColor,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: titleStyle,
            actions: [
              if (canDelete)
                IconButton(
                  tooltip: '删除作品',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(showcaseState),
                ),
              IconButton(
                icon: Icon(
                  _currentItem.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _currentItem.isLiked
                      ? GlowUpColors.sunset
                      : Colors.white,
                ),
                onPressed: auth.isAuthenticated
                    ? () async {
                        final success =
                            await showcaseState.toggleLike(_currentItem.id);
                        if (success && mounted) {
                          final updated = showcaseState.items.firstWhere(
                            (item) => item.id == _currentItem.id,
                            orElse: () => _currentItem,
                          );
                          setState(() => _currentItem = updated);
                        }
                      }
                    : null,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildContent(showcaseState, auth),
                const SizedBox(height: 20),
                _buildMetadata(),
                const SizedBox(height: 20),
                _buildComments(),
                const SizedBox(height: 20),
                if (auth.isAuthenticated) _buildCommentInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentItem.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(_friendlyCategory(_currentItem.kind)),
                backgroundColor: _getCategoryColor(_currentItem.kind),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: GlowUpColors.primary,
                child: Text(
                  _currentItem.ownerName.isNotEmpty
                      ? _currentItem.ownerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentItem.ownerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _currentItem.ownerRole == 'teacher' ? '老师' : '学生',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _formatDate(_currentItem.createdAt),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          if (_currentItem.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _currentItem.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(ShowcaseState showcaseState, AuthState auth) {
    final preview = _currentItem.preview;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '作品内容',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (preview.isNotEmpty) ...[
            _buildPreviewContent(preview, showcaseState, auth),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GlowUpColors.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _getContentIcon(_currentItem.kind),
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_friendlyCategory(_currentItem.kind)}作品',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewContent(
    Map<String, dynamic> preview,
    ShowcaseState showcaseState,
    AuthState auth,
  ) {
    final type = preview['type'] as String?;

    switch (type) {
      case 'story_bundle':
        return _buildStoryBundle(preview, showcaseState, auth);
      case 'ai_image':
        return _buildAIImageContent(preview);
      case 'ai_music':
        return _buildAIMusicContent(preview);
      case 'ai_lesson':
        return _buildAILessonContent(preview);
      case 'text':
        return _buildTextContent(preview);
      case 'user_upload':
        return _buildUserUploadContent(_currentItem, preview);
      default:
        return _buildGenericContent(preview);
    }
  }

  Widget _buildAIImageContent(Map<String, dynamic> preview) {
    final prompt = preview['prompt'] as String? ?? '';
    final style = preview['style'] as String? ?? '';
    final colors = (preview['colors'] as List?)?.cast<String>() ?? [];
    final imageUrl = preview['imageUrl'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.pink.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '妙手画坊作品',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (style.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '风格：$style',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (prompt.isNotEmpty) ...[
          const Text(
            '创作提示词：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              prompt,
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (colors.isNotEmpty) ...[
          const Text(
            '主要色彩：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: colors
                .map((color) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: GlowUpColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: GlowUpColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        color,
                        style: TextStyle(
                          fontSize: 12,
                          color: GlowUpColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    '图片预览',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(演示模式)',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAIMusicContent(Map<String, dynamic> preview) {
    final genre = preview['genre'] as String? ?? '';
    final mood = preview['mood'] as String? ?? '';
    final duration = preview['duration'] as String? ?? '';
    final instruments = (preview['instruments'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.cyan.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '旋律工坊作品',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (genre.isNotEmpty) ...[
                    Text(
                      '类型：$genre',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (duration.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text(
                      '时长：$duration',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (mood.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.sentiment_satisfied,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '情感氛围：$mood',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (instruments.isNotEmpty) ...[
          const Text(
            '使用乐器：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: instruments
                .map((instrument) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        instrument,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '音频播放器',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(演示模式)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryBundle(
    Map<String, dynamic> preview,
    ShowcaseState showcaseState,
    AuthState auth,
  ) {
    final metadata = _currentItem.metadata;
    final bundle = metadata['storyBundle'] as Map<String, dynamic>?;
    final assets = (metadata['assets'] as Map<String, dynamic>? ?? {});

    final title = (bundle?['title'] as String?) ??
        (preview['title'] as String?) ??
        '课堂故事';
    final theme =
        (bundle?['theme'] as String?) ?? (preview['theme'] as String?) ?? '';
    final classroomNameMap = {
      for (final c in auth.classrooms) c.id: c.name,
    };
    final classrooms = (metadata['classroomIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final List<Map<String, dynamic>> detailedSteps =
        (bundle?['steps'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final List<String> summarySteps = (preview['steps'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final canImportStory =
        auth.user?.isTeacher == true && auth.classrooms.isNotEmpty;
    final storyWidgets = <Widget>[];

    if (detailedSteps.isNotEmpty) {
      for (final step in detailedSteps) {
        final label = (step['label'] as String?) ?? '课堂环节';
        final summary = (step['summary'] as String?) ?? '';
        final completed = step['completed'] == true;
        final payload = (step['payload'] as Map<String, dynamic>? ?? {});
        final stepPreview = Map<String, dynamic>.from(
          (payload['preview'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
        );
        final stepMetadata = Map<String, dynamic>.from(
          (payload['metadata'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
        );
        final assetData = assets[step['kind']] as Map<String, dynamic>?;
        final normalizedPreview = Map<String, dynamic>.from(stepPreview);
        normalizedPreview['subtype'] ??=
            _inferSubtypeForStep(step['kind']?.toString() ?? '', stepPreview);
        if (assetData != null && normalizedPreview.isEmpty) {
          if (assetData['preview'] is Map<String, dynamic>) {
            normalizedPreview.addAll(Map<String, dynamic>.from(
                assetData['preview'] as Map<String, dynamic>));
          }
        }

        Widget? mediaWidget;
        if (normalizedPreview.isNotEmpty) {
          mediaWidget = Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _UserUploadPreview(
              preview: normalizedPreview,
              downloadUrl: stepMetadata['fileUrl'] as String? ??
                  normalizedPreview['fileUrl'] as String?,
              fileName: stepMetadata['fileName']?.toString() ??
                  normalizedPreview['fileName']?.toString(),
            ),
          );
        }

        storyWidgets.add(
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlowUpColors.mist),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (completed)
                      const Chip(
                        label: Text('已完成'),
                        avatar: Icon(Icons.check, size: 16),
                      ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(summary, style: const TextStyle(fontSize: 14)),
                ],
                if (mediaWidget != null) mediaWidget,
              ],
            ),
          ),
        );
      }
    }

    final children = <Widget>[
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [GlowUpColors.primary, GlowUpColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (theme.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '主题：$theme',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
            if (classrooms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: classrooms
                    .map(
                      (id) => Chip(
                        label: Text(classroomNameMap[id] ?? '班级 $id'),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ];

    if (storyWidgets.isNotEmpty) {
      children
        ..add(const SizedBox(height: 16))
        ..add(const Text(
          '故事内容：',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ))
        ..addAll(storyWidgets);
    } else if (summarySteps.isNotEmpty) {
      children
        ..add(const SizedBox(height: 16))
        ..add(const Text(
          '故事内容：',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ))
        ..add(const SizedBox(height: 8))
        ..addAll(summarySteps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  decoration: const BoxDecoration(
                    color: GlowUpColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(step, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ));
    }

    if (canImportStory && bundle != null) {
      children
        ..add(const SizedBox(height: 16))
        ..add(
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isImportingStory
                  ? null
                  : () => _promptImportStory(showcaseState, auth),
              icon: _isImportingStory
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.library_add),
              label: Text(_isImportingStory ? '导入中...' : '导入到我的班级'),
            ),
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildAILessonContent(Map<String, dynamic> preview) {
    final subject = preview['subject'] as String? ?? '';
    final ageGroup = preview['ageGroup'] as String? ?? '';
    final duration = preview['duration'] as String? ?? '';
    final objectives = (preview['objectives'] as List?)?.cast<String>() ?? [];
    final activities =
        (preview['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final materials = (preview['materials'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '教案设计',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (subject.isNotEmpty) ...[
                    Text(
                      '学科：$subject',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (ageGroup.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text(
                      '年龄：$ageGroup',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (duration.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text(
                      '时长：$duration',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (objectives.isNotEmpty) ...[
          const Text(
            '教学目标：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...objectives.map((objective) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        objective,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (activities.isNotEmpty) ...[
          const Text(
            '教学活动：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...activities.map((activity) {
            final name = activity['name'] as String? ?? '';
            final activityDuration = activity['duration'] as String? ?? '';
            final description = activity['description'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (activityDuration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activityDuration,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (materials.isNotEmpty) ...[
          const Text(
            '所需材料：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: materials
                .map((material) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        material,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTextContent(Map<String, dynamic> preview) {
    final title = preview['title'] as String? ?? '';
    final body = preview['body'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GlowUpColors.mist,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            body.isNotEmpty ? body : '暂无详细内容',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericContent(Map<String, dynamic> preview) {
    final entries = preview.entries.where((e) => e.value != null).toList();

    if (entries.isEmpty) {
      return const Text('暂无预览内容');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '${entry.key}：',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserUploadContent(
    ShowcaseItem item,
    Map<String, dynamic> preview,
  ) {
    return _UserUploadPreview(
      preview: preview,
      downloadUrl: item.downloadUrl,
      fileName: item.displayFileName,
    );
  }

  String _inferSubtypeForStep(String kind, Map<String, dynamic> preview) {
    final lowerKind = kind.toLowerCase();
    if (preview['imageUrl'] is String &&
        (preview['imageUrl'] as String).trim().isNotEmpty) {
      return 'image';
    }
    if (preview['videoUrl'] is String &&
        (preview['videoUrl'] as String).trim().isNotEmpty) {
      return 'video';
    }
    if (preview['audioUrl'] is String &&
        (preview['audioUrl'] as String).trim().isNotEmpty) {
      return 'audio';
    }
    if (lowerKind.contains('video')) return 'video';
    if (lowerKind.contains('music') || lowerKind.contains('audio')) {
      return 'audio';
    }
    if (lowerKind.contains('image') || lowerKind.contains('background')) {
      return 'image';
    }
    return 'file';
  }

  Future<void> _promptImportStory(
    ShowcaseState showcaseState,
    AuthState auth,
  ) async {
    final bundle =
        _currentItem.metadata['storyBundle'] as Map<String, dynamic>?;
    if (bundle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该作品缺少可导入的故事数据')),
      );
      return;
    }

    final classrooms = auth.classrooms;
    if (classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建班级后再导入故事')),
      );
      return;
    }

    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入课堂故事'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: classrooms
                    .map(
                      (classroom) => CheckboxListTile(
                        value: selected.contains(classroom.id),
                        title: Text(classroom.name),
                        subtitle: Text('班级码：${classroom.code}'),
                        onChanged: (checked) {
                          setModalState(() {
                            if (checked == true) {
                              selected.add(classroom.id);
                            } else {
                              selected.remove(classroom.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed:
                  selected.isEmpty ? null : () => Navigator.pop(context, true),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || selected.isEmpty) {
      return;
    }

    setState(() => _isImportingStory = true);
    try {
      final ok = await showcaseState.importStoryBundle(
        story: bundle,
        classroomIds: selected.toList(),
        title: _currentItem.title,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('故事已导入到班级，可在“课堂故事”中查看')),
        );
      } else {
        final error = showcaseState.error ?? '导入失败，请稍后再试';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingStory = false);
      }
    }
  }

  Widget _buildMetadata() {
    final metadata = _currentItem.metadata;
    if (metadata.isEmpty) return const SizedBox.shrink();

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '作品信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red, size: 20),
              const SizedBox(width: 4),
              Text('${_currentItem.likes} 点赞'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '评论 (${_currentItem.comments})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_currentItem.commentDetails.isEmpty) ...[
            const Text(
              '暂无评论，快来抢沙发吧！',
              style: TextStyle(color: Colors.grey),
            ),
          ] else ...[
            ..._currentItem.commentDetails.map((comment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlowUpColors.mist,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: GlowUpColors.primary,
                          child: Text(
                            comment.username.isNotEmpty
                                ? comment.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(comment.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '发表评论',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '写下你的想法...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _commentController.clear(),
                child: const Text('清空'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmittingComment ? null : _submitComment,
                child: _isSubmittingComment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('发表'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final showcaseState = context.read<ShowcaseState>();
    final auth = context.read<AuthState>();
    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再发表评论')),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final updated = await showcaseState.commentOnContent(
        contentId: _currentItem.id,
        text: content,
      );

      if (!mounted) return;
      if (updated != null) {
        setState(() => _currentItem = updated);
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论发表成功')),
        );
      } else {
        final error = showcaseState.error ?? '评论发表失败，请稍后重试';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('评论发表失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(ShowcaseState showcaseState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除作品'),
        content: Text('确定要删除《${_currentItem.title}》吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await showcaseState.deleteContent(_currentItem.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('作品已删除')),
      );
      Navigator.of(context).pop();
    } else {
      final error = showcaseState.error ?? '删除失败，请稍后再试';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  bool _canManageItem(AuthState auth, ShowcaseItem item) {
    if (!(auth.user?.isTeacher ?? false)) return false;
    final userId = auth.user?.id ?? '';
    if (userId.isNotEmpty && item.ownerId == userId) {
      return true;
    }
    final managedIds = auth.classrooms.map((room) => room.id).toSet();
    if (managedIds.isEmpty) return false;
    return item.classroomIds.any(managedIds.contains);
  }

  String _friendlyCategory(String value) {
    switch (value) {
      case 'image':
        return '妙手画坊';
      case 'music':
        return '旋律工坊';
      case 'video':
        return '光影剧场';
      case 'lesson':
        return '教案';
      default:
        return value;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'image':
        return GlowUpColors.bloom.withValues(alpha: 0.3);
      case 'music':
        return GlowUpColors.breeze.withValues(alpha: 0.3);
      case 'video':
        return GlowUpColors.sunset.withValues(alpha: 0.3);
      case 'lesson':
        return GlowUpColors.lavender.withValues(alpha: 0.3);
      default:
        return GlowUpColors.mist;
    }
  }

  IconData _getContentIcon(String kind) {
    switch (kind) {
      case 'image':
        return Icons.image;
      case 'music':
        return Icons.music_note;
      case 'video':
        return Icons.play_circle;
      case 'lesson':
        return Icons.menu_book;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
