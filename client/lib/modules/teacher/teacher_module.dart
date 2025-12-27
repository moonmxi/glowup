import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/classroom.dart';
import '../../models/story_asset.dart';
import '../../models/showcase.dart';
import '../../models/teacher_story.dart';
import '../../screens/analysis/audio_analysis_page.dart';
import '../../screens/analysis/image_analysis_page.dart';
import '../../screens/showcase/showcase_detail_page.dart';
import '../../screens/story/story_creative_suite_page.dart';
import '../../state/ai_generation_state.dart';
import '../../state/auth_state.dart';
import '../../state/classroom_state.dart';
import '../../state/showcase_state.dart';
import '../../state/story_orchestrator_state.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';
import '../../utils/platform_file_helper.dart';

class TeacherModule extends StatefulWidget {
  const TeacherModule({super.key});

  @override
  State<TeacherModule> createState() => _TeacherModuleState();
}

class _TeacherModuleState extends State<TeacherModule> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      TeacherStoryStudioPage(),
      TeacherClassroomPage(),
      TeacherShowcaseHubPage(),
      TeacherProfilePage(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthState>();
      if (auth.user?.isTeacher ?? false) {
        context.read<ClassroomState>().refreshAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: GlowUpColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: '课堂故事',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: '班级',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: '作品橱窗',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class TeacherStoryStudioPage extends StatefulWidget {
  const TeacherStoryStudioPage({super.key});

  @override
  State<TeacherStoryStudioPage> createState() => _TeacherStoryStudioPageState();
}

class _TeacherStoryStudioPageState extends State<TeacherStoryStudioPage> {
  bool _storyInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final classroomState = context.read<ClassroomState>();
    final storyState = context.read<StoryOrchestratorState>();
    storyState.attachMediaStates(
      videoState: context.read<VideoGenerationState>(),
      musicState: context.read<MusicGenerationState>(),
    );
    if (!_storyInitialized && classroomState.stories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = storyState.activeStory;
        final stories = classroomState.stories;
        if (current == null && stories.isNotEmpty) {
          storyState.loadStory(stories.first);
        }
      });
      _storyInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClassroomState, StoryOrchestratorState>(
      builder: (context, classroomState, storyState, _) {
        final stories = classroomState.stories;
        final activeStory = storyState.activeStory;
        final assets = storyState.assets;
        final availableClasses = storyState.availableClassrooms;

        return Scaffold(
          appBar: AppBar(
            title: const Text('课堂故事工作室'),
            actions: [
              IconButton(
                tooltip: '刷新故事',
                icon: const Icon(Icons.refresh),
                onPressed: () => classroomState.refreshStories(),
              ),
              TextButton.icon(
                onPressed: () => _showCreateStoryDialog(
                  context,
                  storyState: storyState,
                  classroomState: classroomState,
                  classrooms: availableClasses,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('新建故事'),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await classroomState.refreshStories();
              if (storyState.activeStory != null) {
                final updated = classroomState.stories.firstWhere(
                  (story) => story.id == storyState.activeStory!.id,
                  orElse: () => storyState.activeStory!,
                );
                storyState.loadStory(updated);
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (stories.isEmpty) ...[
                  _EmptyStoryPlaceholder(onCreate: () {
                    _showCreateStoryDialog(
                      context,
                      storyState: storyState,
                      classroomState: classroomState,
                      classrooms: availableClasses,
                    );
                  }),
                ] else ...[
                  _StorySelector(
                    stories: stories,
                    activeStoryId: activeStory?.id,
                    onSelect: (story) => storyState.loadStory(story),
                  ),
                  const SizedBox(height: 16),
                  if (activeStory != null) ...[
                    _StoryOverviewCard(
                      story: activeStory,
                      classrooms: availableClasses,
                      onEditTheme: (theme) => _updateStoryTheme(
                        context,
                        classroomState,
                        storyState,
                        activeStory,
                        theme,
                      ),
                      onShareChanged: (share) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await storyState.setStoryVisibility(share);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(share ? '故事已公开到平台' : '故事仅自己可见'),
                          ),
                        );
                      },
                      isShared: storyState.isShared,
                      onDelete: () => _confirmDeleteStory(
                        context,
                        storyState,
                        activeStory,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._studioSteps.map((kind) {
                      final asset = assets[kind];
                      return StoryStepCard(
                        key: ValueKey('$kind-${asset?.status}'),
                        asset: asset ??
                            StoryAsset(
                              kind: kind,
                              label: _stepLabels[kind] ?? kind,
                            ),
                        isBusy: storyState.isBusy,
                        onGenerate: () =>
                            _handleGenerate(context, storyState, kind),
                        onUpload: () => _handleUpload(
                          context,
                          storyState,
                          kind,
                          availableClasses,
                        ),
                      );
                    }),
                  ],
                ],
                const SizedBox(height: 28),
                Text(
                  '教师工具箱',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _StoryToolsCard(
                  onColorAnalysis: () =>
                      _openAnalysis(context, const ImageAnalysisPage()),
                  onRhythmLab: () =>
                      _openAnalysis(context, const AudioAnalysisPage()),
                  onCreativeSuite: () => _openCreativeSuite(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateStoryDialog(
    BuildContext context, {
    required StoryOrchestratorState storyState,
    required ClassroomState classroomState,
    required List<ClassroomInfo> classrooms,
  }) async {
    if (classrooms.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('请先创建班级'),
          content: const Text('小光需要知道故事要服务的班级，请到“班级”页面创建或导入班级。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('好的'),
            ),
          ],
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final themeController = TextEditingController(text: '缤纷课堂的创意故事');
    final selectedClasses = <String>{classrooms.first.id};

    final messenger = ScaffoldMessenger.of(context);
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建课堂故事'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '故事名称',
                      hintText: '例如：春日色彩探险',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '请输入故事名称'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: themeController,
                    decoration: const InputDecoration(
                      labelText: '故事主题 / 情境',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '关联班级',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: classrooms.map((room) {
                      final selected = selectedClasses.contains(room.id);
                      return FilterChip(
                        label: Text(room.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            if (selected) {
                              selectedClasses.remove(room.id);
                            } else {
                              selectedClasses.add(room.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedClasses.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请至少选择一个班级')),
                  );
                  return;
                }
                final story = await storyState.createStory(
                  title: titleController.text.trim(),
                  classroomIds: selectedClasses.toList(),
                  theme: themeController.text.trim(),
                );
                if (story != null) {
                  await classroomState.refreshStories();
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              child: const Text('创建故事'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('故事已创建，小光准备就绪！')),
      );
    }
  }

  Future<void> _confirmDeleteStory(
    BuildContext context,
    StoryOrchestratorState storyState,
    TeacherStory story,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课堂故事'),
        content: Text('确定要删除故事《${story.title}》吗？相关素材也会一起移除。'),
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
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await storyState.deleteStory(story.id);
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('故事已删除')),
      );
    } else {
      final error = storyState.error ?? '删除失败，请稍后再试';
      messenger.showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _updateStoryTheme(
    BuildContext context,
    ClassroomState classroomState,
    StoryOrchestratorState storyState,
    TeacherStory story,
    String theme,
  ) async {
    await classroomState.updateStory(
      storyId: story.id,
      theme: theme,
    );
    final refreshed = classroomState.stories.firstWhere(
      (item) => item.id == story.id,
      orElse: () => story.copyWith(theme: theme),
    );
    storyState.loadStory(refreshed);
  }

  Future<void> _handleGenerate(
    BuildContext context,
    StoryOrchestratorState storyState,
    String kind,
  ) async {
    final activeStory = storyState.activeStory;
    if (activeStory == null) return;
    final theme = activeStory.theme ?? activeStory.title;

    switch (kind) {
      case 'lesson_plan':
        await _showLessonPlanDialog(context, storyState, theme);
        break;
      case 'background_image':
        await storyState.generateBackgroundImage(theme: theme);
        break;
      case 'video':
        await storyState.generateVideoStoryboard(theme: theme);
        break;
      case 'music':
        await storyState.generateMusicCue(theme: theme);
        break;
      default:
        break;
    }
  }

  Future<void> _handleUpload(
    BuildContext context,
    StoryOrchestratorState storyState,
    String kind,
    List<ClassroomInfo> classrooms,
  ) async {
    final asset = storyState.assets[kind];
    if (asset == null ||
        (asset.status != StoryAssetStatus.ready &&
            asset.status != StoryAssetStatus.uploaded)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先让小光完成生成，再上传到课堂。')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        String visibility =
            asset.metadata['visibility'] as String? ?? 'classes';
        final selected = <String>{
          ...?asset.metadata['classroomIds'] as List<String>?,
        };
        if (selected.isEmpty && classrooms.isNotEmpty) {
          selected.add(classrooms.first.id);
        }
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择分享范围'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '分享范围',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButton<String>(
                      value: visibility,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'classes',
                          child: Text('仅指定班级可见'),
                        ),
                        DropdownMenuItem(
                          value: 'global',
                          child: Text('全平台所有班级可见'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => visibility = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (visibility == 'classes')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: classrooms.map((room) {
                        final isSelected = selected.contains(room.id);
                        return FilterChip(
                          label: Text(room.name),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                selected.remove(room.id);
                              } else {
                                selected.add(room.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (visibility == 'classes' && selected.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请选择至少一个班级')),
                      );
                      return;
                    }
                    await storyState.uploadAsset(
                      kind: kind,
                      visibility: visibility,
                      classroomIds: selected.toList(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('课堂素材已上传至作品橱窗')),
                      );
                    }
                  },
                  child: const Text('确定上传'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAnalysis(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openCreativeSuite(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoryCreativeSuitePage()),
    );
  }

  Future<void> _showLessonPlanDialog(
    BuildContext context,
    StoryOrchestratorState storyState,
    String theme,
  ) async {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController(text: '美术');
    final gradeController = TextEditingController(text: '三年级');
    final focusController = TextEditingController(text: '创意表达,色彩混合,故事讲述');
    final descriptionController =
        TextEditingController(text: '围绕“$theme”设计一次45分钟的课堂，包含互动和延伸。');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('让小光编写教案'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: '学科'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '请输入学科' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gradeController,
                    decoration: const InputDecoration(labelText: '年级'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '请输入年级' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: focusController,
                    decoration: const InputDecoration(
                      labelText: '课堂重点（逗号分隔）',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: '课堂补充说明'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final focus = focusController.text
                    .split(RegExp(r'[，,]'))
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList();
                await storyState.generateLessonPlan(
                  subject: subjectController.text.trim(),
                  grade: gradeController.text.trim(),
                  focus: focus.isEmpty ? ['创意表达'] : focus,
                  description: descriptionController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('开始生成'),
            ),
          ],
        );
      },
    );
  }
}

class _StorySelector extends StatelessWidget {
  const _StorySelector({
    required this.stories,
    required this.activeStoryId,
    required this.onSelect,
  });

  final List<TeacherStory> stories;
  final String? activeStoryId;
  final ValueChanged<TeacherStory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final story = stories[index];
          final selected = story.id == activeStoryId;
          return ChoiceChip(
            label: Text(story.title),
            tooltip: story.theme ?? story.title,
            selected: selected,
            onSelected: (_) => onSelect(story),
          );
        },
      ),
    );
  }
}

class _StoryOverviewCard extends StatelessWidget {
  const _StoryOverviewCard({
    required this.story,
    required this.classrooms,
    required this.onEditTheme,
    required this.onShareChanged,
    required this.isShared,
    required this.onDelete,
  });

  final TeacherStory story;
  final List<ClassroomInfo> classrooms;
  final ValueChanged<String> onEditTheme;
  final Future<void> Function(bool) onShareChanged;
  final bool isShared;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final classNames = story.classroomIds
        .map((id) => classrooms.firstWhere(
              (room) => room.id == id,
              orElse: () => ClassroomInfo(
                  id: id, code: '', name: '班级', students: const []),
            ))
        .map((room) => room.name)
        .join('、');

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlowUpColors.lavender.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: GlowUpColors.lavender),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '关联班级：$classNames',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '修改主题',
                onPressed: () => _editTheme(context),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: '删除故事',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            story.theme ?? '点击右上角编辑故事主题，小光会以此为线索串联课堂。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: isShared,
            onChanged: (value) {
              onShareChanged(value);
            },
            title: const Text('公开到平台'),
            subtitle: const Text('开启后，其他老师可以在平台中一键导入这个故事'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTheme(BuildContext context) async {
    final controller = TextEditingController(text: story.theme ?? story.title);
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新故事主题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '主题 / 情境',
            helperText: '例如：在花田里寻找色彩的旅程',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (updated == true && controller.text.trim().isNotEmpty) {
      onEditTheme(controller.text.trim());
    }
  }
}

class StoryStepCard extends StatefulWidget {
  const StoryStepCard({
    super.key,
    required this.asset,
    required this.isBusy,
    required this.onGenerate,
    required this.onUpload,
  });

  final StoryAsset asset;
  final bool isBusy;
  final VoidCallback onGenerate;
  final VoidCallback onUpload;

  @override
  State<StoryStepCard> createState() => _StoryStepCardState();
}

class _StoryStepCardState extends State<StoryStepCard> {
  bool _isExpanded = true;

  bool get _canCollapse {
    return widget.asset.status == StoryAssetStatus.ready ||
        widget.asset.status == StoryAssetStatus.uploaded;
  }

  @override
  void didUpdateWidget(covariant StoryStepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_canCollapse && !_isExpanded) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        widget.asset.summary ?? _defaultSummary(widget.asset.kind);
    final statusChip = _buildStatusChip(widget.asset);
    final canCollapse = _canCollapse;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.asset.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 12),
                statusChip,
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  color: canCollapse ? GlowUpColors.primary : Colors.grey,
                  tooltip: canCollapse ? '折叠内容' : '生成后可折叠',
                  onPressed: canCollapse
                      ? () => setState(() => _isExpanded = !_isExpanded)
                      : null,
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  (!canCollapse || _isExpanded)
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _SummarySection(
                    summary: summary,
                    preview: widget.asset.preview,
                    metadata: widget.asset.metadata,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.isBusy &&
                                widget.asset.status ==
                                    StoryAssetStatus.generating
                            ? null
                            : widget.onGenerate,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('让小光生成'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            widget.asset.status == StoryAssetStatus.ready ||
                                    widget.asset.status ==
                                        StoryAssetStatus.uploaded
                                ? widget.onUpload
                                : null,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(
                          widget.asset.status == StoryAssetStatus.uploaded
                              ? '已上传'
                              : '上传到课堂',
                        ),
                      ),
                    ],
                  ),
                  if (widget.asset.status == StoryAssetStatus.generating)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (widget.asset.error != null &&
                      widget.asset.error!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.asset.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            if (!canCollapse)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '生成完成后可折叠，保持创作区整洁。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Chip _buildStatusChip(StoryAsset asset) {
    late final String label;
    late final Color color;
    switch (asset.status) {
      case StoryAssetStatus.idle:
        label = '待生成';
        color = Colors.grey;
        break;
      case StoryAssetStatus.generating:
        label = '生成中';
        color = GlowUpColors.primary;
        break;
      case StoryAssetStatus.ready:
        label = '已就绪';
        color = GlowUpColors.breeze;
        break;
      case StoryAssetStatus.uploading:
        label = '上传中';
        color = GlowUpColors.sunset;
        break;
      case StoryAssetStatus.uploaded:
        label = '已上传';
        color = GlowUpColors.lavender;
        break;
      case StoryAssetStatus.failed:
        label = '生成失败';
        color = Colors.red;
        break;
    }
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _defaultSummary(String kind) {
    switch (kind) {
      case 'lesson_plan':
        return '小光可以根据主题生成完整的45分钟课堂教案，包含目标、流程与延伸。';
      case 'background_image':
        return '生成可投影或打印的教学背景图，营造沉浸式课堂。';
      case 'video':
        return '生成30秒开场动画，带孩子进入新的课堂情境。';
      case 'music':
        return '生成课堂背景音乐与节奏提示，配合教学环节使用。';
      default:
        return '让小光帮你完成课堂的这一步。';
    }
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.summary,
    required this.preview,
    required this.metadata,
  });

  final String summary;
  final Map<String, dynamic> preview;
  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final type = preview['type']?.toString();

    if (type == 'lesson_plan') {
      final objectives = _stringItems(preview['objectives']);
      final materials = _stringItems(preview['materials']);
      final stages = _lessonPlanStages(preview['stages']);
      final questions = _stringItems(preview['questions']);
      final differentiation = _stringItems(preview['differentiation']);
      final summaryNotes = _stringItems(preview['summary']);
      final extensions =
          _stringItems(preview['extensions'] ?? preview['homework']);
      return _LessonPlanView(
        objectives: objectives,
        materials: materials,
        stages: stages,
        questions: questions,
        differentiation: differentiation,
        summaryNotes: summaryNotes,
        extensions: extensions,
      );
    }

    final widgets = <Widget>[];

    // 对于text类型（如教案），只显示summary，不重复显示body
    widgets.add(
      Text(
        summary,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );

    if (type == 'moodboard') {
      final palette = _stringItems(preview['palette']);
      final scenes = _stringItems(preview['scenes']);
      final textures = _stringItems(preview['textures'])
        ..addAll(_stringItems(preview['texture']));
      if (palette.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 12))
          ..add(_ColorPalettePreview(palette: palette));
      }
      if (scenes.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(_BulletList(title: '情境构想', items: scenes));
      }
      if (textures.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(_BulletList(title: '可尝试素材', items: textures));
      }
    } else if (type == 'storyboard') {
      final segments = _storyboardSegments(preview['segments']);
      final ambient = _stringValue(preview['ambient']) ??
          _stringValue(preview['ambientSound']);
      final script = _stringValue(preview['script']);
      final videoUrl =
          _stringValue(preview['videoUrl']) ?? _stringValue(preview['fileUrl']);
      if (segments.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 12))
          ..add(_StoryboardPreview(segments: segments));
      }
      if (ambient != null) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(Text('建议环境音：$ambient',
              style: Theme.of(context).textTheme.bodySmall));
      }
      if (script != null && script.trim().isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(_ScriptBlock(script: script.trim()));
      }
      if (videoUrl != null && videoUrl.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 12))
          ..add(_InlineVideoPlayer(
            videoUrl: videoUrl,
          ))
          ..add(const SizedBox(height: 8));
        widgets.add(
          _MediaActionRow(
            icon: Icons.movie_filter,
            title: '课堂开场动画',
            buttonLabel: '外部播放 / 下载',
            onTap: () => _openExternal(videoUrl),
          ),
        );
      }
    } else if (type == 'music') {
      final tempo = _stringValue(preview['tempo']);
      final mode = _stringValue(preview['mode']);
      final structureLines = _musicStructureLines(preview['structure']);
      final encouragement = _stringValue(preview['encouragement']);
      final tracks =
          _musicTracks(preview['tracks'] ?? preview['generatedTracks']);
      if (tempo != null || mode != null) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(Text(
            '节奏：${tempo ?? '未知'}    调式：${mode ?? '未知'}',
            style: Theme.of(context).textTheme.bodySmall,
          ));
      }
      if (structureLines.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(_BulletList(title: '课堂使用建议', items: structureLines));
      }
      if (encouragement != null) {
        widgets
          ..add(const SizedBox(height: 8))
          ..add(Text(encouragement,
              style: Theme.of(context).textTheme.bodySmall));
      }
      if (tracks.isNotEmpty) {
        widgets
          ..add(const SizedBox(height: 12))
          ..add(Text('生成音乐',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)))
          ..add(const SizedBox(height: 8));
        widgets.addAll(tracks.map((track) => _MusicTrackTile(track: track)));
      }
    } else if (type == 'image') {
      final url = _stringValue(preview['imageUrl']);
      final downloadUrl = _stringValue(preview['fileUrl']) ?? url;
      if (url != null) {
        widgets
          ..add(const SizedBox(height: 12))
          ..add(_ImagePreview(imageUrl: url));
        if (downloadUrl != null) {
          widgets
            ..add(const SizedBox(height: 8))
            ..add(
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openExternal(downloadUrl),
                  icon: const Icon(Icons.download),
                  label: const Text('下载图片'),
                ),
              ),
            );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Map<String, dynamic>> _lessonPlanStages(dynamic value) {
    final stages = <Map<String, dynamic>>[];
    if (value is List) {
      for (final entry in value) {
        if (entry is Map) {
          final name =
              _stringValue(entry['name'] ?? entry['stage'] ?? entry['title']);
          final duration = _stringValue(entry['duration'] ?? entry['time']);
          final goal = _stringValue(
              entry['goal'] ?? entry['focus'] ?? entry['objective']);
          final activities =
              _stringItems(entry['activities'] ?? entry['steps']);
          final teacher = _stringItems(entry['teacher'] ??
              entry['teacherActions'] ??
              entry['teacherNotes']);
          final students = _stringItems(entry['students'] ??
              entry['studentActivities'] ??
              entry['studentActions']);
          final questions =
              _stringItems(entry['questions'] ?? entry['keyQuestions']);
          final materials = _stringItems(entry['materials']);
          final stage = <String, dynamic>{
            'name': name ?? '课堂环节',
          };
          if (duration != null) stage['duration'] = duration;
          if (goal != null) stage['goal'] = goal;
          if (activities.isNotEmpty) stage['activities'] = activities;
          if (teacher.isNotEmpty) stage['teacher'] = teacher;
          if (students.isNotEmpty) stage['students'] = students;
          if (questions.isNotEmpty) stage['questions'] = questions;
          if (materials.isNotEmpty) stage['materials'] = materials;
          stages.add(stage);
        } else if (entry is String) {
          final text = entry.trim();
          if (text.isNotEmpty) {
            stages.add({'name': text});
          }
        }
      }
    }
    return stages;
  }

  List<String> _stringItems(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[\n,;]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  List<Map<String, String>> _storyboardSegments(dynamic value) {
    final segments = <Map<String, String>>[];
    if (value is List) {
      for (final entry in value) {
        if (entry is Map) {
          final scene = _stringValue(entry['scene']);
          final narration = _stringValue(entry['narration']);
          final camera = _stringValue(entry['cameraHint'] ?? entry['camera']);
          final music = _stringValue(entry['musicCue'] ?? entry['music']);
          if (scene == null &&
              narration == null &&
              camera == null &&
              music == null) {
            continue;
          }
          segments.add({
            if (scene != null) 'scene': scene,
            if (narration != null) 'narration': narration,
            if (camera != null) 'cameraHint': camera,
            if (music != null) 'musicCue': music,
          });
        } else if (entry is String) {
          final text = entry.trim();
          if (text.isEmpty) continue;
          final parts = text.split(RegExp(r'[｜|]'));
          final scene = parts.isNotEmpty ? parts.first.trim() : '';
          final narration =
              parts.length > 1 ? parts.sublist(1).join('｜').trim() : '';
          if (scene.isEmpty && narration.isEmpty) continue;
          segments.add({
            if (scene.isNotEmpty) 'scene': scene,
            if (narration.isNotEmpty) 'narration': narration,
          });
        } else if (entry != null) {
          final text = entry.toString().trim();
          if (text.isEmpty) continue;
          segments.add({'scene': text});
        }
      }
    }
    return segments;
  }

  List<String> _musicStructureLines(dynamic value) {
    final lines = <String>[];
    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final label = _stringValue(item['label']);
          final duration = _stringValue(item['duration']);
          final purpose = _stringValue(item['purpose']);
          final buffer = StringBuffer();
          if (label != null) {
            buffer.write(label);
          }
          if (duration != null) {
            if (buffer.isEmpty) {
              buffer.write(duration);
            } else {
              buffer.write('（$duration）');
            }
          }
          if (purpose != null) {
            if (buffer.isEmpty) {
              buffer.write(purpose);
            } else {
              buffer.write('：$purpose');
            }
          }
          final line = buffer.toString().trim();
          if (line.isNotEmpty) {
            lines.add(line);
          }
        } else if (item != null) {
          final text = item.toString().trim();
          if (text.isNotEmpty) {
            lines.add(text);
          }
        }
      }
    }
    return lines;
  }

  List<Map<String, String>> _musicTracks(dynamic value) {
    final tracks = <Map<String, String>>[];
    if (value is List) {
      for (final entry in value) {
        if (entry is Map) {
          final title = _stringValue(entry['title']) ?? '课堂音乐';
          final audio = _stringValue(entry['audioUrl']);
          final cover = _stringValue(entry['coverUrl']);
          final localAudio = _stringValue(entry['localAudioPath']);
          tracks.add({
            'title': title,
            if (audio != null) 'audioUrl': audio,
            if (cover != null) 'coverUrl': cover,
            if (localAudio != null) 'localAudioPath': localAudio,
          });
        } else if (entry is String) {
          final text = entry.trim();
          if (text.isNotEmpty) {
            tracks.add({'title': text});
          }
        }
      }
    }
    return tracks;
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MediaActionRow extends StatelessWidget {
  const _MediaActionRow({
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ScriptBlock extends StatelessWidget {
  const _ScriptBlock({required this.script});

  final String script;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlowUpColors.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            script,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _copyScript(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('复制脚本'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyScript(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: script));
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(content: Text('脚本已复制到剪贴板')),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({this.videoUrl});

  final String? videoUrl;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _prepareController();
  }

  @override
  void didUpdateWidget(covariant _InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl) {
      _prepareController();
    }
  }

  Future<void> _prepareController() async {
    await _controller?.dispose();
    if (!mounted) return;

    setState(() {
      _controller = null;
      _initializeFuture = null;
      _loadFailed = false;
    });

    final remoteUrl = widget.videoUrl?.trim();
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      final remoteReady = await _initializeController(() {
        final uri = Uri.tryParse(remoteUrl);
        if (uri == null) return null;
        return VideoPlayerController.networkUrl(uri);
      });
      if (remoteReady) {
        return;
      }
    }

    if (mounted) {
      setState(() {
        _loadFailed = true;
      });
    }
  }

  Future<bool> _initializeController(
    FutureOr<VideoPlayerController?> Function() createController,
  ) async {
    VideoPlayerController? controller;
    try {
      controller = await createController();
      if (controller == null) {
        return false;
      }

      final initializeFuture = controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return false;
      }

      setState(() {
        _controller = controller;
        _initializeFuture = initializeFuture;
        _loadFailed = false;
      });

      await initializeFuture;
      await controller.setLooping(true);
      if (mounted) {
        setState(() {});
      }
      return true;
    } catch (error) {
      debugPrint('Inline video init failed: $error');
      await controller?.dispose();
      if (mounted && controller != null && identical(_controller, controller)) {
        setState(() {
          _controller = null;
          _initializeFuture = null;
        });
      }
      return false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: GlowUpColors.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('视频暂不可用'),
      );
    }

    final controller = _controller;
    final future = _initializeFuture;
    if (controller == null || future == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: GlowUpColors.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: GlowUpColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        final aspectRatio = controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  if (!controller.value.isPlaying)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: IconButton(
                          iconSize: 64,
                          color: Colors.white,
                          onPressed: _togglePlayback,
                          icon: const Icon(Icons.play_circle_filled),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _togglePlayback,
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
              label: Text(controller.value.isPlaying ? '暂停播放' : '播放视频'),
            ),
          ],
        );
      },
    );
  }
}

