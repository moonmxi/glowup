import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/classroom.dart';
import '../models/user_profile.dart';
import '../services/app_api_service.dart';

class AuthState extends ChangeNotifier {
  AppUser? _user;
  ClassroomInfo? _classroom;
  List<ClassroomInfo> _classrooms = [];
  UserProfile? _profile;
  String? _token;
  String? _error;
  bool _isLoading = false;
  bool _isInitialized = false;

  AppUser? get user => _user;
  ClassroomInfo? get classroom => _classroom;
  List<ClassroomInfo> get classrooms => List.unmodifiable(_classrooms);
  UserProfile? get profile => _profile;
  String? get token => _token;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _user != null;

  // 持久化存储的键名
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _classroomKey = 'auth_classroom';
  static const String _classroomsKey = 'auth_classrooms';
  static const Duration _networkTimeout = Duration(seconds: 8);

  /// 初始化认证状态，从本地存储恢复登录状态
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true, silent: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token != null) {
        _token = token;
        
        // 尝试从本地存储恢复用户信息
        final userJson = prefs.getString(_userKey);
        final classroomJson = prefs.getString(_classroomKey);
        final classroomsJson = prefs.getString(_classroomsKey);
        
        if (userJson != null) {
          try {
            final userData = Map<String, dynamic>.from(
              jsonDecode(userJson)
            );
            _user = AppUser.fromJson(userData);
          } catch (_) {
            // 如果解析失败，清除无效数据
            await _clearStoredAuth();
          }
        }
        
        if (classroomJson != null) {
          try {
            final classroomData = Map<String, dynamic>.from(
              jsonDecode(classroomJson)
            );
            _classroom = ClassroomInfo.fromJson(classroomData);
          } catch (_) {
            // 忽略解析错误
          }
        }
        
        if (classroomsJson != null) {
          try {
            final classroomsData = List<dynamic>.from(
              jsonDecode(classroomsJson)
            );
            _classrooms = classroomsData
                .whereType<Map<String, dynamic>>()
                .map(ClassroomInfo.fromJson)
                .toList();
          } catch (_) {
            // 忽略解析错误
          }
        }
        
        // 验证token有效性并刷新用户信息
        if (_user != null) {
          try {
            await _refreshUser(silent: true);
            await _refreshClassrooms(silent: true);
          } catch (_) {
            // 如果token无效，清除登录状态
            logout();
          }
        }
      }
    } catch (error) {
      _handleError(error, silent: true);
    } finally {
      _isInitialized = true;
      _setLoading(false, silent: true);
      notifyListeners();
    }
  }

  /// 清除存储的认证信息
  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
      prefs.remove(_classroomKey),
      prefs.remove(_classroomsKey),
    ]);
  }

  /// 保存认证信息到本地存储
  Future<void> _saveAuthToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
    
    if (_user != null) {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    }
    
    if (_classroom != null) {
      await prefs.setString(_classroomKey, jsonEncode(_classroom!.toJson()));
    }
    
    if (_classrooms.isNotEmpty) {
      final classroomsJson = _classrooms.map((c) => c.toJson()).toList();
      await prefs.setString(_classroomsKey, jsonEncode(classroomsJson));
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String role,
    String? classroomCode,
    String? classroomName,
  }) async {
    _setLoading(true);
    try {
      final result = await AppApiService.register(
        username: username,
        password: password,
        role: role,
        classroomCode: classroomCode,
        classroomName: classroomName,
      );
      if (result['token'] == null || result['user'] == null) {
        throw ApiException('注册接口返回数据不完整');
      }
      _applyAuthResult(result);
      _error = null;
      await _saveAuthToStorage();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await AppApiService.login(username: username, password: password);
      if (result['token'] == null || result['user'] == null) {
        throw ApiException('登录接口返回数据不完整');
      }
      _applyAuthResult(result);
      _error = null;
      unawaited(_refreshClassrooms(silent: true));
      await _saveAuthToStorage();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  Future<void> refresh() async {
    if (!isAuthenticated) {
      return;
    }
    _setLoading(true, silent: true);
    try {
      await Future.wait([
        _refreshUser(silent: true),
        _refreshClassrooms(silent: true),
      ]);
      _error = null;
    } catch (error) {
      _handleError(error, silent: true);
    } finally {
      _setLoading(false, silent: true);
      notifyListeners();
    }
  }

  void logout() async {
    _user = null;
    _classroom = null;
    _classrooms = [];
    _profile = null;
    _token = null;
    _error = null;
    await _clearStoredAuth();
    notifyListeners();
  }

  Future<void> _fetchUser() async {
    if (_token == null) return;
    final data = await AppApiService.fetchCurrentUser(_token!);
    _applyAuthResult(data, updateToken: false);
  }

  Future<void> _fetchClassrooms() async {
    if (_token == null) return;
    try {
      final data = await AppApiService.listClassrooms(_token!);
      final classesJson = data['classrooms'];
      final classroomJson = data['classroom'];
      if (classesJson is List) {
        _classrooms = classesJson
            .whereType<Map<String, dynamic>>()
            .map(ClassroomInfo.fromJson)
            .toList();
        if ((_user?.isTeacher ?? false) && _classrooms.isNotEmpty) {
          final current = _classroom;
          if (current != null) {
            final matched = _classrooms.firstWhere(
              (c) => c.id == current.id,
              orElse: () => _classrooms.first,
            );
            _classroom = matched;
          } else {
            _classroom = _classrooms.first;
          }
        }
      } else if (classroomJson is Map<String, dynamic>) {
        final info = ClassroomInfo.fromJson(classroomJson);
        _classroom = info;
        _classrooms = [info];
      }
    } catch (_) {
      // Classroom might not exist yet.
      _classrooms = [];
    }
  }

  Future<void> _refreshUser({bool silent = false}) async {
    if (_token == null) return;
    try {
      await _fetchUser().timeout(_networkTimeout);
    } on TimeoutException catch (error) {
      if (!silent) {
        _error = '获取用户信息超时，请稍后再试';
        notifyListeners();
      } else {
        debugPrint('AuthState: refresh user timeout: $error');
      }
    } catch (error) {
      if (!silent) {
        _handleError(error);
      } else {
        debugPrint('AuthState: refresh user failed: $error');
      }
    }
  }

  Future<void> _refreshClassrooms({bool silent = false}) async {
    if (_token == null) return;
    try {
      await _fetchClassrooms().timeout(_networkTimeout);
    } on TimeoutException catch (error) {
      if (!silent) {
        _error = '获取课堂信息超时，请稍后再试';
        notifyListeners();
      } else {
        debugPrint('AuthState: refresh classrooms timeout: $error');
      }
    } catch (error) {
      if (!silent) {
        _handleError(error);
      } else {
        debugPrint('AuthState: refresh classrooms failed: $error');
      }
    }
  }

  void _applyAuthResult(Map<String, dynamic> result, {bool updateToken = true}) {
    if (updateToken) {
      final token = result['token'] as String?;
      if (token != null) {
        _token = token;
      }
    }
    final userJson = result['user'] as Map<String, dynamic>?;
    final classroomJson = result['classroom'] as Map<String, dynamic>?;
    final classroomsJson = result['classrooms'] as List<dynamic>?;

    if (userJson != null) {
      _user = AppUser.fromJson(userJson);
    }
    if (classroomJson != null) {
      _classroom = ClassroomInfo.fromJson(classroomJson);
    }
    if (classroomsJson != null) {
      _classrooms = classroomsJson
          .whereType<Map<String, dynamic>>()
          .map(ClassroomInfo.fromJson)
          .toList();
    } else if (_classroom != null) {
      _classrooms = [_classroom!];
    } else {
      _classrooms = [];
    }
    if (_classrooms.isNotEmpty && _classroom == null) {
      _classroom = _classrooms.first;
    }
    if (_profile == null && _user != null) {
      _profile = _buildLocalProfile(_user!);
    }
  }

  UserProfile _buildLocalProfile(AppUser user) {
    final bio = user.isTeacher
        ? '课堂的引航人，让孩子们在故事中学会表达与倾听。'
        : '热爱艺术的小创作者，勇敢探索声音与色彩的世界。';
    return UserProfile.fromJson({
      'id': user.id,
      'userId': user.id,
      'username': user.username,
      'role': user.role,
      'bio': bio,
      'preferences': {
        'theme': 'light',
        'language': 'zh-CN',
        'notifications': {'push': true},
      },
      'stats': {
        'worksCreated': 0,
        'lessonsCompleted': 0,
        'pointsEarned': 0,
      },
    });
  }

  void _handleError(Object error, {bool silent = false}) {
    final message = error is ApiException ? error.message : error.toString();
    if (!silent) {
      _error = message;
    }
    _setLoading(false, silent: true);
    if (!silent) {
      notifyListeners();
    }
  }

  void _setLoading(bool value, {bool silent = false}) {
    _isLoading = value;
    if (!silent) {
      notifyListeners();
    }
  }
}
