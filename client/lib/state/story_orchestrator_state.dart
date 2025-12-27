import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/classroom.dart';
import '../models/lesson_plan.dart';
import '../models/story_asset.dart';
import '../models/teacher_story.dart';
import '../services/ai_analyzers.dart';
import '../services/ai_case_analyzer.dart';
import '../services/ai_lesson_template_generator.dart';
import '../services/ai_media_generator.dart';
import '../services/ai_story_weaver.dart';
import '../services/app_api_service.dart';
import '../services/story_cache_service.dart';
import 'ai_generation_state.dart';
import 'auth_state.dart';
import 'classroom_state.dart';

class StoryOrchestratorState extends ChangeNotifier {
  StoryOrchestratorState({
    required AuthState authState,
    required ClassroomState classroomState,
    AiLessonPlanner? lessonPlanner,
    AiStoryWeaver? storyWeaver,
    AiMediaGenerator? mediaGenerator,
    VideoGenerationState? videoState,
    MusicGenerationState? musicState,
    StoryCacheService? cacheService,
  })  : _auth = authState,
        _classroomState = classroomState,
        _lessonPlanner = lessonPlanner ?? AiLessonPlanner(),
        _storyWeaver = storyWeaver ?? AiStoryWeaver(),
        _mediaGenerator = mediaGenerator ?? AiMediaGenerator(),
        _lessonTemplateGenerator = AiLessonTemplateGenerator(),
        _caseAnalyzer = AiCaseAnalyzer(),
        _videoState = videoState,
        _musicState = musicState,
        _cache = cacheService ?? StoryCacheService();

  AuthState _auth;
  ClassroomState _classroomState;
  final AiLessonPlanner _lessonPlanner;
  final AiStoryWeaver _storyWeaver;
  final AiMediaGenerator _mediaGenerator;
  final AiLessonTemplateGenerator _lessonTemplateGenerator;
  final AiCaseAnalyzer _caseAnalyzer;
  VideoGenerationState? _videoState;
  MusicGenerationState? _musicState;
  final StoryCacheService _cache;
  Timer? _cacheWriteTimer;

  TeacherStory? _activeStory;
  Map<String, StoryAsset> _assets = <String, StoryAsset>{};
  LessonPlan? _currentLessonPlan;
  bool _isGeneratingLesson = false;
  bool _isBusy = false;
  String? _error;
  String? _sharedContentId;

  TeacherStory? get activeStory => _activeStory;
  Map<String, StoryAsset> get assets => _assets;
  LessonPlan? get currentLessonPlan => _currentLessonPlan;
  bool get isGeneratingLesson => _isGeneratingLesson;
  bool get isBusy => _isBusy;
  String? get error => _error;
  List<ClassroomInfo> get availableClassrooms => _classroomState.classrooms;
  bool get isShared => _activeStory?.status == 'public';

  void attachMediaStates({
    VideoGenerationState? videoState,
    MusicGenerationState? musicState,
  }) {
    if (videoState != null) {
      _videoState = videoState;
    }
    _musicState = musicState ?? _musicState;
  }