class _MusicTrackTile extends StatefulWidget {
  const _MusicTrackTile({required this.track});

  final Map<String, String> track;

  @override
  State<_MusicTrackTile> createState() => _MusicTrackTileState();
}

class _MusicTrackTileState extends State<_MusicTrackTile> {
  AudioPlayer? _player;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _loadFailed = false;

  String? get _audioUrl {
    final url = widget.track['audioUrl'];
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant _MusicTrackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_audioUrl != oldWidget.track['audioUrl']) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    await _disposePlayer();
    final url = _audioUrl;
    if (url == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = false;
        });
      }
      return;
    }
    final player = AudioPlayer();
    setState(() {
      _player = player;
      _isLoading = true;
      _loadFailed = false;
    });
    _durationSub = player.durationStream.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value ?? Duration.zero);
    });
    _positionSub = player.positionStream.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _stateSub = player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (state.processingState == ProcessingState.completed) {
        player.seek(Duration.zero);
      }
      setState(() => _isPlaying = playing);
    });
    try {
      await player.setUrl(url);
    } catch (error) {
      debugPrint('Inline audio load failed: $error');
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _disposePlayer() async {
    await _durationSub?.cancel();
    await _positionSub?.cancel();
    await _stateSub?.cancel();
    await _player?.dispose();
    _player = null;
    _duration = Duration.zero;
    _position = Duration.zero;
    _isPlaying = false;
  }

  @override
  void dispose() {
    unawaited(_disposePlayer());
    super.dispose();
  }

  void _togglePlay() {
    final player = _player;
    if (player == null) return;
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seek(double milliseconds) {
    final player = _player;
    if (player == null) return;
    player.seek(Duration(milliseconds: milliseconds.floor()));
  }

  @override
  Widget build(BuildContext context) {
    final audioUrl = _audioUrl;
    final title = widget.track['title'] ?? '课堂音乐';
    final durationMs = _duration.inMilliseconds.toDouble();
    final sliderMax = durationMs > 0 ? durationMs : 1.0;
    final sliderValue =
        _position.inMilliseconds.clamp(0, sliderMax.toInt()).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (audioUrl != null)
                IconButton(
                  tooltip: _isPlaying ? '暂停' : '播放',
                  onPressed: _isLoading || _loadFailed ? null : _togglePlay,
                  icon:
                      Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                ),
            ],
          ),
          if (audioUrl == null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                '暂无可播放的音频',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else if (_loadFailed)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                '音频加载失败，请稍后再试',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Slider(
                value: sliderValue,
                max: sliderMax,
                onChanged: _isLoading || _player == null ? null : _seek,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (audioUrl != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(audioUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('外部播放 / 下载'),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  if (duration.inMilliseconds <= 0) {
    return '00:00';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

class _StoryToolsCard extends StatelessWidget {
  const _StoryToolsCard({
    required this.onColorAnalysis,
    required this.onRhythmLab,
    required this.onCreativeSuite,
  });

  final VoidCallback onColorAnalysis;
  final VoidCallback onRhythmLab;
  final VoidCallback onCreativeSuite;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '小光课堂工具',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.colorize),
            title: const Text('色彩分析实验室'),
            subtitle: const Text('导入作品照片，获取 RGB / 亮度等数据，准备课堂点评'),
            onTap: onColorAnalysis,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.graphic_eq),
            title: const Text('节奏实验室'),
            subtitle: const Text('导入音频，查看音量与主频曲线，设计节奏练习'),
            onTap: onRhythmLab,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome_motion),
            title: const Text('小光创作工作室'),
            subtitle: const Text('需要自定义提示词时，进入这里生成插画、动画或音乐'),
            onTap: onCreativeSuite,
          ),
        ],
      ),
    );
  }
}

