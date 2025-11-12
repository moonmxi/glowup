import 'package:flutter/material.dart';

import '../models/classroom.dart';
import '../models/teacher_story.dart';
import '../services/app_api_service.dart';
import 'auth_state.dart';

class ClassroomState extends ChangeNotifier {
  ClassroomState(this._auth);

  AuthState _auth;
  List<TeacherStory> _stories = [];
  bool _isLoading = false;
  String? _error;

  AuthState get auth => _auth;
  List<ClassroomInfo> get classrooms => _auth.classrooms;
  ClassroomInfo? get classroom => _auth.classroom;
  List<TeacherStory> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canManageStories => _auth.user?.isTeacher ?? false;

  void updateAuth(AuthState auth) {
    if (!identical(_auth, auth)) {
      _auth = auth;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      _auth.refresh(),
      refreshStories(),
    ]);
  }

  Future<void> refreshStories() async {
    if (_auth.token == null || !canManageStories) {
      _stories = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      final data = await AppApiService.listStories(_auth.token!);
      final storiesJson = data['stories'] as List<dynamic>? ?? [];
      _stories = storiesJson
          .whereType<Map<String, dynamic>>()
          .map(TeacherStory.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<TeacherStory?> createStory({
    required String title,
    required List<String> classroomIds,
    String? theme,
  }) async {
    if (_auth.token == null || !canManageStories) {
      _error = '未登录或无权限';
      notifyListeners();
      return null;
    }
    try {
      final response = await AppApiService.createStory(
        token: _auth.token!,
        title: title,
        classroomIds: classroomIds,
        theme: theme,
      );
      final storyJson = response['story'] as Map<String, dynamic>?;
      if (storyJson != null) {
        final story = TeacherStory.fromJson(storyJson);
        _stories = [story, ..._stories];
        _error = null;
        notifyListeners();
        return story;
      }
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
    return null;
  }

  Future<TeacherStory?> updateStory({
    required String storyId,
    String? title,
    String? theme,
    String? status,
    List<StoryStepModel>? steps,
    Map<String, dynamic>? metadata,
  }) async {
    if (_auth.token == null || !canManageStories) {
      return null;
    }
    try {
      final payload = <String, dynamic>{
        if (title != null) 'title': title,
        if (theme != null) 'theme': theme,
        if (status != null) 'status': status,
        if (steps != null) 'steps': steps.map((step) => step.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };
      final response = await AppApiService.updateStory(
        token: _auth.token!,
        storyId: storyId,
        data: payload,
      );
      final storyJson = response['story'] as Map<String, dynamic>?;
      if (storyJson != null) {
        final updated = TeacherStory.fromJson(storyJson);
        _stories = _stories
            .map((story) => story.id == storyId ? updated : story)
            .toList();
        _error = null;
        notifyListeners();
        return updated;
      }
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
    return null;
  }

  Future<bool> deleteStory(String storyId) async {
    if (_auth.token == null || !canManageStories) {
      _error = '未登录或无权限';
      notifyListeners();
      return false;
    }
    try {
      await AppApiService.deleteStory(token: _auth.token!, storyId: storyId);
      _stories = _stories.where((story) => story.id != storyId).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createClassroom(String name) async {
    if (_auth.token == null || !(_auth.user?.isTeacher ?? false)) {
      _error = '未登录或无权限';
      notifyListeners();
      return false;
    }
    try {
      await AppApiService.createClassroom(token: _auth.token!, name: name);
      await _auth.refresh();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClassroom(String classroomId) async {
    if (_auth.token == null || !(_auth.user?.isTeacher ?? false)) {
      _error = '未登录或无权限';
      notifyListeners();
      return false;
    }
    try {
      await AppApiService.deleteClassroom(
        token: _auth.token!,
        classroomId: classroomId,
      );
      await _auth.refresh();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinClassroom(String code) async {
    if (_auth.token == null || !(_auth.user?.isStudent ?? false)) {
      _error = '请以学生身份登录';
      notifyListeners();
      return false;
    }
    try {
      await AppApiService.joinClassroom(token: _auth.token!, code: code);
      await _auth.refresh();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
