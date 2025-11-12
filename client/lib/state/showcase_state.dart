import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/showcase.dart';
import '../models/story_asset.dart';
import '../models/teacher_story.dart';
import '../services/app_api_service.dart';
import '../services/story_cache_service.dart';
import 'auth_state.dart';

class ShowcaseState extends ChangeNotifier {
  ShowcaseState(this._auth);

  AuthState _auth;
  List<ShowcaseItem> _items = [];
  List<ShowcaseCategory> _categories = [];
  bool _isLoading = false;
  String _activeCategory = 'all';
  String _scope = 'classes';
  String? _activeClassId;
  String? _error;

  List<ShowcaseItem> get items => _items;
  List<ShowcaseCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String get activeCategory => _activeCategory;
  String get scope => _scope;
  String? get activeClassId => _activeClassId;
  String? get error => _error;

  void updateAuth(AuthState auth) {
    if (!identical(_auth, auth)) {
      _auth = auth;
      notifyListeners();
    }
  }

  Future<void> loadItems({String category = 'all'}) async {
    await loadFeed(scope: _scope, classId: _activeClassId, category: category);
  }

  Future<void> loadFeed({
    String scope = 'classes',
    String? classId,
    String category = 'all',
  }) async {
    _setLoading(true);
    try {
      _scope = scope;
      _activeClassId = classId;
      _activeCategory = category;

      Map<String, dynamic> response;
      if (_auth.token != null) {
        response = await AppApiService.fetchContentFeed(
          token: _auth.token!,
          scope: scope,
          classId: classId,
          kind: category == 'all' ? null : category,
        );
      } else {
        response = await AppApiService.listShowcaseItems(category: category);
      }

      final itemsJson = response['items'] as List<dynamic>? ?? [];
      final normalizedItems = itemsJson
          .whereType<Map<String, dynamic>>()
          .map(_normalizeContentJson)
          .toList();

      await _hydrateStoryContent(normalizedItems);

      _items = normalizedItems.map(ShowcaseItem.fromJson).toList();

      final categoriesResponse = await AppApiService.fetchShowcaseCategories();
      final categoriesJson =
          categoriesResponse['categories'] as List<dynamic>? ?? [];
      _categories = categoriesJson
          .whereType<Map<String, dynamic>>()
          .map(ShowcaseCategory.fromJson)
          .toList();

      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleLike(String itemId) async {
    if (_auth.token == null) {
      _error = '请先登录后再点赞';
      notifyListeners();
      return false;
    }

    try {
      final response = await AppApiService.toggleContentLike(
        token: _auth.token!,
        contentId: itemId,
      );
      final contentJson = response['content'] as Map<String, dynamic>?;
      if (contentJson != null) {
        final updated =
            ShowcaseItem.fromJson(_normalizeContentJson(contentJson));
        _items =
            _items.map((item) => item.id == itemId ? updated : item).toList();
      }
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContent(String itemId) async {
    if (_auth.token == null) {
      _error = '请先登录后再操作';
      notifyListeners();
      return false;
    }
    try {
      await AppApiService.deleteContent(
        token: _auth.token!,
        contentId: itemId,
      );
      _items = _items.where((item) => item.id != itemId).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadContent({
    required String title,
    required String kind,
    String? description,
    String visibility = 'classes',
    List<String> classroomIds = const [],
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
    bool teacherGenerated = false,
    bool aiGenerated = false,
    String? storyId,
    Uint8List? fileBytes,
    String? fileName,
    String? fileMimeType,
  }) async {
    if (_auth.token == null) {
      _error = '请先登录后再上传作品';
      notifyListeners();
      return false;
    }

    try {
      Map<String, dynamic> response;

      // 如果有文件，使用文件上传API
      if (fileBytes != null && fileName != null && fileName.isNotEmpty) {
        final mergedMetadata = <String, dynamic>{...?metadata};
        Map<String, dynamic>? uploadPreview =
            preview != null ? Map<String, dynamic>.from(preview) : null;

        try {
          mergedMetadata['localFileSize'] = fileBytes.length;
          uploadPreview ??= <String, dynamic>{};
          uploadPreview['size'] ??= fileBytes.length;
        } catch (_) {
          // ignore failures to enrich metadata
        }

        final trimmedName = fileName.trim().isEmpty ? 'upload.bin' : fileName.trim();
        uploadPreview ??= <String, dynamic>{};
        uploadPreview['type'] ??= 'user_upload';
        uploadPreview['fileName'] ??= trimmedName;

        response = await AppApiService.uploadFile(
          token: _auth.token!,
          title: title,
          kind: kind,
          visibility: visibility,
          classroomIds: classroomIds,
          fileBytes: fileBytes,
          fileName: trimmedName,
          mimeType: fileMimeType,
          description: description,
          metadata: mergedMetadata.isEmpty ? null : mergedMetadata,
          preview: uploadPreview.isEmpty ? null : uploadPreview,
          teacherGenerated: teacherGenerated,
          aiGenerated: aiGenerated,
          storyId: storyId,
        );
      } else {
        // 否则使用原有的内容上传API
        response = await AppApiService.uploadContent(
          token: _auth.token!,
          title: title,
          kind: kind,
          visibility: visibility,
          classroomIds: classroomIds,
          description: description,
          preview: preview,
          metadata: metadata,
          teacherGenerated: teacherGenerated,
          aiGenerated: aiGenerated,
          storyId: storyId,
        );
      }

      final itemJson = response['content'] as Map<String, dynamic>?;
      if (itemJson != null) {
        final item = ShowcaseItem.fromJson(_normalizeContentJson(itemJson));
        _items = [item, ..._items];
        notifyListeners();
      }
      _error = null;
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<ShowcaseItem?> commentOnContent({
    required String contentId,
    required String text,
  }) async {
    if (_auth.token == null) {
      _error = '请先登录后再评论';
      notifyListeners();
      return null;
    }

    try {
      final response = await AppApiService.commentOnContent(
        token: _auth.token!,
        contentId: contentId,
        content: text,
      );
      final contentJson = response['content'] as Map<String, dynamic>?;
      if (contentJson == null) {
        _error = '服务器未返回更新后的作品信息';
        notifyListeners();
        return null;
      }
      final item = ShowcaseItem.fromJson(_normalizeContentJson(contentJson));
      _items = _items
          .map((existing) => existing.id == item.id ? item : existing)
          .toList();
      _error = null;
      notifyListeners();
      return item;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> importStoryBundle({
    required Map<String, dynamic> story,
    required List<String> classroomIds,
    String? title,
  }) async {
    if (_auth.token == null) {
      _error = '请先登录后再导入故事';
      notifyListeners();
      return false;
    }
    if (classroomIds.isEmpty) {
      _error = '请选择班级';
      notifyListeners();
      return false;
    }
    try {
      await AppApiService.importStoryBundle(
        token: _auth.token!,
        story: story,
        classroomIds: classroomIds,
        title: title,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _hydrateStoryContent(List<Map<String, dynamic>> items) async {
    final tasks = <Future<void>>[];
    for (final item in items) {
      final metadata =
          item['metadata'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final storyId = _extractStoryId(item, metadata);
      if (storyId == null || storyId.isEmpty) continue;

      final existingAssets =
          metadata['assets'] as Map<String, dynamic>? ?? const {};
      if (existingAssets.isNotEmpty) {
        continue;
      }

      tasks.add(_ensureStoryAssetsCached(storyId, metadata));
    }

    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
  }

  String? _extractStoryId(
    Map<String, dynamic> item,
    Map<String, dynamic> metadata,
  ) {
    final preview = item['preview'] as Map<String, dynamic>? ?? const {};
    final candidates = [
      metadata['storyId'],
      metadata['story_id'],
      preview['storyId'],
      item['storyId'],
      item['story_id'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        final value = candidate.trim();
        metadata['storyId'] = value;
        return value;
      }
    }
    return null;
  }

  Future<void> _ensureStoryAssetsCached(
    String storyId,
    Map<String, dynamic> metadata,
  ) async {
    final cache = StoryCacheService();
    final cached = await cache.load(storyId);
    if (cached != null) {
      final cachedAssets = cached['assets'];
      if (cachedAssets is Map<String, dynamic> && cachedAssets.isNotEmpty) {
        metadata['assets'] = _normalizeAssets(cachedAssets);
      }
      final cachedStory = cached['story'];
      if (cachedStory is Map<String, dynamic>) {
        final bundle = {
          'title': cachedStory['title'],
          'theme': cachedStory['theme'],
          'steps': cachedStory['steps'],
        };
        metadata['storyBundle'] ??= _normalizeStoryBundle(bundle);
        metadata['classroomIds'] ??=
            (cachedStory['classroomIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();
      }
      final hasAssets =
          (metadata['assets'] as Map<String, dynamic>? ?? const {}).isNotEmpty;
      if (hasAssets) {
        return;
      }
    }

    await _loadStoryAssetsIntoMetadata(storyId, metadata);
  }

  Future<void> _loadStoryAssetsIntoMetadata(
    String storyId,
    Map<String, dynamic> metadata,
  ) async {
    final cache = StoryCacheService();
    final cached = await cache.load(storyId);
    if (cached != null && cached.isNotEmpty) {
      metadata['assets'] = cached;
      return;
    }
    if (_auth.token == null) return;
    try {
      final response = await AppApiService.fetchStory(
        token: _auth.token!,
        storyId: storyId,
      );
      final storyJson = response['story'] as Map<String, dynamic>?;
      if (storyJson == null) return;
      final story = TeacherStory.fromJson(storyJson);
      final assetsJson = _buildStoryAssetsJson(story);
      if (assetsJson.isNotEmpty) {
        final normalizedAssets = _normalizeAssets(assetsJson);
        metadata['assets'] = normalizedAssets;
        await cache.save(storyId, {
          'story': story.toJson(),
          'assets': normalizedAssets,
          'savedAt': DateTime.now().toIso8601String(),
        });
      }
      final bundle = {
        'id': story.id,
        'title': story.title,
        'theme': story.theme,
        'classroomIds': story.classroomIds,
        'steps': story.steps.map((step) => step.toJson()).toList(),
      };
      metadata['storyBundle'] = _normalizeStoryBundle(bundle);
      metadata['classroomIds'] ??= story.classroomIds;
    } catch (error) {
      debugPrint('Failed to hydrate story $storyId: $error');
    }
  }

  Map<String, dynamic> _buildStoryAssetsJson(TeacherStory story) {
    final assets = <String, StoryAsset>{};
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
              payload['preview'] as Map<String, dynamic>,
            )
          : const <String, dynamic>{};
      final data = Map<String, dynamic>.from(payload)..remove('preview');
      assets[kind] = StoryAsset(
        kind: kind,
        label: label,
        summary: matched?.summary,
        preview: preview,
        metadata: data,
        status: matched?.completed == true
            ? StoryAssetStatus.uploaded
            : StoryAssetStatus.idle,
      );
    }
    return assets.toJson();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Map<String, dynamic> _normalizeContentJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    final preview =
        (json['preview'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final metadata =
        (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (preview.isNotEmpty) {
      normalized['preview'] = _normalizeMediaMap(preview);
    }
    if (metadata.isNotEmpty) {
      normalized['metadata'] = _normalizeMediaMap(metadata);
      final storyBundle = metadata['storyBundle'];
      if (storyBundle is Map<String, dynamic>) {
        normalized['metadata'] = {
          ...normalized['metadata'] as Map<String, dynamic>,
          'storyBundle': _normalizeStoryBundle(storyBundle),
        };
      }
      final assets = metadata['assets'];
      if (assets is Map<String, dynamic>) {
        normalized['metadata'] = {
          ...normalized['metadata'] as Map<String, dynamic>,
          'assets': _normalizeAssets(assets),
        };
      }
    }
    return normalized;
  }

  Map<String, dynamic> _normalizeMediaMap(Map<String, dynamic> source) {
    final updated = Map<String, dynamic>.from(source);
    updated.removeWhere((key, value) => key.toString().startsWith('local'));
    const mediaKeys = [
      'fileUrl',
      'imageUrl',
      'audioUrl',
      'videoUrl',
      'thumbnailUrl'
    ];
    for (final key in mediaKeys) {
      final value = updated[key];
      if (value is String && value.trim().isNotEmpty) {
        updated[key] = AppApiService.resolveUrl(value);
      }
    }
    return updated;
  }

  Map<String, dynamic> _normalizeStoryBundle(Map<String, dynamic> bundle) {
    final normalized = Map<String, dynamic>.from(bundle);
    final steps = (bundle['steps'] as List<dynamic>? ?? []).map((step) {
      if (step is Map<String, dynamic>) {
        final payload = Map<String, dynamic>.from(
          (step['payload'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
        );
        if (payload['preview'] is Map<String, dynamic>) {
          payload['preview'] = _normalizeMediaMap(
            Map<String, dynamic>.from(
                payload['preview'] as Map<String, dynamic>),
          );
        }
        if (payload['metadata'] is Map<String, dynamic>) {
          payload['metadata'] = _normalizeMediaMap(
            Map<String, dynamic>.from(
                payload['metadata'] as Map<String, dynamic>),
          );
        }
        return {
          ...step,
          'payload': payload,
        };
      }
      return step;
    }).toList();
    normalized['steps'] = steps;
    return normalized;
  }

  Map<String, dynamic> _normalizeAssets(Map<String, dynamic> assets) {
    final normalized = <String, dynamic>{};
    assets.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final assetMap = Map<String, dynamic>.from(value);
        assetMap.removeWhere((k, v) => k.toString().startsWith('local'));
        if (assetMap['preview'] is Map<String, dynamic>) {
          assetMap['preview'] = _normalizeMediaMap(
            Map<String, dynamic>.from(
                assetMap['preview'] as Map<String, dynamic>),
          );
        }
        if (assetMap['metadata'] is Map<String, dynamic>) {
          assetMap['metadata'] = _normalizeMediaMap(
            Map<String, dynamic>.from(
                assetMap['metadata'] as Map<String, dynamic>),
          );
        }
        normalized[key] = assetMap;
      } else {
        normalized[key] = value;
      }
    });
    return normalized;
  }
}
