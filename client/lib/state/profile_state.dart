import 'package:flutter/material.dart';

enum AppLanguage { zh, en }

class ProfileState extends ChangeNotifier {
  AppLanguage _language = AppLanguage.zh;
  bool _largeText = false;
  bool _highContrast = false;

  AppLanguage get language => _language;
  bool get largeText => _largeText;
  bool get highContrast => _highContrast;
  Locale get locale =>
      _language == AppLanguage.zh ? const Locale('zh') : const Locale('en');
  double get textScaleFactor => _largeText ? 1.12 : 1.0;

  String get teacherName => '李老师';
  String get schoolName => '贵州 · 松树林乡中心小学';

  final List<String> badges = const [
    '美术课 1-4 年级',
    '心理小组辅导',
    'GlowUp 种子校',
  ];

  void updateLanguage(AppLanguage value) {
    if (value == _language) return;
    _language = value;
    notifyListeners();
  }

  void toggleLargeText(bool value) {
    if (value == _largeText) return;
    _largeText = value;
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    if (value == _highContrast) return;
    _highContrast = value;
    notifyListeners();
  }
}
