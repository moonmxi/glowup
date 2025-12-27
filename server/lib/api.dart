import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import 'auth.dart';
import 'data_store.dart';
import 'models.dart';
import 'utils.dart';

typedef Json = Map<String, dynamic>;

class ApiServer {
  ApiServer({
    required this.store,
    required this.authManager,
  });

  final DataStore store;
  final AuthManager authManager;

  Future<void> handle(HttpRequest request) async {
    _applyCors(request);

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.noContent
        ..close();
      return;
    }

    final segments = request.uri.pathSegments;
    if (segments.isEmpty || segments.first != 'api') {
      return _sendNotFound(request);
    }

    try {
      final subPath = segments.skip(1).toList();
      if (subPath.isEmpty) {
        return _sendNotFound(request);
      }
      final category = subPath.first;

      switch (category) {
        case 'auth':
          return await _handleAuth(request, subPath.skip(1).toList());
        case 'classrooms':
          return await _handleClassrooms(request, subPath.skip(1).toList());
        case 'stories':
          return await _handleStories(request, subPath.skip(1).toList());
        case 'content':
          return await _handleContent(request, subPath.skip(1).toList());
        case 'showcase':
          return await _handleShowcase(request, subPath.skip(1).toList());
        case 'uploads':
          return await _handleUploads(request, subPath.skip(1).toList());
        default:
          return _sendNotFound(request);
      }
    } catch (error, stackTrace) {
      stderr.writeln('Error handling ${request.uri}: $error');
      stderr.writeln(stackTrace);
      await _sendError(request, error.toString());
    }
  }

  Future<void> _handleAuth(HttpRequest request, List<String> path) async {
    switch (request.method) {
      case 'POST':
        if (path.isEmpty) {
          return _sendNotFound(request);
        }
        if (path.first == 'register') {
          final payload = await _readJson(request);
          return _register(request, payload);
        }
        if (path.first == 'login') {
          final payload = await _readJson(request);
          return _login(request, payload);
        }
        break;
      case 'GET':
        if (path.isNotEmpty && path.first == 'me') {
          final user = authManager.authenticate(request);
          if (user == null) {
            return _sendUnauthorized(request);
          }
          return _sendJson(request, _serializeAuthPayload(user));
        }
        break;
    }
    return _sendNotFound(request);
  }

  Future<void> _register(HttpRequest request, Json payload) async {
    final username = (payload['username'] as String?)?.trim();
    final password = payload['password'] as String?;
    final role = payload['role'] as String?;
    final classroomName = (payload['classroomName'] as String?)?.trim();
    final rawClassroomCode = (payload['classroomCode'] as String?)?.trim();
    final classroomCode = rawClassroomCode?.toUpperCase();

    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return _sendError(request, '用户名或密码不能为空', status: HttpStatus.badRequest);
    }
    if (role != 'teacher' && role != 'student') {
      return _sendError(request, '角色必须是 teacher 或 student',
          status: HttpStatus.badRequest);
    }
    if (store.users.any((user) => user.username == username)) {
      return _sendError(request, '用户名已存在', status: HttpStatus.conflict);
    }

    final resolvedRole = role!;
    final user = User(
      id: generateId(),
      username: username,
      password: password,
      role: resolvedRole,
    );

    Classroom? classroom;

    if (resolvedRole == 'teacher') {
      final newClassroom = Classroom(
        id: generateId(),
        code: generateCode(),
        name:
            classroomName?.isNotEmpty == true ? classroomName! : '$username的班级',
        teacherId: user.id,
      );
      user.managedClassroomIds.add(newClassroom.id);
      store.classrooms.add(newClassroom);
      classroom = newClassroom;
    } else {
      if (classroomCode == null || classroomCode.isEmpty) {
        return _sendError(request, '学生注册需要填写班级编码',
            status: HttpStatus.badRequest);
      }
      final target = store.classrooms.firstWhere(
        (room) => room.code == classroomCode,
        orElse: () => Classroom(
          id: '',
          code: '',
          name: '',
          teacherId: '',
        ),
      );
      if (target.id.isEmpty) {
        return _sendError(request, '未找到班级编码', status: HttpStatus.notFound);
      }
      target.studentIds.add(user.id);
      user.joinedClassroomId = target.id;
      classroom = target;
      await store.saveClassrooms();
    }

    store.users.add(user);
    await store.saveUsers();

    final token = authManager.issueToken(user);
    final payloadJson =
        _serializeAuthPayload(user, overrideToken: token, classroom: classroom);
    return _sendJson(request, payloadJson);
  }

  Future<void> _login(HttpRequest request, Json payload) async {
    final username = (payload['username'] as String?)?.trim();
    final password = payload['password'] as String?;

    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return _sendError(request, '请输入用户名和密码', status: HttpStatus.badRequest);
    }

    final user = store.users.firstWhere(
      (u) => u.username == username && u.password == password,
      orElse: () => User(id: '', username: '', password: '', role: ''),
    );

    if (user.id.isEmpty) {
      return _sendError(request, '用户名或密码错误', status: HttpStatus.unauthorized);
    }

    final token = authManager.issueToken(user);
    final classroom = _primaryClassroomFor(user);
    final payloadJson =
        _serializeAuthPayload(user, overrideToken: token, classroom: classroom);
    return _sendJson(request, payloadJson);
  }

  Classroom? _primaryClassroomFor(User user) {
    if (user.isTeacher) {
      if (user.managedClassroomIds.isEmpty) return null;
      final classroomId = user.managedClassroomIds.first;
      return store.classrooms
              .firstWhere(
                (room) => room.id == classroomId,
                orElse: () =>
                    Classroom(id: '', code: '', name: '', teacherId: ''),
              )
              .id
              .isEmpty
          ? null
          : store.classrooms.firstWhere((room) => room.id == classroomId);
    }
    if (user.joinedClassroomId == null) return null;
    final classId = user.joinedClassroomId!;
    return store.classrooms
            .firstWhere(
              (room) => room.id == classId,
              orElse: () =>
                  Classroom(id: '', code: '', name: '', teacherId: ''),
            )
            .id
            .isEmpty
        ? null
        : store.classrooms.firstWhere((room) => room.id == classId);
  }

  Json _serializeAuthPayload(
    User user, {
    String? overrideToken,
    Classroom? classroom,
  }) {
    final userJson = {
      'id': user.id,
      'username': user.username,
      'role': user.role,
      'classroomId': user.joinedClassroomId ??
          (user.managedClassroomIds.isNotEmpty
              ? user.managedClassroomIds.first
              : null),
      'classroomCode': classroom?.code,
    };

    final classroomJson =
        classroom == null ? null : _serializeClassroom(classroom);

    final result = <String, dynamic>{
      if (overrideToken != null) 'token': overrideToken,
      'user': userJson,
      if (classroomJson != null) 'classroom': classroomJson,
      if (user.isTeacher)
        'classrooms': user.managedClassroomIds
            .map((id) => store.classrooms.firstWhere(
                  (room) => room.id == id,
                  orElse: () =>
                      Classroom(id: '', code: '', name: '', teacherId: ''),
                ))
            .where((room) => room.id.isNotEmpty)
            .map(_serializeClassroom)
            .toList(),
    };
    return result;
  }

  Json _serializeClassroom(Classroom classroom) {
    final teacher = store.users.firstWhere(
      (u) => u.id == classroom.teacherId,
      orElse: () => User(id: '', username: '', password: '', role: ''),
    );
    return {
      'id': classroom.id,
      'code': classroom.code,
      'name': classroom.name,
      'teacher': {
        'id': classroom.teacherId,
        'username': teacher.username,
      },
      'students': classroom.studentIds
          .map(
            (id) => store.users.firstWhere(
              (u) => u.id == id,
              orElse: () => User(id: '', username: '', password: '', role: ''),
            ),
          )
          .where((u) => u.id.isNotEmpty)
          .map((u) => {'id': u.id, 'username': u.username})
          .toList(),
      'createdAt': classroom.createdAt.toIso8601String(),
    };
  }

  Future<void> _handleClassrooms(HttpRequest request, List<String> path) async {
    final user = authManager.authenticate(request);
    if (user == null) {
      return _sendUnauthorized(request);
    }

    if (request.method == 'POST' && path.isEmpty) {
      if (!user.isTeacher) {
        return _sendError(request, '只有教师可以创建班级', status: HttpStatus.forbidden);
      }
      final payload = await _readJson(request);
      final name = (payload['name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        return _sendError(request, '班级名称不能为空', status: HttpStatus.badRequest);
      }
      final classroom = Classroom(
        id: generateId(),
        code: generateCode(),
        name: name,
        teacherId: user.id,
      );
      store.classrooms.add(classroom);
      user.managedClassroomIds.add(classroom.id);
      await Future.wait([store.saveClassrooms(), store.saveUsers()]);
      return _sendJson(request, {'classroom': _serializeClassroom(classroom)});
    }

    if (request.method == 'POST' && path.length == 1 && path.first == 'join') {
      if (!user.isStudent) {
        return _sendError(request, '只有学生可以加入班级', status: HttpStatus.forbidden);
      }
      final payload = await _readJson(request);
      final code = (payload['code'] as String?)?.trim().toUpperCase();
      if (code == null || code.isEmpty) {
        return _sendError(request, '请输入班级编码', status: HttpStatus.badRequest);
      }
      final classroom = store.classrooms.firstWhere(
        (room) => room.code == code,
        orElse: () => Classroom(id: '', code: '', name: '', teacherId: ''),
      );
      if (classroom.id.isEmpty) {
        return _sendError(request, '未找到班级编码', status: HttpStatus.notFound);
      }
      if (!classroom.studentIds.contains(user.id)) {
        classroom.studentIds.add(user.id);
      }
      user.joinedClassroomId = classroom.id;
      await Future.wait([store.saveClassrooms(), store.saveUsers()]);
      return _sendJson(request, {'classroom': _serializeClassroom(classroom)});
    }

    if (request.method == 'GET' && path.isEmpty) {
      if (user.isTeacher) {
        final classes = user.managedClassroomIds
            .map((id) => store.classrooms.firstWhere(
                  (room) => room.id == id,
                  orElse: () =>
                      Classroom(id: '', code: '', name: '', teacherId: ''),
                ))
            .where((room) => room.id.isNotEmpty)
            .map(_serializeClassroom)
            .toList();
        return _sendJson(request, {'classrooms': classes});
      } else {
        final classroom = _primaryClassroomFor(user);
        return _sendJson(request, {
          'classroom':
              classroom != null ? _serializeClassroom(classroom) : null,
        });
      }
    }

    if (request.method == 'DELETE' && path.length == 1) {
      if (!user.isTeacher) {
        return _sendError(request, '只有教师可以解散班级', status: HttpStatus.forbidden);
      }
      final id = path.first;
      final classroomIndex =
          store.classrooms.indexWhere((room) => room.id == id);
      if (classroomIndex == -1) {
        return _sendError(request, '班级不存在', status: HttpStatus.notFound);
      }
      final classroom = store.classrooms[classroomIndex];
      if (classroom.teacherId != user.id) {
        return _sendError(request, '只能解散自己创建的班级', status: HttpStatus.forbidden);
      }
      store.classrooms.removeAt(classroomIndex);
      user.managedClassroomIds.remove(id);
      for (final u in store.users) {
        if (u.joinedClassroomId == id) {
          u.joinedClassroomId = null;
        }
      }
      await Future.wait([store.saveClassrooms(), store.saveUsers()]);
      return _sendJson(request, {'success': true});
    }

    return _sendNotFound(request);
  }

  Future<void> _handleStories(HttpRequest request, List<String> path) async {
    final user = authManager.authenticate(request);
    if (user == null) {
      return _sendUnauthorized(request);
    }
    if (!user.isTeacher) {
      return _sendError(request, '故事流程仅教师可用', status: HttpStatus.forbidden);
    }

    if (request.method == 'POST' && path.isEmpty) {
      final payload = await _readJson(request);
      final title = (payload['title'] as String?)?.trim();
      if (title == null || title.isEmpty) {
        return _sendError(request, '故事标题不能为空', status: HttpStatus.badRequest);
      }
      final classroomIds = (payload['classroomIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((id) => id.isNotEmpty)
          .toList();
      if (classroomIds.isEmpty) {
        return _sendError(request, '请选择至少一个班级', status: HttpStatus.badRequest);
      }
      final theme = (payload['theme'] as String?)?.trim();
      final story = Story(
        id: generateId(),
        teacherId: user.id,
        classroomIds: classroomIds,
        title: title,
        theme: theme,
        steps: _buildDefaultStorySteps(theme),
        metadata: (payload['metadata'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      );
      store.stories.add(story);
      await store.saveStories();
      return _sendJson(request, {'story': _serializeStory(story)});
    }

    if (request.method == 'PUT' && path.length == 1) {
      final storyId = path.first;
      final story = store.stories.firstWhere(
        (s) => s.id == storyId,
        orElse: () =>
            Story(id: '', teacherId: '', classroomIds: const [], title: ''),
      );
      if (story.id.isEmpty) {
        return _sendError(request, '故事不存在', status: HttpStatus.notFound);
      }
      if (story.teacherId != user.id) {
        return _sendError(request, '无权修改该故事', status: HttpStatus.forbidden);
      }
      final payload = await _readJson(request);
      story.title = (payload['title'] as String?)?.trim() ?? story.title;
      story.theme = (payload['theme'] as String?)?.trim() ?? story.theme;
      story.status = (payload['status'] as String?)?.trim() ?? story.status;

      if (payload['classroomIds'] is List) {
        story.classroomIds = (payload['classroomIds'] as List<dynamic>)
            .map((e) => e.toString())
            .where((id) => id.isNotEmpty)
            .toList();
      }

      if (payload['steps'] is List) {
        final updatedSteps = <StoryStep>[];
        for (final item in payload['steps'] as List<dynamic>) {
          if (item is Map<String, dynamic>) {
            updatedSteps.add(StoryStep.fromJson(item));
          }
        }
        if (updatedSteps.isNotEmpty) {
          story.steps = updatedSteps;
        }
      }

      if (payload['metadata'] is Map<String, dynamic>) {
        story.metadata = Map<String, dynamic>.from(
          payload['metadata'] as Map<String, dynamic>,
        );
      }

      await store.saveStories();
      return _sendJson(request, {'story': _serializeStory(story)});
    }

    if (request.method == 'GET' && path.isEmpty) {
      final stories = store.stories
          .where((story) => story.teacherId == user.id)
          .map(_serializeStory)
          .toList();
      return _sendJson(request, {'stories': stories});
    }

    if (request.method == 'GET' && path.length == 1) {
      final storyId = path.first;
      final story = store.stories.firstWhere(
        (s) => s.id == storyId,
        orElse: () =>
            Story(id: '', teacherId: '', classroomIds: const [], title: ''),
      );
      if (story.id.isEmpty) {
        return _sendError(request, '故事不存在', status: HttpStatus.notFound);
      }
      if (story.teacherId != user.id) {
        return _sendError(request, '无权查看该故事', status: HttpStatus.forbidden);
      }
      return _sendJson(request, {'story': _serializeStory(story)});
    }

    if (request.method == 'DELETE' && path.length == 1) {
      final storyId = path.first;
      final storyIndex =
          store.stories.indexWhere((story) => story.id == storyId);
      if (storyIndex == -1) {
        return _sendError(request, '故事不存在', status: HttpStatus.notFound);
      }
      final story = store.stories[storyIndex];
      if (story.teacherId != user.id) {
        return _sendError(request, '无权删除该故事', status: HttpStatus.forbidden);
      }

      final relatedContents = store.contents
          .where((content) => content.storyId == storyId)
          .toList();
      store.stories.removeAt(storyIndex);
      for (final entry in relatedContents) {
        store.contents.removeWhere((content) => content.id == entry.id);
        await _deleteContentFiles(entry);
      }
      await Future.wait([
        store.saveStories(),
        store.saveContents(),
      ]);
      return _sendJson(request, {'success': true});
    }

    if (request.method == 'POST' &&
        path.length == 1 &&
        path.first == 'import') {
      final payload = await _readJson(request);
      final storyPayload = payload['story'] as Map<String, dynamic>?;
      if (storyPayload == null || storyPayload.isEmpty) {
        return _sendError(request, '缺少需要导入的故事数据',
            status: HttpStatus.badRequest);
      }
      final classroomIds = (payload['classroomIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((id) => id.isNotEmpty)
          .toList();
      if (classroomIds.isEmpty) {
        return _sendError(request, '请选择导入的班级', status: HttpStatus.badRequest);
      }
      for (final id in classroomIds) {
        if (!user.managedClassroomIds.contains(id)) {
          return _sendError(
            request,
            '只能导入到自己管理的班级',
            status: HttpStatus.forbidden,
          );
        }
      }

      Story sourceStory;
      try {
        sourceStory = Story.fromJson(storyPayload);
      } catch (error) {
        return _sendError(request, '无法解析故事数据: $error',
            status: HttpStatus.badRequest);
      }

      final String titleOverride =
          (payload['title'] as String?)?.trim() ?? sourceStory.title;

      final Story importedStory = Story(
        id: generateId(),
        teacherId: user.id,
        classroomIds: classroomIds,
        title: titleOverride,
        theme: sourceStory.theme,
        status: 'draft',
        steps: <StoryStep>[],
        metadata: {
          'originStoryId': sourceStory.id,
          'originTeacherId': sourceStory.teacherId,
        },
      );

      final List<StoryStep> clonedSteps = <StoryStep>[];
      for (final step in sourceStory.steps) {
        final stepPayload = Map<String, dynamic>.from(step.payload);
        final preview = Map<String, dynamic>.from(
          (stepPayload['preview'] as Map<String, dynamic>? ??
              <String, dynamic>{}),
        );
        final metadata = Map<String, dynamic>.from(
          (stepPayload['metadata'] as Map<String, dynamic>? ??
              <String, dynamic>{}),
        );
        final originalContentId = (metadata['contentId'] as String?)?.trim();
        if (originalContentId != null && originalContentId.isNotEmpty) {
          final sourceIndex =
              store.contents.indexWhere((c) => c.id == originalContentId);
          if (sourceIndex != -1) {
            final sourceContent = store.contents[sourceIndex];
            final clonedContent = ContentEntry(
              id: generateId(),
              ownerId: user.id,
              ownerName: user.username,
              ownerRole: user.role,
              kind: sourceContent.kind,
              title: sourceContent.title,
              description: sourceContent.description,
              visibility: 'classes',
              classroomIds: classroomIds,
              preview: Map<String, dynamic>.from(sourceContent.preview),
              metadata: Map<String, dynamic>.from(sourceContent.metadata),
              teacherGenerated: sourceContent.teacherGenerated,
              aiGenerated: sourceContent.aiGenerated,
              storyId: importedStory.id,
            );
            store.contents.add(clonedContent);
            metadata
              ..['contentId'] = clonedContent.id
              ..['sourceContentId'] = originalContentId;
            if (!metadata.containsKey('fileUrl')) {
              final previewUrl = clonedContent.preview['fileUrl'] as String?;
              if (previewUrl != null && previewUrl.isNotEmpty) {
                metadata['fileUrl'] = previewUrl;
              }
            }
            if (!metadata.containsKey('fileName')) {
              final name = clonedContent.metadata['fileName'] as String?;
              if (name != null && name.isNotEmpty) {
                metadata['fileName'] = name;
              } else {
                metadata['fileName'] = clonedContent.title;
              }
            }
          } else {
            metadata.remove('contentId');
          }
        }

        stepPayload
          ..['preview'] = preview
          ..['metadata'] = metadata;

        clonedSteps.add(
          StoryStep(
            kind: step.kind,
            label: step.label,
            summary: step.summary,
            payload: stepPayload,
            completed: step.completed,
          ),
        );
      }

      importedStory.steps = clonedSteps;
      store.stories.add(importedStory);
      await Future.wait([store.saveStories(), store.saveContents()]);
      return _sendJson(request, {'story': _serializeStory(importedStory)});
    }

    return _sendNotFound(request);
  }

  List<StoryStep> _buildDefaultStorySteps(String? theme) {
    String normalizedTheme = theme?.isNotEmpty == true ? theme!.trim() : '课堂主题';
    return [
      StoryStep(
        kind: 'lesson_plan',
        label: '教案设计',
        summary: '$normalizedTheme 的课堂节奏，以故事开场、探索、共创结尾为框架。',
        payload: {
          'preview': <String, dynamic>{},
          'metadata': <String, dynamic>{},
        },
      ),
      StoryStep(
        kind: 'background_image',
        label: '教学背景图',
        summary: '生成可投影或打印的班级背景图，让孩子沉浸在主题故事里。',
        payload: {
          'preview': <String, dynamic>{},
          'metadata': <String, dynamic>{},
        },
      ),
      StoryStep(
        kind: 'video',
        label: '开场动画',
        summary: '30秒引导孩子进入主题的动画片段，营造情境。',
        payload: {
          'preview': <String, dynamic>{},
          'metadata': <String, dynamic>{},
        },
      ),
      StoryStep(
        kind: 'music',
        label: '背景音乐',
        summary: '轻柔伴奏或节奏练习音乐，配合课堂关键环节。',
        payload: {
          'preview': <String, dynamic>{},
          'metadata': <String, dynamic>{},
        },
      ),
    ];
  }

  Json _serializeStory(Story story) {
    return {
      'id': story.id,
      'teacherId': story.teacherId,
      'classroomIds': story.classroomIds,
      'title': story.title,
      'theme': story.theme,
      'status': story.status,
      'createdAt': story.createdAt.toIso8601String(),
      'steps': story.steps.map((step) => step.toJson()).toList(),
      if (story.metadata.isNotEmpty) 'metadata': story.metadata,
    };
  }

  Future<void> _handleFileUpload(HttpRequest request, User user) async {
    try {
      final uploadsDir = Directory('${store.storageDir.path}/uploads');
      if (!await uploadsDir.exists()) {
        await uploadsDir.create(recursive: true);
      }

      final boundary = request.headers.contentType?.parameters['boundary'];
      if (boundary == null) {
        return _sendError(request, '无效的文件上传格式', status: HttpStatus.badRequest);
      }

      final transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(request).toList();

      String? title;
      String kind = 'image';
      String description = '';
      String visibility = 'classes';
      List<String> classroomIds = <String>[];
      bool teacherGenerated = false;
      bool aiGenerated = false;
      String? storyId;
      Map<String, dynamic> metadata = <String, dynamic>{};
      Map<String, dynamic> preview = <String, dynamic>{};
      File? storedFile;
      String? originalFileName;
      String? storedFileName;
      String? mimeType;
      int fileSize = 0;

      for (final part in parts) {
        final disposition = part.headers['content-disposition'];
        if (disposition == null) continue;
        final fieldName = _extractDispositionValue(disposition, 'name');
        if (fieldName == null) continue;

        if (fieldName == 'file') {
          final rawFileName =
              _extractDispositionValue(disposition, 'filename') ?? 'upload.bin';
          originalFileName = rawFileName;
          final sanitizedFileName = _sanitizeFileName(rawFileName);
          final extension = _fileExtension(sanitizedFileName);
          final uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_${generateId(6)}$extension';
          final target = File('${uploadsDir.path}/$uniqueFileName');
          final sink = target.openWrite();
          var written = 0;
          await for (final data in part) {
            written += data.length;
            sink.add(data);
          }
          await sink.close();

          fileSize = written;
          storedFile = target;
          storedFileName = uniqueFileName;
          mimeType = lookupMimeType(target.path) ??
              part.headers['content-type'] ??
              'application/octet-stream';
          metadata['size'] = written;
          metadata['mimeType'] = mimeType;
        } else {
          final rawValue = await part.transform(utf8.decoder).join();
          final value = rawValue.trim();
          switch (fieldName) {
            case 'title':
              if (value.isNotEmpty) title = value;
              break;
            case 'kind':
              if (value.isNotEmpty) kind = value;
              break;
            case 'description':
              description = value;
              break;
            case 'visibility':
              if (value.isNotEmpty) visibility = value;
              break;
            case 'classroomIds':
              classroomIds = _parseClassroomIds(value);
              break;
            case 'teacherGenerated':
              teacherGenerated = _parseBool(value);
              break;
            case 'aiGenerated':
              aiGenerated = _parseBool(value);
              break;
            case 'storyId':
              if (value.isNotEmpty) storyId = value;
              break;
            case 'metadata':
              final parsedMetadata = _tryDecodeJson(value);
              if (parsedMetadata is Map<String, dynamic>) {
                metadata.addAll(parsedMetadata);
              }
              break;
            case 'preview':
              final parsedPreview = _tryDecodeJson(value);
              if (parsedPreview is Map<String, dynamic>) {
                preview.addAll(parsedPreview);
              }
              break;
          }
        }
      }

      if (storedFile == null || storedFileName == null) {
        return _sendError(request, '未找到上传的文件', status: HttpStatus.badRequest);
      }

      if (visibility == 'classes' && classroomIds.isEmpty) {
        return _sendError(request, '请选择可见的班级', status: HttpStatus.badRequest);
      }

      final normalizedTitle = title?.trim();
      final normalizedOriginal = originalFileName?.trim();
      final resolvedTitle =
          (normalizedTitle != null && normalizedTitle.isNotEmpty)
              ? normalizedTitle
              : (normalizedOriginal != null && normalizedOriginal.isNotEmpty
                  ? normalizedOriginal
                  : '未命名作品');
      final fileUrl = '/api/uploads/$storedFileName';

      metadata.addAll({
        'uploadedFile': true,
        'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        'originalFileName': originalFileName ?? storedFileName,
        'fileName': storedFileName,
        'fileUrl': fileUrl,
        'size': fileSize,
        if (mimeType != null) 'mimeType': mimeType,
      });

      final uploadPreview = _previewForUpload(
        kind: kind,
        fileUrl: fileUrl,
        fileName: originalFileName ?? storedFileName,
        mimeType: mimeType,
      );
      preview = {
        ...uploadPreview,
        ...preview,
      };

      final entry = ContentEntry(
        id: generateId(),
        ownerId: user.id,
        ownerName: user.username,
        ownerRole: user.role,
        kind: kind,
        title: resolvedTitle,
        description: description,
        visibility: visibility,
        classroomIds: classroomIds,
        preview: preview,
        metadata: metadata,
        storyId: storyId,
        teacherGenerated: teacherGenerated,
        aiGenerated: aiGenerated,
      );

      store.contents.add(entry);
      await store.saveContents();

      return _sendJson(
          request, {'content': _serializeContent(entry, viewer: user)});
    } catch (error, stackTrace) {
      stderr.writeln('文件上传失败: $error');
      stderr.writeln(stackTrace);
      return _sendError(request, '文件上传失败: $error',
          status: HttpStatus.internalServerError);
    }
  }

  Future<void> _handleUploads(HttpRequest request, List<String> path) async {
    if (path.isEmpty) {
      return _sendError(request, '文件路径不能为空', status: HttpStatus.badRequest);
    }

    final relativePath = path.join('/');
    if (relativePath.contains('..')) {
      return _sendError(request, '非法的文件路径', status: HttpStatus.badRequest);
    }

    final uploadsDir = Directory('${store.storageDir.path}/uploads');
    final file = File('${uploadsDir.path}/$relativePath');

    if (!await file.exists()) {
      return _sendError(request, '文件不存在', status: HttpStatus.notFound);
    }

    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.parse(mimeType)
        ..headers.set('Cache-Control', 'public, max-age=3600');

      await file.openRead().pipe(request.response);
    } catch (error, stackTrace) {
      stderr.writeln('读取上传文件失败: $error');
      stderr.writeln(stackTrace);
      return _sendError(request, '文件读取失败: $error',
          status: HttpStatus.internalServerError);
    }
  }

  String? _extractDispositionValue(String disposition, String key) {
    final match = RegExp('$key="([^"]*)"').firstMatch(disposition);
    return match?.group(1);
  }

  String _sanitizeFileName(String input) {
    final replaced = input.replaceAll(RegExp(r'[^\w\.-]'), '_');
    return replaced.isEmpty ? 'upload.bin' : replaced;
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex);
  }

  List<String> _parseClassroomIds(String raw) {
    if (raw.trim().isEmpty) return <String>[];
    final decoded = _tryDecodeJson(raw);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString())
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool _parseBool(String raw) {
    switch (raw.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }

  dynamic _tryDecodeJson(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _previewForUpload({
    required String kind,
    required String fileUrl,
    required String fileName,
    String? mimeType,
  }) {
    final normalizedKind = kind.toLowerCase();
    final mime = mimeType?.toLowerCase() ?? '';

    if (normalizedKind == 'image' || mime.startsWith('image/')) {
      return {
        'type': 'user_upload',
        'subtype': 'image',
        'imageUrl': fileUrl,
        'fileUrl': fileUrl,
        'fileName': fileName,
      };
    }
    if (normalizedKind == 'video' || mime.startsWith('video/')) {
      return {
        'type': 'user_upload',
        'subtype': 'video',
        'videoUrl': fileUrl,
        'fileUrl': fileUrl,
        'fileName': fileName,
      };
    }
    if (normalizedKind == 'music' ||
        normalizedKind == 'audio' ||
        mime.startsWith('audio/')) {
      return {
        'type': 'user_upload',
        'subtype': 'audio',
        'audioUrl': fileUrl,
        'fileUrl': fileUrl,
        'fileName': fileName,
      };
    }
    return {
      'type': 'user_upload',
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }

  Future<void> _handleContent(HttpRequest request, List<String> path) async {
    final user = authManager.authenticate(request);
    if (user == null) {
      return _sendUnauthorized(request);
    }

    if (request.method == 'POST' && path.isEmpty) {
      // 检查是否为文件上传请求
      final contentType = request.headers.contentType;
      if (contentType?.mimeType == 'multipart/form-data') {
        return await _handleFileUpload(request, user);
      }

      // 处理普通JSON请求
      final payload = await _readJson(request);
      final title = (payload['title'] as String?)?.trim();
      final kind = (payload['kind'] as String?)?.trim();
      if (title == null || title.isEmpty) {
        return _sendError(request, '作品标题不能为空', status: HttpStatus.badRequest);
      }
      if (kind == null || kind.isEmpty) {
        return _sendError(request, '作品类型不能为空', status: HttpStatus.badRequest);
      }
      final description = (payload['description'] as String?)?.trim() ?? '';
      final visibility =
          (payload['visibility'] as String?)?.trim() ?? 'classes';
      final classroomIds = (payload['classroomIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((id) => id.isNotEmpty)
          .toList();
      final preview =
          (payload['preview'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final metadata =
          (payload['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final storyId = (payload['storyId'] as String?)?.trim();
      final teacherGenerated = payload['teacherGenerated'] == true;
      final aiGenerated = payload['aiGenerated'] == true;

      if (visibility == 'classes' && classroomIds.isEmpty) {
        return _sendError(request, '请选择可见的班级', status: HttpStatus.badRequest);
      }

      final entry = ContentEntry(
        id: generateId(),
        ownerId: user.id,
        ownerName: user.username,
        ownerRole: user.role,
        kind: kind,
        title: title,
        description: description,
        visibility: visibility,
        classroomIds: classroomIds,
        preview: preview,
        metadata: metadata,
        storyId: storyId,
        teacherGenerated: teacherGenerated,
        aiGenerated: aiGenerated,
      );
      store.contents.add(entry);
      await store.saveContents();
      return _sendJson(
          request, {'content': _serializeContent(entry, viewer: user)});
    }

    if (request.method == 'GET' && path.isNotEmpty && path.first == 'feed') {
      final scope = request.uri.queryParameters['scope'] ?? 'classes';
      final classId = request.uri.queryParameters['classId'];
      final category = request.uri.queryParameters['kind'];

      Iterable<ContentEntry> entries = store.contents;
      if (category != null && category.isNotEmpty) {
        entries = entries.where((entry) => entry.kind == category);
      }
      if (scope == 'global') {
        entries = entries.where((entry) => entry.visibility == 'global');
      } else if (scope == 'classes') {
        final relevantClassIds = <String>[];
        if (user.isTeacher) {
          relevantClassIds.addAll(user.managedClassroomIds);
        } else if (user.joinedClassroomId != null) {
          relevantClassIds.add(user.joinedClassroomId!);
        }
        if (classId != null && classId.isNotEmpty) {
          relevantClassIds
            ..clear()
            ..add(classId);
        }
        entries = entries.where(
          (entry) {
            if (relevantClassIds.isEmpty) {
              return entry.ownerId == user.id;
            }
            return entry.classroomIds.any((id) => relevantClassIds.contains(id));
          },
        );
      }

      final items = entries
          .map((entry) => _serializeContent(entry, viewer: user))
          .toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'] as String? ?? '') ??
              DateTime.now();
          final dateB = DateTime.tryParse(b['createdAt'] as String? ?? '') ??
              DateTime.now();
          return dateB.compareTo(dateA);
        });

      return _sendJson(request, {'items': items});
    }

    if (request.method == 'POST' && path.length == 2 && path[1] == 'like') {
      final contentId = path.first;
      final entry = store.contents.firstWhere(
        (c) => c.id == contentId,
        orElse: () => ContentEntry(
          id: '',
          ownerId: '',
          ownerName: '',
          ownerRole: '',
          kind: '',
          title: '',
          description: '',
          visibility: 'global',
          classroomIds: const [],
        ),
      );
      if (entry.id.isEmpty) {
        return _sendError(request, '作品不存在', status: HttpStatus.notFound);
      }
      if (entry.likeUserIds.contains(user.id)) {
        entry.likeUserIds.remove(user.id);
      } else {
        entry.likeUserIds.add(user.id);
      }
      await store.saveContents();
      return _sendJson(
          request, {'content': _serializeContent(entry, viewer: user)});
    }

    if (request.method == 'POST' && path.length == 2 && path[1] == 'comment') {
      final contentId = path.first;
      final entry = store.contents.firstWhere(
        (c) => c.id == contentId,
        orElse: () => ContentEntry(
          id: '',
          ownerId: '',
          ownerName: '',
          ownerRole: '',
          kind: '',
          title: '',
          description: '',
          visibility: 'global',
          classroomIds: const [],
        ),
      );
      if (entry.id.isEmpty) {
        return _sendError(request, '作品不存在', status: HttpStatus.notFound);
      }
      final payload = await _readJson(request);
      final content = (payload['content'] as String?)?.trim();
      if (content == null || content.isEmpty) {
        return _sendError(request, '评论内容不能为空', status: HttpStatus.badRequest);
      }
      final comment = ContentComment(
        id: generateId(),
        userId: user.id,
        username: user.username,
        content: content,
      );
      entry.comments.add(comment);
      await store.saveContents();
      return _sendJson(
          request, {'content': _serializeContent(entry, viewer: user)});
    }

    if (request.method == 'DELETE' && path.length == 1) {
      final contentId = path.first;
      final index =
          store.contents.indexWhere((content) => content.id == contentId);
      if (index == -1) {
        return _sendError(request, '作品不存在', status: HttpStatus.notFound);
      }
      final entry = store.contents[index];
      final isOwner = entry.ownerId == user.id;
      final managesClass = user.isTeacher &&
          entry.classroomIds
              .any((id) => user.managedClassroomIds.contains(id));
      final canDelete = (user.isTeacher && (isOwner || managesClass)) ||
          (!user.isTeacher && isOwner);
      if (!canDelete) {
        return _sendError(request, '无权删除该作品', status: HttpStatus.forbidden);
      }

      store.contents.removeAt(index);
      await _deleteContentFiles(entry);
      await store.saveContents();
      return _sendJson(request, {'success': true});
    }

    return _sendNotFound(request);
  }

  Json _serializeContent(ContentEntry entry, {required User viewer}) {
    final liked = entry.likeUserIds.contains(viewer.id);
    return {
      'id': entry.id,
      'ownerId': entry.ownerId,
      'title': entry.title,
      'description': entry.description,
      'kind': entry.kind,
      'visibility': entry.visibility,
      'classroomIds': entry.classroomIds,
      'preview': entry.preview,
      'metadata': entry.metadata,
      'likes': entry.likeCount,
      'comments': entry.comments.length,
      'isLiked': liked,
      'ownerName': entry.ownerName,
      'ownerRole': entry.ownerRole,
      'teacherGenerated': entry.teacherGenerated,
      'aiGenerated': entry.aiGenerated,
      if (entry.storyId != null) 'storyId': entry.storyId,
      'createdAt': entry.createdAt.toIso8601String(),
      'commentDetails': entry.comments
          .map(
            (c) => {
              'id': c.id,
              'username': c.username,
              'content': c.content,
              'createdAt': c.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  Future<void> _handleShowcase(HttpRequest request, List<String> path) async {
    if (request.method == 'GET' && path.isNotEmpty && path.first == 'top') {
      final items = _dailyTopItems();
      return _sendJson(request, {'items': items});
    }
    if (request.method == 'GET' &&
        path.isNotEmpty &&
        path.first == 'categories') {
      final categories = <String, int>{};
      for (final entry in store.contents) {
        categories.update(entry.kind, (value) => value + 1, ifAbsent: () => 1);
      }
      final serialized = categories.entries
          .map((entry) => {
                'id': entry.key,
                'name': _kindDisplay(entry.key),
                'count': entry.value,
              })
          .toList();
      return _sendJson(request, {'categories': serialized});
    }
    if (request.method == 'GET' && path.isNotEmpty && path.first == 'items') {
      final viewer = authManager.authenticate(request);
      final queryKind = request.uri.queryParameters['category'];
      Iterable<ContentEntry> entries = store.contents;
      if (queryKind != null && queryKind.isNotEmpty && queryKind != 'all') {
        entries = entries.where((entry) => entry.kind == queryKind);
      }
      final result = entries
          .map(
            (entry) => _serializeContent(
              entry,
              viewer:
                  viewer ?? User(id: '', username: '', password: '', role: ''),
            ),
          )
          .toList();
      return _sendJson(request, {'items': result});
    }
    return _sendNotFound(request);
  }

  String _kindDisplay(String kind) {
    switch (kind) {
      case 'image':
        return '妙手画坊';
      case 'music':
        return '旋律工坊';
      case 'video':
        return '光影剧场';
      case 'lesson':
        return '教案';
      default:
        return kind;
    }
  }

  List<Json> _dailyTopItems() {
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final entries = store.contents
        .where((entry) => entry.createdAt.isAfter(startOfDay))
        .toList()
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return entries.take(3).map((entry) {
      return {
        'id': entry.id,
        'title': entry.title,
        'ownerName': entry.ownerName,
        'likes': entry.likeCount,
        'kind': entry.kind,
        'createdAt': entry.createdAt.toIso8601String(),
      };
    }).toList();
  }

  Future<void> _deleteContentFiles(ContentEntry entry) async {
    final urls = <String>{};

    void collect(dynamic value) {
      if (value is String && _isUploadUrl(value)) {
        urls.add(value);
      } else if (value is Map) {
        for (final element in value.values) {
          collect(element);
        }
      } else if (value is Iterable) {
        for (final element in value) {
          collect(element);
        }
      }
    }

    collect(entry.preview);
    collect(entry.metadata);

    for (final url in urls) {
      await _deleteUploadedFile(url);
    }
  }

  bool _isUploadUrl(String url) => url.contains('/api/uploads/');

  Future<void> _deleteUploadedFile(String url) async {
    final relative = _uploadsRelativePath(url);
    if (relative == null || relative.isEmpty) return;
    final uploadsDir = Directory('${store.storageDir.path}/uploads');
    final file = File('${uploadsDir.path}/$relative');
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // ignore deletion errors
      }
    }
  }

  String? _uploadsRelativePath(String url) {
    const marker = '/api/uploads/';
    final index = url.indexOf(marker);
    if (index == -1) return null;
    return url.substring(index + marker.length);
  }

  Future<Json> _readJson(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    if (content.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('请求体需要是 JSON 对象');
  }

  void _applyCors(HttpRequest request) {
    request.response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..set(HttpHeaders.accessControlAllowHeadersHeader,
          'origin, content-type, accept, authorization')
      ..set(HttpHeaders.accessControlAllowMethodsHeader,
          'GET, POST, PUT, DELETE, OPTIONS');
  }

  Future<void> _sendJson(HttpRequest request, Json data,
      {int status = HttpStatus.ok}) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(data));
    await request.response.close();
  }

  Future<void> _sendError(HttpRequest request, String message,
      {int status = HttpStatus.internalServerError}) async {
    await _sendJson(request, {'error': message}, status: status);
  }

  Future<void> _sendUnauthorized(HttpRequest request) => _sendError(
        request,
        '需要登录',
        status: HttpStatus.unauthorized,
      );

  Future<void> _sendNotFound(HttpRequest request) => _sendError(
        request,
        '接口未找到',
        status: HttpStatus.notFound,
      );
}