class _ColorPalettePreview extends StatelessWidget {
  const _ColorPalettePreview({required this.palette});

  final List<String> palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: palette.take(4).map((hexColor) {
        Color displayColor;
        try {
          displayColor =
              Color(int.parse('FF${hexColor.replaceAll('#', '')}', radix: 16));
        } catch (_) {
          displayColor = GlowUpColors.primary;
        }
        return Expanded(
          child: Container(
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: displayColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              hexColor.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StoryboardPreview extends StatelessWidget {
  const _StoryboardPreview({required this.segments});

  final List<Map<String, String>> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final segment = entry.value;
        final scene = segment['scene'];
        final narration = segment['narration'];
        final camera = segment['cameraHint'];
        final music = segment['musicCue'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('镜头 $index', style: textTheme.titleSmall),
              if (scene != null && scene.isNotEmpty)
                Text('场景：$scene', style: textTheme.bodySmall),
              if (narration != null && narration.isNotEmpty)
                Text('旁白：$narration', style: textTheme.bodySmall),
              if (camera != null && camera.isNotEmpty)
                Text('机位提示：$camera', style: textTheme.bodySmall),
              if (music != null && music.isNotEmpty)
                Text('配乐提示：$music', style: textTheme.bodySmall),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final targetWidth = (MediaQuery.of(context).size.width * devicePixelRatio).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheWidth: targetWidth > 0 ? targetWidth : null,
        placeholder: (context, url) => Container(
          height: 180,
          alignment: Alignment.center,
          color: GlowUpColors.mist,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, error, stackTrace) => Container(
          height: 180,
          alignment: Alignment.center,
          color: Colors.grey.shade200,
          child: const Text('图片加载失败'),
        ),
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _LessonPlanView extends StatelessWidget {
  const _LessonPlanView({
    required this.objectives,
    required this.materials,
    required this.stages,
    required this.questions,
    required this.differentiation,
    required this.summaryNotes,
    required this.extensions,
  });

  final List<String> objectives;
  final List<String> materials;
  final List<Map<String, dynamic>> stages;
  final List<String> questions;
  final List<String> differentiation;
  final List<String> summaryNotes;
  final List<String> extensions;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    void addSpacer() {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 12));
      }
    }

    if (objectives.isNotEmpty) {
      addSpacer();
      children.add(_BulletList(title: '教学目标', items: objectives));
    }
    if (materials.isNotEmpty) {
      addSpacer();
      children.add(_BulletList(title: '准备材料', items: materials));
    }
    if (stages.isNotEmpty) {
      addSpacer();
      children.add(Text(
        '课堂流程',
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ));
      children.add(const SizedBox(height: 8));
      children.addAll(
        stages.map((stage) => _LessonStageCard(stage: stage)),
      );
    }
    if (questions.isNotEmpty) {
      addSpacer();
      children.add(_BulletList(title: '互动提问', items: questions));
    }
    if (differentiation.isNotEmpty) {
      addSpacer();
      children.add(_BulletList(title: '差异化建议', items: differentiation));
    }
    if (summaryNotes.isNotEmpty) {
      addSpacer();
      children.add(_BulletList(title: '课堂总结', items: summaryNotes));
    }
    if (extensions.isNotEmpty) {
      addSpacer();
      children.add(_BulletList(title: '延伸任务', items: extensions));
    }
    if (children.isNotEmpty && children.last is SizedBox) {
      children.removeLast();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _LessonStageCard extends StatelessWidget {
  const _LessonStageCard({required this.stage});

  final Map<String, dynamic> stage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = stage['name'] as String? ?? '课堂环节';
    final duration = stage['duration'] as String?;
    final goal = stage['goal'] as String?;
    final activities =
        (stage['activities'] as List?)?.cast<String>() ?? const <String>[];
    final teacher =
        (stage['teacher'] as List?)?.cast<String>() ?? const <String>[];
    final students =
        (stage['students'] as List?)?.cast<String>() ?? const <String>[];
    final questions =
        (stage['questions'] as List?)?.cast<String>() ?? const <String>[];
    final materials =
        (stage['materials'] as List?)?.cast<String>() ?? const <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlowUpColors.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            duration != null ? '$name · $duration' : name,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (goal != null && goal.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('目标：$goal', style: textTheme.bodySmall),
          ],
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BulletList(title: '课堂活动', items: activities),
          ],
          if (teacher.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BulletList(title: '教师引导', items: teacher),
          ],
          if (students.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BulletList(title: '学生参与', items: students),
          ],
          if (questions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BulletList(title: '互动提问', items: questions),
          ],
          if (materials.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BulletList(title: '使用材料', items: materials),
          ],
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyStoryPlaceholder extends StatelessWidget {
  const _EmptyStoryPlaceholder({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '还没有课堂故事',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '小光建议以“主题—视觉—音乐—课堂反馈”串联课堂，每次创作都记录在故事里。',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('立即创建课堂故事'),
          ),
        ],
      ),
    );
  }
}

class TeacherClassroomPage extends StatelessWidget {
  const TeacherClassroomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassroomState>(
      builder: (context, classroomState, _) {
        final classes = classroomState.classrooms;
        return Scaffold(
          appBar: AppBar(
            title: const Text('班级管理'),
            actions: [
              IconButton(
                tooltip: '刷新',
                icon: const Icon(Icons.refresh),
                onPressed: () => classroomState.refreshAll(),
              ),
              IconButton(
                tooltip: '新建班级',
                icon: const Icon(Icons.add),
                onPressed: () =>
                    _showCreateClassDialog(context, classroomState),
              ),
            ],
          ),
          body: classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('还没有班级，先创建一个吧！'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            _showCreateClassDialog(context, classroomState),
                        child: const Text('创建班级'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final room = classes[index];
                    return _ClassroomCard(
                      classroom: room,
                      onDelete: () => classroomState.deleteClassroom(room.id),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _showCreateClassDialog(
    BuildContext context,
    ClassroomState classroomState,
  ) async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建班级'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '例如：三年级二班'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('请输入班级名称')));
                return;
              }
              final success =
                  await classroomState.createClassroom(controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context, success);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('班级创建成功')),
      );
    }
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.classroom,
    required this.onDelete,
  });

  final ClassroomInfo classroom;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  classroom.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '复制班级编码',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: classroom.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('班级编码 ${classroom.code} 已复制')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  tooltip: '删除班级',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('班级编码：${classroom.code}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classroom.students.isEmpty
                  ? [
                      Chip(
                        label: const Text('暂时没有学生加入'),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ]
                  : classroom.students
                      .map(
                        (student) => Chip(
                          label: Text(student.username),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherShowcaseHubPage extends StatefulWidget {
  const TeacherShowcaseHubPage({super.key});

  @override
  State<TeacherShowcaseHubPage> createState() => _TeacherShowcaseHubPageState();
}

class _TeacherShowcaseHubPageState extends State<TeacherShowcaseHubPage> {
  String _scope = 'classes';
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final showcaseState = context.read<ShowcaseState>();
      showcaseState.loadFeed(scope: _scope, classId: _selectedClassId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ShowcaseState, ClassroomState, AuthState>(
      builder: (context, showcaseState, classroomState, auth, _) {
        final items = showcaseState.items;
        final classes = classroomState.classrooms;
        final isLoading = showcaseState.isLoading;
        final topThree = [...items]..sort((a, b) => b.likes.compareTo(a.likes));

        return Scaffold(
          appBar: AppBar(
            title: const Text('作品橱窗'),
            actions: [
              IconButton(
                tooltip: '刷新',
                icon: const Icon(Icons.refresh),
                onPressed: () => showcaseState.loadFeed(
                    scope: _scope, classId: _selectedClassId),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: auth.isAuthenticated
                ? () =>
                    _showUploadDialog(context, showcaseState, classroomState)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('创建展示'),
            backgroundColor: GlowUpColors.sunset,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'classes',
                          label: Text('我的班级'),
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
                            scope: _scope, classId: _selectedClassId);
                      },
                    ),
                    if (_scope == 'classes' && classes.isNotEmpty)
                      DropdownButton<String>(
                        value: _selectedClassId,
                        hint: const Text('选择班级'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('全部班级'),
                          ),
                          ...classes.map(
                            (room) => DropdownMenuItem(
                              value: room.id,
                              child: Text(room.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedClassId = value);
                          showcaseState.loadFeed(
                              scope: _scope, classId: _selectedClassId);
                        },
                      ),
                  ],
                ),
              ),
              if (topThree.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今日点赞榜 Top 3',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final item = topThree[index];
                            return _TopShowcaseCard(
                              item: item,
                              rank: index + 1,
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: topThree.length.clamp(0, 3),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? const Center(child: Text('暂时没有作品，鼓励师生上传吧！'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final canDelete = _canManageShowcaseItem(
                                auth,
                                classes,
                                item,
                              );
                              return _ShowcaseListTile(
                                item: item,
                                onLike: auth.isAuthenticated
                                    ? () => showcaseState.toggleLike(item.id)
                                    : null,
                                onDelete: canDelete
                                    ? () => _confirmDeleteContent(
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

  Future<void> _showUploadDialog(
    BuildContext outerContext,
    ShowcaseState showcaseState,
    ClassroomState classroomState,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String kind = 'image';
    String visibility = 'classes';
    final selectedClasses = <String>{
      if (classroomState.classrooms.isNotEmpty)
        classroomState.classrooms.first.id,
    };
    PlatformFile? selectedFile;
    ResolvedPlatformFile? resolvedFile;
    bool isSubmitting = false;
    String? fileError;

    await showDialog<void>(
      context: outerContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('创建作品展示'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: '作品标题'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '请输入标题'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '作品类型',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButton<String>(
                          value: kind,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'image',
                              child: Text('妙手画坊'),
                            ),
                            DropdownMenuItem(
                              value: 'video',
                              child: Text('光影剧场'),
                            ),
                            DropdownMenuItem(
                              value: 'music',
                              child: Text('旋律工坊'),
                            ),
                            DropdownMenuItem(
                              value: 'lesson',
                              child: Text('教案'),
                            ),
                          ],
                          onChanged: (value) => kind = value ?? 'image',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: '作品说明',
                          hintText: '可选，向孩子们介绍这件作品',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '上传素材（可选）',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await FilePicker.platform.pickFiles(
                            withData: true,
                            type: FileType.media,
                          );
                          if (picked == null) return;
                          final platformFile = picked.files.single;
                          final resolved =
                              await resolvePlatformFile(platformFile);
                          if (resolved == null) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                const SnackBar(content: Text('无法读取所选文件')),
                              );
                            }
                            return;
                          }
                          resolvedFile = resolved;
                          selectedFile = platformFile;
                          fileError = null;
                          setState(() {});
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(selectedFile == null ? '选择文件' : '更换文件'),
                      ),
                      if (selectedFile != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedFile!.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: '移除文件',
                              onPressed: () {
                                resolvedFile = null;
                                selectedFile = null;
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ],
                      if (fileError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            fileError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text('可见范围',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '可见范围',
                        ),
                        child: DropdownButton<String>(
                          value: visibility,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'classes',
                              child: Text('我的班级'),
                            ),
                            DropdownMenuItem(
                              value: 'global',
                              child: Text('全平台'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => visibility = value);
                          },
                        ),
                      ),
                      if (visibility == 'classes')
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: classroomState.classrooms.map((room) {
                            final selected = selectedClasses.contains(room.id);
                            return FilterChip(
                              label: Text(room.name),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  if (selected) {
                                    selectedClasses.remove(room.id);
                                  } else {
                                    selectedClasses.add(room.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (visibility == 'classes' &&
                              selectedClasses.isEmpty) {
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              const SnackBar(content: Text('请选择班级')),
                            );
                            return;
                          }
                          if (selectedFile != null && resolvedFile == null) {
                            fileError = '无法读取所选文件，请重新选择';
                            setState(() {});
                            return;
                          }
                          setState(() {
                            isSubmitting = true;
                            fileError = null;
                          });
                          try {
                            final success = await showcaseState.uploadContent(
                              title: titleController.text.trim(),
                              kind: kind,
                              description: descriptionController.text.trim(),
                              visibility: visibility,
                              classroomIds: selectedClasses.toList(),
                              fileBytes: resolvedFile?.bytes,
                              fileName: resolvedFile?.name,
                              fileMimeType: resolvedFile?.mimeType,
                              preview: resolvedFile == null
                                  ? {
                                      'type': 'text_only',
                                      'generatedBy': 'xiaoguang',
                                    }
                                  : null,
                              metadata: {
                                'note': '教师上传作品',
                                if (selectedFile != null)
                                  'originalFileName': selectedFile!.name,
                              },
                              teacherGenerated: true,
                              aiGenerated: kind != 'lesson',
                            );
                            if (success && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  const SnackBar(content: Text('作品已发布')),
                                );
                                showcaseState.loadFeed(
                                  scope: _scope,
                                  classId: _selectedClassId,
                                );
                              }
                              resolvedFile = null;
                              selectedFile = null;
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setState(() => isSubmitting = false);
                            } else {
                              isSubmitting = false;
                            }
                          }
                        },
                  child: const Text('发布'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  bool _canManageShowcaseItem(
    AuthState auth,
    List<ClassroomInfo> classrooms,
    ShowcaseItem item,
  ) {
    if (!(auth.user?.isTeacher ?? false)) return false;
    final userId = auth.user?.id ?? '';
    if (userId.isNotEmpty && item.ownerId == userId) {
      return true;
    }
    final managedIds = classrooms.map((room) => room.id).toSet();
    if (managedIds.isEmpty) return false;
    return item.classroomIds.any(managedIds.contains);
  }

  Future<void> _confirmDeleteContent(
    BuildContext context,
    ShowcaseState showcaseState,
    ShowcaseItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除橱窗作品'),
        content: Text('确定要删除作品《${item.title}》吗？此操作无法撤销。'),
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
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('作品已删除')),
      );
    } else {
      final error = showcaseState.error ?? '删除失败，请稍后再试';
      messenger.showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

class _TopShowcaseCard extends StatelessWidget {
  const _TopShowcaseCard({required this.item, required this.rank});

  final ShowcaseItem item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = [
      GlowUpColors.sunset,
      GlowUpColors.bloom,
      GlowUpColors.lavender
    ];
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[(rank - 1) % colors.length].withValues(alpha: 0.2),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors[(rank - 1) % colors.length],
            child: Text(
              '$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              '${item.ownerName} · 点赞 ${item.likes}',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseListTile extends StatelessWidget {
  const _ShowcaseListTile({required this.item, this.onLike, this.onDelete});

  final ShowcaseItem item;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final previewImage = item.previewImageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: previewImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: previewImage,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GlowUpColors.mist,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => _fallbackIcon(),
                ),
              )
            : _fallbackIcon(),
        title: Text(item.title),
        subtitle: Text(
          '${item.ownerName} · 点赞 ${item.likes} · 评论 ${item.comments}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.isLiked ? Icons.favorite : Icons.favorite_border,
                color: item.isLiked ? GlowUpColors.sunset : Colors.grey,
              ),
              onPressed: onLike,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                tooltip: '删除作品',
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShowcaseDetailPage(item: item),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: GlowUpColors.primary.withValues(alpha: 0.1),
      child: Icon(
        _iconForKind(item.kind),
        color: GlowUpColors.primary,
      ),
    );
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'image':
        return Icons.brush;
      case 'video':
        return Icons.movie_filter;
      case 'music':
        return Icons.music_note;
      case 'lesson':
        return Icons.menu_book;
      default:
        return Icons.auto_awesome;
    }
  }
}

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        final user = auth.user;
        final profile = auth.profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('我的'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlowCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            GlowUpColors.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? '老师',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.bio ?? '课堂的故事讲述者，让孩子们用艺术拥抱世界。',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '偏好设置',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _PreferenceRow(
                        label: '界面语言',
                        value: profile?.preferences.language ?? '简体中文',
                      ),
                      _PreferenceRow(
                        label: '主题',
                        value:
                            profile?.preferences.theme == 'dark' ? '深色' : '浅色',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
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

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}

const List<String> _studioSteps = [
  'lesson_plan',
  'background_image',
  'video',
  'music',
];

const Map<String, String> _stepLabels = {
  'lesson_plan': '故事教案',
  'background_image': 'AI 教学背景图',
  'video': '开场动画脚本',
  'music': '课堂音乐脚本',
};
