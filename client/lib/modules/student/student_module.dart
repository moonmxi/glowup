import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/showcase.dart';
import '../../screens/showcase/showcase_detail_page.dart';
import '../../services/ai_analyzers.dart';
import '../../state/auth_state.dart';
import '../../state/classroom_state.dart';
import '../../state/showcase_state.dart';
import '../../theme/glowup_theme.dart';
import '../../utils/platform_file_helper.dart';
import '../../widgets/glow_card.dart';

class StudentModule extends StatefulWidget {
  const StudentModule({super.key});

  @override
  State<StudentModule> createState() => _StudentModuleState();
}

class _StudentModuleState extends State<StudentModule> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const StudentHomePage(),
    const StudentAiStudioPage(),
    const StudentShowcasePage(),
    const StudentProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassroomState>().refreshAll();
      context.read<ShowcaseState>().loadFeed(scope: 'classes');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: GlowUpColors.secondary,
        unselectedItemColor: GlowUpColors.dusk.withOpacity(0.45),
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI小光'),
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: '作品'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthState, ClassroomState>(
      builder: (context, auth, classroomState, _) {
        final classroom = classroomState.classroom;
        final user = auth.user;
        final showcaseState = context.read<ShowcaseState>();
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('你好，小小创作者'),
            backgroundColor: GlowUpColors.secondary,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await classroomState.refreshAll();
              await showcaseState.loadFeed(
                    scope: 'classes',
                    classId: classroom?.id,
                  );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlowCard(
                  accent: GlowUpColors.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '欢迎回来，${user?.username ?? '同学'}！',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '小光今天想和你一起用音乐和颜色探索世界，保持好奇心哦！',
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        '我的班级',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      classroom == null
                          ? const Text('你还没有加入班级，请在“我的”中输入班级编码。')
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: GlowUpColors.secondary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('班级名称：${classroom.name}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text('班级编码：${classroom.code}'),
                                  const SizedBox(height: 8),
                                  Text('同学人数：${classroom.studentCount}'),
                                ],
                              ),
                            ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GlowUpColors.secondary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lightbulb,
                                color: GlowUpColors.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '今日小光的耳语',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '试着用身边的声音和颜色讲一个小故事，下一节课分享给大家，小光会给你点赞！',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StudentAiStudioPage extends StatefulWidget {
  const StudentAiStudioPage({super.key});

  @override
  State<StudentAiStudioPage> createState() => _StudentAiStudioPageState();
}

class _StudentAiStudioPageState extends State<StudentAiStudioPage> {
  final List<StudentMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiChatMentor _chatMentor = AiChatMentor();
  final AiImageAnalyzer _imageAnalyzer = AiImageAnalyzer();
  bool _isThinking = false;
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('和小光聊聊'),
        backgroundColor: GlowUpColors.secondary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: '和小光聊聊你的想法、心情或课堂问题吧',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _sendTextMessage,
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('发送'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_pendingImageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.memory(
                            _pendingImageBytes!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.4),
                              ),
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _pendingImageBytes = null;
                                  _pendingImageName = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _UploadArtworkButton(
                      onPressed: _pickAndProcessArtwork,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (_pendingImageBytes != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('先告诉小光你想分享的内容吧')),
        );
      }
      return;
    }
    _textController.clear();
    final imageBytes = _pendingImageBytes;
    final imageName = _pendingImageName;
    setState(() {
      _pendingImageBytes = null;
      _pendingImageName = null;
      _messages.add(
        StudentMessage(
          isUser: true,
          text: text,
          imageBytes: imageBytes,
          imageName: imageName,
        ),
      );
      _isThinking = true;
    });
    await _scrollToEnd();

    try {
      final reply = imageBytes != null
          ? await _imageAnalyzer.analyzeImageBytes(
              imageBytes: imageBytes,
              fileName: imageName,
              question: text,
            )
          : await _chatMentor.replyTo(text);
      if (!mounted) return;
      setState(() {
        _messages.add(StudentMessage(isUser: false, text: reply));
        _isThinking = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isThinking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('小光回复失败：$error')),
      );
    }
    await _scrollToEnd();
  }

  Future<void> _pickAndProcessArtwork() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform
        .pickFiles(withData: true, type: FileType.image);
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null && file.readStream == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('无法读取文件，请重试')),
      );
      return;
    }

    final resolved = await resolvePlatformFile(file);
    if (!mounted) return;
    if (resolved == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('无法解析所选文件，请重新选择')),
      );
      return;
    }
    if (resolved.bytes.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('读取到的图片大小为 0，请重新选择')),
      );
      return;
    }

    setState(() {
      _pendingImageBytes = resolved.bytes;
      _pendingImageName = resolved.name;
      if (_textController.text.trim().isEmpty) {
        final displayName = resolved.name.isNotEmpty
            ? resolved.name
            : (file.name.isNotEmpty ? file.name : '我的作品');
        _textController.text = '这是我的作品《$displayName》，请小光点评！';
      }
    });
    await _scrollToEnd();
  }

  Future<void> _scrollToEnd() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final StudentMessage message;

  @override
  Widget build(BuildContext context) {
  final alignment =
    message.isUser ? Alignment.centerRight : Alignment.centerLeft;
  final color = message.isUser
    ? GlowUpColors.secondary.withValues(alpha: 0.9)
    : GlowUpColors.card;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.memory(
                        message.imageBytes!,
                        fit: BoxFit.cover,
                        height: 160,
                        width: double.infinity,
                      ),
                      if (message.imageName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.image, size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Tooltip(
                                  message: message.imageName!,
                                  child: Text(
                                    message.imageName!,
                                    style: TextStyle(color: textColor, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (message.imageBytes != null)
              const SizedBox(height: 8)
            else if (message.imageName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.image, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Tooltip(
                        message: message.imageName!,
                        child: Text(
                          message.imageName!,
                          style: TextStyle(color: textColor, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (message.text != null)
              Text(
                message.text!,
                style: TextStyle(color: textColor),
                softWrap: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadArtworkButton extends StatelessWidget {
  const _UploadArtworkButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.brush),
        label: const Text('上传作品'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class StudentShowcasePage extends StatefulWidget {
  const StudentShowcasePage({super.key});

  @override
  State<StudentShowcasePage> createState() => _StudentShowcasePageState();
}

class _StudentShowcasePageState extends State<StudentShowcasePage> {
  String _scope = 'classes';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final showcaseState = context.read<ShowcaseState>();
      final classroomId = context.read<ClassroomState>().classroom?.id;
      showcaseState.loadFeed(scope: _scope, classId: classroomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ShowcaseState, ClassroomState, AuthState>(
      builder: (context, showcaseState, classroomState, auth, _) {
        final items = showcaseState.items;
        final isLoading = showcaseState.isLoading;
        final classroom = classroomState.classroom;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('作品橱窗'),
            backgroundColor: GlowUpColors.secondary,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => showcaseState.loadFeed(
                  scope: _scope,
                  classId: classroom?.id,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: auth.isAuthenticated ? _uploadStudentArtwork : null,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('上传我的作品'),
            backgroundColor: GlowUpColors.secondary,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'classes',
                      label: Text('班级作品'),
                    ),
                    ButtonSegment(
                      value: 'global',
                      label: Text('全平台'),
                    ),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (value) {
                    setState(() => _scope = value.first);
                    showcaseState.loadFeed(
                      scope: _scope,
                      classId: classroom?.id,
                    );
                  },
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? const Center(child: Text('还没有作品，快来第一个分享吧！'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _StudentShowcaseCard(
                                item: item,
                                onLike: auth.isAuthenticated
                                    ? () => showcaseState.toggleLike(item.id)
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ShowcaseDetailPage(item: item),
                                  ),
                                ),
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

  Future<void> _uploadStudentArtwork() async {
    final showcaseState = context.read<ShowcaseState>();
    final classroom = context.read<ClassroomState>().classroom;
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );
    if (result == null) return;
    final file = result.files.single;

    final formKey = GlobalKey<FormState>();
    final defaultTitle = _deriveTitle(file.name);
    final titleController = TextEditingController(text: defaultTitle);
    final descriptionController = TextEditingController();

    if (!parentContext.mounted) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    // ignore: use_build_context_synchronously
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('完善作品信息'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '作品标题',
                    hintText: '请输入作品标题',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请填写作品标题' : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '作品描述（可选）',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('上传'),
            ),
          ],
        );
      },
    );

    if (!parentContext.mounted) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    if (confirmed != true) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    final resolved = await resolvePlatformFile(file);
    if (resolved == null) {
      if (!parentContext.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('无法读取所选文件，请重新尝试')),
      );
      return;
    }
    final Uint8List uploadBytes = resolved.bytes;
    final String uploadName =
        resolved.name.isNotEmpty ? resolved.name : 'student_artwork.png';
    final String? uploadMime = resolved.mimeType;
    bool success = false;
    try {
      success = await showcaseState.uploadContent(
        title: titleController.text.trim().isEmpty
            ? defaultTitle
            : titleController.text.trim(),
        kind: 'image',
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : '来自学生的原创作品',
        visibility: 'classes',
        classroomIds: classroom != null ? [classroom.id] : const [],
        metadata: {
          'uploader': 'student',
          'note': '学生客户端上传',
          'originalSize': file.size,
        },
        preview: {
          'fileName': file.name,
          'type': 'user_upload',
        },
        fileBytes: uploadBytes,
        fileName: uploadName,
        fileMimeType: uploadMime,
        teacherGenerated: false,
        aiGenerated: false,
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }

    if (success && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('作品已上传，请等待老师点评')),
      );
      await showcaseState.loadFeed(
        scope: _scope,
        classId: classroom?.id,
      );
    } else if (mounted) {
      final message = showcaseState.error ?? '作品上传失败，请稍后再试';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _StudentShowcaseCard extends StatelessWidget {
  const _StudentShowcaseCard({
    required this.item,
    this.onLike,
    this.onTap,
  });

  final ShowcaseItem item;
  final Future<bool> Function()? onLike;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final previewImage = item.previewImageUrl;
    final downloadUrl = item.downloadUrl;
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
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _KindChip(kind: item.kind, aiGenerated: item.aiGenerated),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '作者：${item.ownerName}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                item.description.isEmpty ? '这位作者还没有留下描述。' : item.description,
              ),
              if (previewImage != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    previewImage,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      height: 160,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GlowUpColors.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.broken_image, size: 32),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      item.isLiked ? Icons.favorite : Icons.favorite_border,
                      color:
                          item.isLiked ? GlowUpColors.sunset : Colors.grey[600],
                    ),
                    onPressed: onLike == null
                        ? null
                        : () async {
                            final ok = await onLike!();
                            if (!ok && context.mounted) {
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
                      onPressed: () => _openExternal(downloadUrl),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _openExternal(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind, required this.aiGenerated});

  final String kind;
  final bool aiGenerated;

  @override
  Widget build(BuildContext context) {
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

String _deriveTitle(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex > 0) {
    final stem = fileName.substring(0, dotIndex).trim();
    if (stem.isNotEmpty) return stem;
  }
  return fileName;
}

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthState, ClassroomState>(
      builder: (context, auth, classroomState, _) {
        final classroom = classroomState.classroom;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('我的'),
            backgroundColor: GlowUpColors.secondary,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlowCard(
                accent: GlowUpColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '我的资料',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('用户名：${auth.user?.username ?? '未登录'}'),
                    const SizedBox(height: 6),
                    Text('身份：学生'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlowCard(
                accent: GlowUpColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '加入班级',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (classroom != null) ...[
                      Text('你属于：${classroom.name}'),
                      const SizedBox(height: 6),
                      Text('班级编码：${classroom.code}'),
                    ] else ...[
                      const Text('输入老师提供的班级编码，即可加入班级：'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: '班级编码',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _joining
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final code = _codeController.text.trim();
                                  if (code.isEmpty) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('请输入班级编码')),
                                    );
                                    return;
                                  }
                                  setState(() => _joining = true);
                                  final success =
                                      await classroomState.joinClassroom(code);
                                  if (!mounted) return;
                                  setState(() => _joining = false);
                                  if (success) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('加入班级成功')),
                                    );
                                    await classroomState.refreshAll();
                                  } else {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          classroomState.error ?? '加入失败，请确认编码',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: _joining
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('加入班级'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AuthState>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentMessage {
  StudentMessage({
    required this.isUser,
    this.text,
    this.imageName,
    this.imageBytes,
  });

  final bool isUser;
  final String? text;
  final String? imageName;
  final Uint8List? imageBytes;
}
