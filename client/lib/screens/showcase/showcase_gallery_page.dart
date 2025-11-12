import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/showcase.dart';
import '../../state/auth_state.dart';
import '../../state/showcase_state.dart';
import '../../theme/glowup_theme.dart';
import '../../utils/platform_file_helper.dart';
import 'showcase_detail_page.dart';

class ShowcaseGalleryPage extends StatefulWidget {
  const ShowcaseGalleryPage({super.key});

  @override
  State<ShowcaseGalleryPage> createState() => _ShowcaseGalleryPageState();
}

class _ShowcaseGalleryPageState extends State<ShowcaseGalleryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShowcaseState>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ShowcaseState, AuthState>(
      builder: (context, showcaseState, auth, _) {
        final items = showcaseState.items;
        final categories = showcaseState.categories;
        final isLoading = showcaseState.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('创意作品展示'),
            backgroundColor: GlowUpColors.card,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: () => showcaseState.loadItems(
                    category: showcaseState.activeCategory),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: auth.isAuthenticated
                ? () => _pickAndUpload(context, showcaseState)
                : () => _showLoginSnack(context),
            icon: const Icon(Icons.cloud_upload),
            label: const Text('上传作品'),
            backgroundColor: GlowUpColors.sunset,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: showcaseState.activeCategory == 'all',
                      onSelected: (_) =>
                          showcaseState.loadItems(category: 'all'),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_friendlyCategory(category.name)),
                            selected:
                                showcaseState.activeCategory == category.id,
                            onSelected: (_) =>
                                showcaseState.loadItems(category: category.id),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? const _EmptyPlaceholder()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final canDelete =
                                  _canManageItem(auth, item);
                              return _ShowcaseCard(
                                item: item,
                                onLike: auth.isAuthenticated
                                    ? () => showcaseState.toggleLike(item.id)
                                    : null,
                                onTap: () => _navigateToDetail(context, item),
                                onDelete: canDelete
                                    ? () => _confirmDelete(
                                          context,
                                          showcaseState,
                                          item,
                                        )
                                    : null,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(
      BuildContext context, ShowcaseState showcaseState) async {
    final result = await FilePicker.platform
        .pickFiles(withData: kIsWeb, type: FileType.media);
    if (result == null) return;
    final platformFile = result.files.single;

    if (!context.mounted) return;
    await _showUploadDialog(
      context,
      showcaseState,
      file: platformFile,
      suggestedTitle: platformFile.name,
    );
  }

  Future<void> _showUploadDialog(
    BuildContext context,
    ShowcaseState showcaseState, {
    required PlatformFile file,
    String? suggestedTitle,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: suggestedTitle ?? '');
    final descriptionController = TextEditingController();
    String category = 'image';

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('上传作品'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '标题'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入作品标题' : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '作品描述'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '分类',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: 'image', child: Text('妙手画坊')),
                      DropdownMenuItem(
                          value: 'music', child: Text('旋律工坊')),
                      DropdownMenuItem(
                          value: 'video', child: Text('光影剧场')),
                      DropdownMenuItem(value: 'lesson', child: Text('教案')),
                    ],
                    onChanged: (value) => category = value ?? 'image',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final resolved = await resolvePlatformFile(file);
                if (resolved == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('无法读取所选文件，请重试')),
                    );
                  }
                  return;
                }

                bool ok = false;
                try {
                  ok = await showcaseState.uploadContent(
                    title: titleController.text.trim(),
                    kind: category,
                    description: descriptionController.text.trim(),
                    visibility: 'global',
                    classroomIds: const [],
                    fileBytes: resolved.bytes,
                    fileName: resolved.name,
                    fileMimeType: resolved.mimeType,
                    preview: {
                      'fileName': file.name,
                    },
                    metadata: null,
                    teacherGenerated: false,
                    aiGenerated: category != 'lesson',
                  );
                } finally {}
                if (context.mounted) {
                  Navigator.pop(context, ok);
                }
              },
              child: const Text('上传'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (success == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('作品上传成功')));
      await showcaseState.loadItems(category: showcaseState.activeCategory);
    }
  }

  void _showLoginSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先登录后再上传作品')),
    );
  }

  void _navigateToDetail(BuildContext context, ShowcaseItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShowcaseDetailPage(item: item),
      ),
    );
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

  Future<void> _confirmDelete(
    BuildContext context,
    ShowcaseState showcaseState,
    ShowcaseItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除作品'),
        content: Text('确定要删除《${item.title}》吗？此操作无法撤销。'),
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

    final success = await showcaseState.deleteContent(item.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('作品已删除')),
      );
    } else {
      final error = showcaseState.error ?? '删除失败，请稍后再试';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
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

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.item,
    this.onLike,
    this.onTap,
    this.onDelete,
  });

  final ShowcaseItem item;
  final Future<bool> Function()? onLike;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final downloadUrl = item.downloadUrl;
    Widget? previewWidget;
    if (item.previewImageUrl != null) {
      final imageUrl = item.previewImageUrl!;
      previewWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GlowUpColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GlowUpColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.broken_image, size: 32),
          ),
        ),
      );
    } else {
      previewWidget = _buildPreviewSection(context, item);
    }
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildKindChip(item.kind, item.aiGenerated),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '删除作品',
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text('作者：${item.ownerName}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              if (item.description.isNotEmpty) Text(item.description),
              if (previewWidget != null) ...[
                const SizedBox(height: 12),
                previewWidget,
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      item.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: item.isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: onLike == null
                        ? null
                        : () async {
                            final success = await onLike!();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('操作失败，请稍后重试')),
                              );
                            }
                          },
                  ),
                  Text('${item.likes}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${item.comments}'),
                  const Spacer(),
                  if (downloadUrl != null)
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _openExternal(context, downloadUrl),
                    ),
                  Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKindChip(String kind, bool aiGenerated) {
    final categoryText = _friendlyCategory(kind);
    final color = aiGenerated ? Colors.purple : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (aiGenerated) ...[
            Icon(Icons.auto_awesome, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            categoryText,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPreviewSection(BuildContext context, ShowcaseItem item) {
    if (item.preview.isEmpty) return null;
    if (item.aiGenerated) {
      return _buildAIContentPreview(item.preview, item.kind);
    }
    final type = item.preview['type'] as String?;
    if (type == 'user_upload') {
      return _buildUserUploadPreview(context, item);
    }
    return null;
  }

  Widget _buildAIContentPreview(Map<String, dynamic> preview, String kind) {
    final type = preview['type'] as String?;

    switch (type) {
      case 'ai_image':
        return _buildAIImagePreview(preview);
      case 'ai_music':
        return _buildAIMusicPreview(preview);
      case 'ai_lesson':
        return _buildAILessonPreview(preview);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserUploadPreview(BuildContext context, ShowcaseItem item) {
    final subtype = (item.preview['subtype'] as String? ?? '').toLowerCase();
    final imageUrl = item.previewImageUrl ?? '';
    final videoUrl = item.previewVideoUrl ?? '';
    final audioUrl = item.previewAudioUrl ?? '';
    final downloadUrl = item.downloadUrl ?? '';
    final fileName = item.displayFileName;

    if (subtype == 'image' && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showImageViewer(context, imageUrl, fileName),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => _buildMediaBadge(
                  context, Icons.broken_image, '$fileName（图片加载失败）'),
            ),
          ),
        ),
      );
    }

    if (subtype == 'video' && videoUrl.isNotEmpty) {
      return _buildMediaBadge(context, Icons.videocam, '$fileName · 视频',
          url: downloadUrl.isNotEmpty ? downloadUrl : videoUrl);
    }

    if (subtype == 'audio' && audioUrl.isNotEmpty) {
      return _buildMediaBadge(context, Icons.audiotrack, '$fileName · 音频',
          url: downloadUrl.isNotEmpty ? downloadUrl : audioUrl);
    }

    if (imageUrl.isNotEmpty) {
      return _buildMediaBadge(context, Icons.insert_drive_file, fileName,
          url: imageUrl);
    }

    return _buildMediaBadge(context, Icons.insert_drive_file, fileName,
        url: downloadUrl.isNotEmpty ? downloadUrl : null);
  }

  Widget _buildMediaBadge(
    BuildContext context,
    IconData icon,
    String label, {
    String? url,
  }) {
    return InkWell(
      onTap: url != null ? () => _openExternal(context, url) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlowUpColors.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: GlowUpColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.download,
                size: 18,
                color: url != null ? Colors.grey : Colors.transparent),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageViewer(
    BuildContext outerContext,
    String imageUrl,
    String title,
  ) async {
    await showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
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
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openExternal(outerContext, imageUrl),
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

  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return;
      }
    } catch (_) {
      // Ignore and fall through to snack message.
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('无法打开链接')),
    );
  }

  Widget _buildAIImagePreview(Map<String, dynamic> preview) {
    final style = preview['style'] as String? ?? '';
    final colors = (preview['colors'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, size: 16, color: Colors.purple.shade600),
              const SizedBox(width: 6),
              Text(
                '妙手画坊预览',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          if (style.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '风格：$style',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: colors
                  .take(3)
                  .map((color) => Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade300,
                          shape: BoxShape.circle,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIMusicPreview(Map<String, dynamic> preview) {
    final genre = preview['genre'] as String? ?? '';
    final mood = preview['mood'] as String? ?? '';
    final duration = preview['duration'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(
                '旋律工坊预览',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (genre.isNotEmpty) ...[
                Text(
                  genre,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              if (mood.isNotEmpty) ...[
                if (genre.isNotEmpty)
                  Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  mood,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              if (duration.isNotEmpty) ...[
                if (genre.isNotEmpty || mood.isNotEmpty)
                  Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  duration,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAILessonPreview(Map<String, dynamic> preview) {
    final subject = preview['subject'] as String? ?? '';
    final ageGroup = preview['ageGroup'] as String? ?? '';
    final objectives = (preview['objectives'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Text(
                '教案预览',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (subject.isNotEmpty) ...[
                Text(
                  subject,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              if (ageGroup.isNotEmpty) ...[
                if (subject.isNotEmpty)
                  Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  ageGroup,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          if (objectives.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '目标：${objectives.first}${objectives.length > 1 ? '...' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('暂无作品，快来成为第一个分享创意的人吧！'),
          ],
        ),
      ),
    );
  }
}
