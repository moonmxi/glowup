import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoryCacheService {
  StoryCacheService._internal();

  static final StoryCacheService _instance = StoryCacheService._internal();

  factory StoryCacheService() => _instance;

  final Map<String, Map<String, dynamic>> _memory = {};
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    final existing = _prefs;
    if (existing != null) {
      return existing;
    }
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  String _prefsKey(String storyId) {
    final sanitized = storyId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'story_cache_$sanitized';
  }

  Map<String, dynamic>? peek(String storyId) {
    final cached = _memory[storyId];
    if (cached == null) return null;
    return _clone(cached);
  }

  Future<Map<String, dynamic>?> load(String storyId) async {
    final prefs = await _ensurePrefs();
    try {
      final raw = prefs.getString(_prefsKey(storyId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final casted = decoded.cast<String, dynamic>();
          _memory[storyId] = casted;
          return _clone(casted);
        }
      }
    } catch (error) {
      debugPrint('Failed to load story cache for $storyId: $error');
    }
    final inMemory = _memory[storyId];
    return inMemory == null ? null : _clone(inMemory);
  }

  Future<void> save(String storyId, Map<String, dynamic> payload) async {
    final cloned = _clone(payload);
    _memory[storyId] = cloned;
    try {
      final prefs = await _ensurePrefs();
      await prefs.setString(_prefsKey(storyId), jsonEncode(cloned));
    } catch (error) {
      debugPrint('Failed to persist story cache for $storyId: $error');
    }
  }

  Future<void> clear(String storyId) async {
    _memory.remove(storyId);
    try {
      final prefs = await _ensurePrefs();
      await prefs.remove(_prefsKey(storyId));
    } catch (error) {
      debugPrint('Failed to clear story cache for $storyId: $error');
    }
  }

  Map<String, dynamic> _clone(Map<String, dynamic> source) {
    try {
      return (jsonDecode(jsonEncode(source)) as Map<String, dynamic>)
          .cast<String, dynamic>();
    } catch (_) {
      return Map<String, dynamic>.from(source);
    }
  }
}