  void updateDependencies({
    required AuthState auth,
    required ClassroomState classroomState,
  }) {
    var changed = false;
    if (!identical(_auth, auth)) {
      _auth = auth;
      changed = true;
    }
    if (!identical(_classroomState, classroomState)) {
      _classroomState = classroomState;
      changed = true;
    }
    if (!(_auth.user?.isTeacher ?? false)) {
      reset();
      return;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void reset() {
    if (_activeStory == null && _assets.isEmpty && !_isBusy && _error == null) {
      return;
    }
    _cacheWriteTimer?.cancel();
    _activeStory = null;
    _assets = <String, StoryAsset>{};
    _isBusy = false;
    _error = null;
    _sharedContentId = null;
    notifyListeners();
  }

  Future<TeacherStory?> createStory({
    required String title,
    required List<String> classroomIds,
    String? theme,
  }) async {
    if (_auth.token == null) {
      _error = '请先登录教师账号';
      notifyListeners();
      return null;
    }
    _setBusy(true);
    try {
      final story = await _classroomState.createStory(
        title: title,
        classroomIds: classroomIds,
        theme: theme,
      );
      _activeStory = story;
      if (story != null) {
        await _seedAssets(story);
      }
      _error = null;
      _setBusy(false);
      return story;
    } catch (error) {
      _error = error.toString();
      _setBusy(false);
      return null;
    }
  }

  Future<void> loadStory(TeacherStory story) async {
    _cacheWriteTimer?.cancel();
    _activeStory = story;
    _sharedContentId = story.metadata['sharedContentId'] as String?;

    final cachedPayload = await _cache.load(story.id);
    Map<String, StoryAsset> cachedSnapshot = {};
    if (cachedPayload != null) {
      final cachedStory = cachedPayload['story'];
      if (cachedStory is Map<String, dynamic>) {
        try {
          final restored = TeacherStory.fromJson(cachedStory);
          _activeStory = restored;
          _sharedContentId =
              restored.metadata['sharedContentId'] as String?;
        } catch (error) {
          debugPrint('Failed to parse cached story for ${story.id}: $error');
        }
      }
      final cachedAssets = cachedPayload['assets'];
      if (cachedAssets is Map<String, dynamic> &&
          cachedAssets.isNotEmpty) {
        try {
          _assets = cachedAssets.toStoryAssets();
          notifyListeners();
        } catch (error) {
          debugPrint('Failed to parse cached assets for ${story.id}: $error');
          await _seedAssets(_activeStory ?? story);
        }
      } else {
        await _seedAssets(_activeStory ?? story);
      }
      cachedSnapshot = Map<String, StoryAsset>.from(_assets);
    } else {
      await _seedAssets(story);
      cachedSnapshot = Map<String, StoryAsset>.from(_assets);
    }

    if (_auth.token == null) {
      return;
    }

    unawaited(_refreshStoryFromServer((_activeStory ?? story).id, cachedSnapshot));
  }

  Future<bool> deleteStory(String storyId) async {
    if (_auth.token == null || !(_auth.user?.isTeacher ?? false)) {
      _error = '请先登录教师账号';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      final success = await _classroomState.deleteStory(storyId);
      if (!success) {
        _error = _classroomState.error ?? '删除失败，请稍后再试';
        _setBusy(false);
        return false;
      }
      await _cache.clear(storyId);
      _error = null;
      final wasActive = _activeStory?.id == storyId;
      if (wasActive) {
        _activeStory = null;
        _assets = <String, StoryAsset>{};
        _sharedContentId = null;
      }
      _setBusy(false);
      if (wasActive && _classroomState.stories.isNotEmpty) {
        final nextStory = _classroomState.stories.first;
        _activeStory = nextStory;
        await _seedAssets(nextStory);
      } else {
        notifyListeners();
      }
      return true;
    } catch (error) {
      _error = error.toString();
      _setBusy(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> generateLessonPlan({
    required String subject,
    required String grade,
    required List<String> focus,
    required String description,
  }) async {
    await _guardedGenerate('lesson_plan', () async {
      final planText = await _lessonPlanner.generateLessonPlan(
        subject: subject,
        grade: grade,
        options: focus,
        description: description,
      );
      final parsed = _parseLessonPlanJson(planText);
      Map<String, dynamic>? normalized;
      if (parsed != null) {
        final candidate = _normalizeLessonPlan(parsed);
        if (candidate.length > 1) {
          normalized = candidate;
        }
      }
      final summaryText = normalized != null
          ? _summarizeLessonPlan(normalized)
          : planText.trim();
      final preview = normalized ??
          {
            'type': 'text',
            'title': '45分钟教案',
            'body': planText,
          };
      _updateAsset(
        'lesson_plan',
        summary: summaryText.isEmpty ? '教案内容已生成，可查看详细步骤。' : summaryText,
        preview: preview,
        metadata: {
          'subject': subject,
          'grade': grade,
          'focus': focus,
          'description': description,
          'rawPlan': planText,
          if (parsed != null) 'structuredPlan': parsed,
        },
      );
    });
  }

  Future<void> generateBackgroundImage({required String theme}) async {
    await _guardedGenerate('background_image', () async {
      final lessonSummary = _assets['lesson_plan']?.summary;
      final result = await _mediaGenerator.generateBackgroundImage(
        theme: theme,
        styleHint: (lessonSummary != null && lessonSummary.trim().isNotEmpty)
            ? lessonSummary
            : theme,
      );
      _updateAsset(
        'background_image',
        summary: '小光建议的课堂背景图已经准备好，可直接投影或打印使用。',
        preview: {
          'type': 'image',
          'imageUrl': result.imageUrl,
          'prompt': result.prompt,
        },
        metadata: {
          'imageUrl': result.imageUrl,
          'prompt': result.prompt,
          'raw': result.responseJson,
        },
      );
    });
  }

  Future<void> generateVideoStoryboard({required String theme}) async {
    await _guardedGenerate('video', () async {
      final result = await _storyWeaver.generateVideoStoryboard(theme: theme);
      final preview = Map<String, dynamic>.from(result.preview);
      final metadata = Map<String, dynamic>.from(result.metadata);
      _updateAsset(
        'video',
        summary: '小光正在整理课堂动画脚本与镜头分镜…',
        preview: preview,
        metadata: metadata,
      );

      final script = _stringValue(metadata['script']) ??
          _stringValue(preview['script']) ??
          result.summary;
      final videoState = _videoState;
      if (videoState == null || script.trim().isEmpty) {
        _updateAsset(
          'video',
          summary: result.summary,
          preview: preview,
          metadata: metadata,
        );
        return;
      }

      videoState.prefillFromStory(script.trim());
      const orientation = 'landscape';
      const size = 'small';
      final videoUrl = await videoState.generateAndWait(
        promptText: script.trim(),
        orientationValue: orientation,
        sizeValue: size,
        timeout: const Duration(minutes: 6),
      );
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('视频生成失败，请稍后再试');
      }

      preview
        ..['videoUrl'] = videoUrl
        ..['fileUrl'] = videoUrl
        ..removeWhere((key, value) => value == null)
        ..['script'] = script.trim();
      metadata['videoUrl'] = videoUrl;

      final finalSummary = [
        result.summary,
        '小光生成了课堂开场动画，可直接播放或下载。',
      ].where((line) => line.trim().isNotEmpty).join('\n');
      _updateAsset(
        'video',
        summary: finalSummary,
        preview: preview,
        metadata: metadata,
      );

      unawaited(_persistAssetsToCache());
    });
  }

  Future<void> generateMusicCue({required String theme}) async {
    await _guardedGenerate('music', () async {
      final result = await _storyWeaver.generateMusicCue(theme: theme);
      final preview = Map<String, dynamic>.from(result.preview);
      final metadata = Map<String, dynamic>.from(result.metadata);

      _updateAsset(
        'music',
        summary: '小光正在整理课堂音乐结构与节奏提示…',
        preview: preview,
        metadata: metadata,
      );

      final musicState = _musicState;
      if (musicState == null) {
        _updateAsset(
          'music',
          summary: result.summary,
          preview: preview,
          metadata: metadata,
        );
        return;
      }

      final structureDescription = _structureDescription(metadata['structure']);
      final descriptionBuffer = StringBuffer()..writeln(result.summary);
      if (structureDescription.isNotEmpty) {
        descriptionBuffer.writeln(structureDescription);
      }
      final structureLines = _stringList(metadata['structure']);
      musicState.prefillFromStory(
        title: _activeStory?.title ?? theme,
        description: result.summary,
        lyric: structureLines.join('\n'),
      );
      final tracks = await musicState.generateAndWait(
        promptText: _activeStory?.title ?? theme,
        descriptionText: descriptionBuffer.toString(),
        styleValue: musicState.style,
        instrumentalValue: musicState.instrumental,
        timeout: const Duration(minutes: 6),
      );
      if (tracks.isEmpty) {
        throw Exception('音乐生成失败，请稍后再试');
      }
      final playable = tracks.firstWhere(
        (track) => track.audioUrl != null && track.audioUrl!.isNotEmpty,
        orElse: () => tracks.first,
      );
      if (playable.audioUrl == null || playable.audioUrl!.isEmpty) {
        throw Exception('音乐生成失败，请稍后再试');
      }

      final orderedTracks = [
        playable,
        ...tracks.where((track) => !identical(track, playable)),
      ];

      final trackMaps = orderedTracks
          .map((track) => {
                'id': track.id,
                'title': track.title,
                if (track.audioUrl != null) 'audioUrl': track.audioUrl,
                if (track.imageUrl != null) 'coverUrl': track.imageUrl,
              })
          .toList();

      preview
        ..['tracks'] = trackMaps
        ..['primaryTrack'] = trackMaps.first
        ..['audioUrl'] = trackMaps.first['audioUrl'];
      metadata['tracks'] = trackMaps;

      final finalSummary = [
        result.summary,
        '小光为课堂准备了背景音乐，可直接试听或下载使用。',
      ].where((line) => line.trim().isNotEmpty).join('\n');
      _updateAsset(
        'music',
        summary: finalSummary,
        preview: preview,
        metadata: metadata,
      );
    });
  }

  Future<void> uploadAsset({
    required String kind,
    String visibility = 'classes',
    List<String>? classroomIds,
  }) async {
    if (_auth.token == null) {
      _error = '请先登录教师账号';
      notifyListeners();
      return;
    }
    final asset = _assets[kind];
    if (asset == null) {
      _error = '未找到要上传的课堂素材';
      notifyListeners();
      return;
    }
    _setAssetStatus(kind, StoryAssetStatus.uploading, error: null);
    try {
      final targetClassrooms = visibility == 'global'
          ? const <String>[]
          : (classroomIds != null && classroomIds.isNotEmpty
              ? classroomIds
              : _defaultClassroomIds());

      final response = await AppApiService.uploadContent(
        token: _auth.token!,
        title: _buildTitleForKind(kind),
        kind: kind,
        visibility: visibility,
        classroomIds: targetClassrooms,
        description: asset.summary ?? '',
        preview: asset.preview,
        metadata: {
          ...asset.metadata,
          'generatedBy': 'xiaoguang',
        },
        teacherGenerated: true,
        aiGenerated: true,
        storyId: _activeStory?.id,
      );

      final content =
          response['content'] as Map<String, dynamic>? ?? <String, dynamic>{};
      _updateAsset(
        kind,
        metadata: {
          ...asset.metadata,
          'contentId': content['id'],
          'uploadedAt': DateTime.now().toIso8601String(),
        },
        status: StoryAssetStatus.uploaded,
        error: null,
      );
      await _persistStoryStep(
          kind: kind, asset: _assets[kind]!, contentId: content['id']);
      _error = null;
    } catch (error) {
      _error = error.toString();
      _setAssetStatus(kind, StoryAssetStatus.failed, error: _error);
    }
  }

  Future<void> setStoryVisibility(bool share) async {
    final story = _activeStory;
    if (story == null) return;
    final currentMetadata = Map<String, dynamic>.from(story.metadata);
    if (!share) {
      currentMetadata.remove('sharedContentId');
      currentMetadata.remove('sharedContentUpdatedAt');
      currentMetadata.remove('sharedContentOwnerId');
    }
    final updated = await _classroomState.updateStory(
      storyId: story.id,
      status: share ? 'public' : 'draft',
      metadata: currentMetadata,
    );
    if (updated != null) {
      _activeStory = updated;
      _sharedContentId =
          share ? updated.metadata['sharedContentId'] as String? : null;
      notifyListeners();
      if (share) {
        await _publishStoryBundle();
      }
    }
  }

  Future<void> _guardedGenerate(
    String kind,
    Future<void> Function() task,
  ) async {
    if (!_assets.containsKey(kind)) {
      _assets = {
        ..._assets,
        kind: StoryAsset(kind: kind, label: _labelFor(kind)),
      };
    }
    _setAssetStatus(kind, StoryAssetStatus.generating, error: null);
    _error = null;
    try {
      await task();
      _setAssetStatus(kind, StoryAssetStatus.ready, error: null);
      await _syncAssetSnapshot(kind);
    } catch (error) {
      _setAssetStatus(kind, StoryAssetStatus.failed, error: error.toString());
      _error = error.toString();
    }
  }

  Future<void> _persistStoryStep({
    required String kind,
    required StoryAsset asset,
    String? contentId,
  }) async {
    final story = _activeStory;
    if (story == null) {
      return;
    }
    final updatedSteps = <StoryStepModel>[];
    for (final step in story.steps) {
      if (step.kind == kind) {
        final previewPayload = _sanitizeRemotePayload(asset.preview);
        final metadataPayload = _sanitizeRemotePayload(asset.metadata)
          ..removeWhere((key, value) => value == null);
        if (contentId != null) {
          metadataPayload['contentId'] = contentId;
        }
        final payload = <String, dynamic>{
          'preview': previewPayload,
          'metadata': metadataPayload,
        };
        updatedSteps.add(
          step.copyWith(
            summary: asset.summary,
            completed: asset.status == StoryAssetStatus.uploaded,
            payload: payload,
          ),
        );
      } else {
        updatedSteps.add(step);
      }
    }
    final result = await _classroomState.updateStory(
      storyId: story.id,
      steps: updatedSteps,
    );
    if (result != null) {
      _activeStory = result;
    } else {
      _activeStory = story.copyWith(steps: updatedSteps);
    }
    notifyListeners();
  }

  Future<void> _seedAssets(TeacherStory story) async {
    _cacheWriteTimer?.cancel();
    final seeded = _buildAssetsFromStory(story);
    _assets = seeded;
    notifyListeners();
    await _persistAssetsToCache(storyOverride: story);
  }

  Map<String, StoryAsset> _buildAssetsFromStory(TeacherStory story) {
    final seeded = <String, StoryAsset>{};
    for (final blueprint in kStoryAssetBlueprints) {
      final kind = blueprint['kind']!;
      final label = blueprint['label']!;
      StoryStepModel? matched;
      for (final step in story.steps) {
        if (step.kind == kind) {
          matched = step;
          break;
        }
      }
      final payload =
          Map<String, dynamic>.from(matched?.payload ?? <String, dynamic>{});
      final preview = payload['preview'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              payload['preview'] as Map<String, dynamic>)
          : const <String, dynamic>{};
      final metadata = Map<String, dynamic>.from(payload)..remove('preview');
      seeded[kind] = StoryAsset(
        kind: kind,
        label: label,
        summary: matched?.summary,
        preview: preview,
        metadata: metadata,
        status: matched?.completed == true
            ? StoryAssetStatus.uploaded
            : StoryAssetStatus.idle,
      );
    }
    return seeded;
  }

  Map<String, dynamic> _sanitizeRemotePayload(Map<String, dynamic> source) {
    final sanitized = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) return;
      final keyString = key.toString();
      if (keyString.startsWith('local')) return;
      if (value is Map<String, dynamic>) {
        sanitized[keyString] = _sanitizeRemotePayload(value);
      } else if (value is List) {
        sanitized[keyString] = value
            .map((item) => item is Map<String, dynamic>
                ? _sanitizeRemotePayload(item)
                : item)
            .toList(growable: false);
      } else {
        sanitized[keyString] = value;
      }
    });
    return sanitized;
  }

  void _restoreLocalAssetData(Map<String, StoryAsset> cachedAssets) {
    for (final entry in cachedAssets.entries) {
      final previewLocals = <String, dynamic>{};
      entry.value.preview.forEach((key, value) {
        if (key.toString().startsWith('local') && value != null) {
          previewLocals[key] = value;
        }
      });
      final metadataLocals = <String, dynamic>{};
      entry.value.metadata.forEach((key, value) {
        if (key.toString().startsWith('local') && value != null) {
          metadataLocals[key] = value;
        }
      });
      if (previewLocals.isEmpty && metadataLocals.isEmpty) {
        continue;
      }
      _updateAsset(entry.key,
          preview: previewLocals, metadata: metadataLocals);
    }
  }

  void _scheduleCacheSave() {
    final storyId = _activeStory?.id;
    if (storyId == null) return;
    _cacheWriteTimer?.cancel();
    _cacheWriteTimer = Timer(const Duration(milliseconds: 300), () {
      final story = _activeStory;
      if (story == null) return;
      unawaited(_persistAssetsToCache());
    });
  }

  Future<void> _persistAssetsToCache({TeacherStory? storyOverride}) async {
    final story = storyOverride ?? _activeStory;
    if (story == null) return;
    try {
      await _cache.save(story.id, {
        'story': story.toJson(),
        'assets': _assets.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('Story cache save failed for ${story.id}: $error');
    }
  }

  Future<TeacherStory?> _fetchStoryFromServer(String storyId) async {
    if (_auth.token == null) return null;
    try {
      final response = await AppApiService.fetchStory(
        token: _auth.token!,
        storyId: storyId,
      );
      final storyJson = response['story'] as Map<String, dynamic>?;
      if (storyJson == null) return null;
      return TeacherStory.fromJson(storyJson);
    } catch (error) {
      debugPrint('Failed to fetch story $storyId: $error');
      return null;
    }
  }

  Future<void> _syncAssetSnapshot(String kind) async {
    final story = _activeStory;
    if (story == null) return;
    final asset = _assets[kind];
    if (asset == null) return;
    try {
      await _persistStoryStep(kind: kind, asset: asset);
      await _persistAssetsToCache();
    } catch (error) {
      debugPrint('Failed to sync story asset $kind: $error');
      rethrow;
    }
  }

  Future<void> _refreshStoryFromServer(
    String storyId,
    Map<String, StoryAsset> cachedSnapshot,
  ) async {
    try {
      final remote = await _fetchStoryFromServer(storyId);
      if (remote == null || _activeStory?.id != storyId) {
        return;
      }
      _activeStory = remote;
      _sharedContentId = remote.metadata['sharedContentId'] as String?;
      await _seedAssets(remote);
      if (cachedSnapshot.isNotEmpty) {
        _restoreLocalAssetData(cachedSnapshot);
      }
    } catch (error) {
      debugPrint('Failed to refresh story $storyId: $error');
    }
  }

  @override
  void dispose() {
    _cacheWriteTimer?.cancel();
    super.dispose();
  }

  Future<void> _publishStoryBundle() async {
    if (_auth.token == null || _activeStory == null) return;
    final story = _activeStory!;
    final existingSharedId = story.metadata['sharedContentId'] as String?;
    if (existingSharedId != null && existingSharedId.isNotEmpty) {
      _sharedContentId = existingSharedId;
      return;
    }
    if (_sharedContentId != null) return;

    final summaryLines = <String>[];
    for (final asset in _assets.values) {
      final line = asset.summary;
      if (line != null && line.trim().isNotEmpty) {
        summaryLines.add('${asset.label}：${line.trim()}');
      }
    }
    final description = summaryLines.isEmpty
        ? '课堂故事包含 ${_assets.length} 个 AI 素材。'
        : summaryLines.join('\n');

    final storyJson = story.toJson()..['teacherId'] = _auth.user?.id ?? '';
    final assetsJson = _assets.map(
      (key, asset) => MapEntry(key, asset.toJson()),
    );

    String? coverImage;
    for (final asset in _assets.values) {
      final imageCandidates = [
        asset.preview['imageUrl'],
        asset.preview['thumbnailUrl'],
        asset.preview['fileUrl'],
      ];
      for (final candidate in imageCandidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          coverImage = candidate.trim();
          break;
        }
      }
      if (coverImage != null) break;
    }

    final preview = {
      'type': 'story_bundle',
      'storyId': story.id,
      'title': story.title,
      'theme': story.theme,
      'steps': summaryLines,
      if (coverImage != null) 'imageUrl': coverImage,
    };

    final response = await AppApiService.uploadContent(
      token: _auth.token!,
      title: story.title,
      kind: 'lesson',
      visibility: 'global',
      classroomIds: const [],
      description: description,
      preview: preview,
      metadata: {
        'storyId': story.id,
        'teacher': _auth.user?.username,
        'classroomIds': story.classroomIds,
        'summary': summaryLines,
        'storyBundle': storyJson,
        'assets': assetsJson,
        'bundleVersion': 1,
        'sharedAt': DateTime.now().toIso8601String(),
      },
      teacherGenerated: true,
      aiGenerated: false,
    );
    final content = response['content'] as Map<String, dynamic>?;
    if (content != null) {
      _sharedContentId = content['id']?.toString();
      final updatedMetadata = {
        ...story.metadata,
        if (_sharedContentId != null) 'sharedContentId': _sharedContentId,
        'sharedContentUpdatedAt': DateTime.now().toIso8601String(),
        if (_auth.user != null) 'sharedContentOwnerId': _auth.user!.id,
      };
      final updatedStory = await _classroomState.updateStory(
        storyId: story.id,
        metadata: updatedMetadata,
      );
      if (updatedStory != null) {
        _activeStory = updatedStory;
      } else {
        _activeStory = story.copyWith(metadata: updatedMetadata);
      }
      notifyListeners();
    }
  }

  void _updateAsset(
    String kind, {
    String? summary,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
    StoryAssetStatus? status,
    String? error,
  }) {
    final existing =
        _assets[kind] ?? StoryAsset(kind: kind, label: _labelFor(kind));
    final mergedPreview =
        preview != null ? {...existing.preview, ...preview} : existing.preview;
    final mergedMetadata = metadata != null
        ? {...existing.metadata, ...metadata}
        : existing.metadata;
    final updated = existing.copyWith(
      summary: summary ?? existing.summary,
      preview: mergedPreview,
      metadata: mergedMetadata,
      status: status ?? existing.status,
      error: error,
    );
    _assets = {..._assets, kind: updated};
    notifyListeners();
    _scheduleCacheSave();
  }

  void _setAssetStatus(String kind, StoryAssetStatus status, {String? error}) {
    final existing = _assets[kind];
    if (existing == null) {
      return;
    }
    _updateAsset(kind, status: status, error: error);
  }

  void _setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    _isBusy = value;
    notifyListeners();
  }

  List<String> _defaultClassroomIds() {
    if (_activeStory != null && _activeStory!.classroomIds.isNotEmpty) {
      return _activeStory!.classroomIds;
    }
    return availableClassrooms.map((room) => room.id).toList();
  }

  String _buildTitleForKind(String kind) {
    final storyTitle = _activeStory?.title ?? '课堂故事';
    switch (kind) {
      case 'lesson_plan':
        return '$storyTitle · 教案';
      case 'background_image':
        return '$storyTitle · 背景图';
      case 'video':
        return '$storyTitle · 开场动画';
      case 'music':
        return '$storyTitle · 音乐伴奏';
      default:
        return '$storyTitle · 教学资源';
    }
  }

  Map<String, dynamic>? _parseLessonPlanJson(String raw) {
    if (raw.isEmpty) return null;
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final candidate = trimmed.substring(start, end + 1);
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic> _normalizeLessonPlan(Map<String, dynamic> data) {
    final objectives = _stringList(data['objectives']);
    final materials = _stringList(data['materials']);
    final questions = _stringList(data['questions']);
    final differentiation = _stringList(data['differentiation']);
    final summary = _stringList(data['summary']);
    final extensions = _stringList(data['extensions'] ?? data['homework']);
    final stages = _normalizeLessonStages(data['stages']);

    final result = <String, dynamic>{'type': 'lesson_plan'};
    if (objectives.isNotEmpty) result['objectives'] = objectives;
    if (materials.isNotEmpty) result['materials'] = materials;
    if (stages.isNotEmpty) result['stages'] = stages;
    if (questions.isNotEmpty) result['questions'] = questions;
    if (differentiation.isNotEmpty) {
      result['differentiation'] = differentiation;
    }
    if (summary.isNotEmpty) result['summary'] = summary;
    if (extensions.isNotEmpty) result['extensions'] = extensions;
    return result;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((text) => text.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const [];
      return text
          .split(RegExp(r'[\n;,]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _normalizeLessonStages(dynamic value) {
    final stages = <Map<String, dynamic>>[];
    if (value is List) {
      for (final entry in value) {
        if (entry is Map) {
          final name =
              _stringValue(entry['name'] ?? entry['stage'] ?? entry['title']);
          final duration = _stringValue(entry['duration'] ?? entry['time']);
          final goal = _stringValue(
              entry['goal'] ?? entry['focus'] ?? entry['objective']);
          final activities = _stringList(entry['activities'] ?? entry['steps']);
          final teacher = _stringList(entry['teacherActions'] ??
              entry['teacher'] ??
              entry['teacherNotes']);
          final students = _stringList(entry['studentActivities'] ??
              entry['students'] ??
              entry['studentActions']);
          final questions =
              _stringList(entry['keyQuestions'] ?? entry['questions']);
          final materials = _stringList(entry['materials']);
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

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _summarizeLessonPlan(Map<String, dynamic> plan) {
    final objectives = _stringList(plan['objectives']);
    final stageList =
        (plan['stages'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
            const [];
    final buffer = StringBuffer();
    if (objectives.isNotEmpty) {
      buffer.writeln('目标：${objectives.take(2).join('，')}');
    }
    if (stageList.isNotEmpty) {
      final labels = stageList
          .map((stage) {
            final name = stage['name'] as String? ?? '课堂环节';
            final duration = stage['duration'] as String?;
            return duration != null ? '$name（$duration）' : name;
          })
          .where((text) => text.isNotEmpty)
          .take(4)
          .join('、');
      if (labels.isNotEmpty) {
        buffer.writeln('流程：$labels');
      }
    }
    final summaryNotes = _stringList(plan['summary']);
    if (summaryNotes.isNotEmpty) {
      buffer.writeln(summaryNotes.first);
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? '教案内容已生成，可查看详细步骤。' : text;
  }

  String _structureDescription(dynamic value) {
    final lines = _stringList(value);
    if (lines.isEmpty) return '';
    return '音乐结构：${lines.join(' / ')}';
  }

  String _labelFor(String kind) {
    for (final blueprint in kStoryAssetBlueprints) {
      if (blueprint['kind'] == kind) {
        return blueprint['label']!;
      }
    }
    return kind;
  }

  // ==================== 教案生成功能 ====================

  /// 生成完整教案
  Future<bool> generateFullLessonPlan({
    required String gradeLevel,
    required int duration,
  }) async {
    if (_activeStory == null) {
      _error = '请先创建或加载一个教学故事';
      notifyListeners();
      return false;
    }

    _isGeneratingLesson = true;
    _error = null;
    notifyListeners();

    try {
      // 生成教案模板
      final template = await _lessonTemplateGenerator.generateLessonTemplate(
        theme: _activeStory!.theme ?? _activeStory!.title,
        gradeLevel: gradeLevel,
        duration: duration,
        availableResources: _assets.values.map((a) => a.kind).toList(),
      );

      // 为每个资源生成使用指南
      final usageGuides = <String, ResourceGuide>{};
      for (final entry in _assets.entries) {
        final assetId = entry.key;
        final asset = entry.value;
        try {
          final guide = await _lessonTemplateGenerator.generateResourceUsageGuide(
            resourceType: asset.kind,
            resourceDescription: asset.preview['summary']?.toString() ?? asset.kind,
            lessonContext: _activeStory!.theme ?? _activeStory!.title,
          );

          usageGuides[assetId] = ResourceGuide(
            resourceId: assetId,
            timing: guide.timing,
            method: guide.method,
            interaction: guide.interaction,
            tips: guide.tips,
          );
        } catch (e) {
          debugPrint('Failed to generate usage guide for $assetId: $e');
        }
      }

      // 转换为教学步骤
      final teachingSteps = template.steps.map((step) {
        return TeachingStep(
          title: step.title,
          duration: step.duration,
          activities: step.activities,
          resourceIds: _matchResourceIds(step.resources),
          teacherActions: step.activities.isNotEmpty ? step.activities : null,
          studentActivities: [],
        );
      }).toList();

      _currentLessonPlan = LessonPlan(
        storyId: _activeStory!.id,
        gradeLevel: gradeLevel,
        duration: duration,
        objectives: template.objectives,
        keyPoints: template.keyPoints,
        preparation: template.preparation,
        teachingSteps: teachingSteps,
        homework: template.homework,
        usageGuides: usageGuides,
      );

      _isGeneratingLesson = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '教案生成失败: $e';
      _isGeneratingLesson = false;
      notifyListeners();
      return false;
    }
  }

  /// 生成简化教案（新手模式）
  Future<SimplifiedLesson?> generateSimplifiedLesson() async {
    if (_activeStory == null) {
      _error = '请先创建或加载一个教学故事';
      notifyListeners();
      return null;
    }

    _isGeneratingLesson = true;
    _error = null;
    notifyListeners();

    try {
      final lesson = await _lessonTemplateGenerator.generateSimplifiedLesson(
        theme: _activeStory!.theme ?? _activeStory!.title,
        availableResources: _assets.values.map((a) => a.kind).toList(),
      );

      _isGeneratingLesson = false;
      notifyListeners();
      return lesson;
    } catch (e) {
      _error = '简化教案生成失败: $e';
      _isGeneratingLesson = false;
      notifyListeners();
      return null;
    }
  }

  /// 评估教案质量
  Future<QualityScore?> evaluateLessonPlanQuality() async {
    if (_currentLessonPlan == null) {
      return null;
    }

    try {
      final qualityCriteria = [
        '教学目标明确且可衡量',
        '教学步骤清晰易执行',
        '适合乡村教学环境',
        '注重学生参与互动',
        '资源使用合理高效',
        '时间分配科学',
        '考虑大班教学需求',
      ];

      final score = await _caseAnalyzer.evaluateLessonPlan(
        lessonPlanData: _currentLessonPlan!.toJson(),
        qualityCriteria: qualityCriteria,
      );

      return score;
    } catch (e) {
      debugPrint('质量评估失败: $e');
      return null;
    }
  }

  /// 匹配资源ID
  List<String> _matchResourceIds(List<String> resourceDescriptions) {
    final matchedIds = <String>[];
    
    for (final desc in resourceDescriptions) {
      final descLower = desc.toLowerCase();
      for (final entry in _assets.entries) {
        final asset = entry.value;
        if (descLower.contains(asset.kind.toLowerCase()) ||
            asset.kind.toLowerCase().contains(descLower)) {
          if (!matchedIds.contains(entry.key)) {
            matchedIds.add(entry.key);
          }
        }
      }
    }
    
    return matchedIds;
  }

  /// 清除当前教案
  void clearLessonPlan() {
    _currentLessonPlan = null;
    notifyListeners();
  }
}
