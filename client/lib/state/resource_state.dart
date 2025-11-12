import 'dart:async';

import 'package:flutter/material.dart';

enum ResourceCategory {
  art('美术'),
  music('音乐'),
  wellbeing('心理关怀'),
  coding('编程启蒙'),
  offline('离线包');

  const ResourceCategory(this.label);
  final String label;
}

enum DownloadStatus { idle, queued, downloading, cached }

class ResourceBundle {
  ResourceBundle({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tag,
    required this.icon,
    required this.gradient,
    this.status = DownloadStatus.idle,
    this.progress = 0,
    this.addedToQueue = false,
  });

  final String id;
  final String title;
  final String description;
  final ResourceCategory category;
  final String tag;
  final IconData icon;
  final List<Color> gradient;
  final DownloadStatus status;
  final double progress;
  final bool addedToQueue;

  ResourceBundle copyWith({
    DownloadStatus? status,
    double? progress,
    bool? addedToQueue,
  }) {
    return ResourceBundle(
      id: id,
      title: title,
      description: description,
      category: category,
      tag: tag,
      icon: icon,
      gradient: gradient,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      addedToQueue: addedToQueue ?? this.addedToQueue,
    );
  }
}

class OfflinePackageInfo {
  OfflinePackageInfo({
    required this.totalSizeGb,
    required this.cachedGb,
    required this.autoUpdate,
  });

  final double totalSizeGb;
  final double cachedGb;
  final bool autoUpdate;

  double get progress => cachedGb / totalSizeGb;

  OfflinePackageInfo copyWith({
    double? totalSizeGb,
    double? cachedGb,
    bool? autoUpdate,
  }) {
    return OfflinePackageInfo(
      totalSizeGb: totalSizeGb ?? this.totalSizeGb,
      cachedGb: cachedGb ?? this.cachedGb,
      autoUpdate: autoUpdate ?? this.autoUpdate,
    );
  }
}

class ResourceLibraryState extends ChangeNotifier {
  ResourceLibraryState() {
    _bundles = [
      ResourceBundle(
        id: 'art_seasons',
        title: '四季颜色 · 美术',
        description: '分层任务卡 + 分步绘画模板 + 课堂照片示例',
        category: ResourceCategory.art,
        tag: '含离线 PPT',
        icon: Icons.palette,
        gradient: const [Color(0xFFFFD6A5), Color(0xFFFFADAD)],
      ),
      ResourceBundle(
        id: 'music_planet',
        title: '节奏星球 · 音乐',
        description: '节拍灯素材 + 哼唱示范 + 旋律任务卡',
        category: ResourceCategory.music,
        tag: '含 MIDI',
        icon: Icons.music_note,
        gradient: const [Color(0xFFA0C4FF), Color(0xFFBDB2FF)],
      ),
      ResourceBundle(
        id: 'mood_diary',
        title: '心情日记 · 心理',
        description: '心情环海报 + 引导语模板 + AI 回信范例',
        category: ResourceCategory.wellbeing,
        tag: '班级热力图',
        icon: Icons.favorite,
        gradient: const [Color(0xFFBDE0FE), Color(0xFFC8E7FF)],
      ),
      ResourceBundle(
        id: 'coding_grass',
        title: '小龟画草地 · 编程',
        description: 'Turtle 任务 JSON + 演示截图 + 学生作品卡',
        category: ResourceCategory.coding,
        tag: '参数示例',
        icon: Icons.code,
        gradient: const [Color(0xFFB9FBC0), Color(0xFFFFF3B0)],
      ),
      ResourceBundle(
        id: 'music_lullaby',
        title: '山谷摇篮曲 · 音乐',
        description: '乡野采风旋律 + 和声练习 + 节奏踩点',
        category: ResourceCategory.music,
        tag: '教学视频',
        icon: Icons.music_video,
        gradient: const [Color(0xFFFFE0FB), Color(0xFFB388FF)],
        status: DownloadStatus.cached,
        progress: 1,
      ),
      ResourceBundle(
        id: 'art_paper_cut',
        title: '剪纸故事 · 美术',
        description: '民俗剪纸模板 + 视频示范 + 评价表格',
        category: ResourceCategory.art,
        tag: '工作纸',
        icon: Icons.content_cut,
        gradient: const [Color(0xFFFFF3B0), Color(0xFFFFA69E)],
      ),
    ];
  }

  late List<ResourceBundle> _bundles;
  ResourceCategory _selectedCategory = ResourceCategory.art;
  final Map<String, Timer> _downloadTimers = {};

  ResourceCategory get selectedCategory => _selectedCategory;

  List<ResourceBundle> get filteredBundles => _bundles
      .where(
        (bundle) => _selectedCategory == ResourceCategory.offline
            ? bundle.status == DownloadStatus.cached
            : bundle.category == _selectedCategory,
      )
      .toList();

  OfflinePackageInfo _offlineInfo = OfflinePackageInfo(
    totalSizeGb: 1.2,
    cachedGb: 0.5,
    autoUpdate: true,
  );

  OfflinePackageInfo get offlineInfo => _offlineInfo;

  final List<Map<String, String>> promptKits = [
    {
      'title': '美术教案模板',
      'description': '教学目标、流程、分层任务结构化输出',
    },
    {
      'title': '两星一愿评价库',
      'description': '课堂点评与成长档案即用语句',
    },
    {
      'title': '心情回信语柄',
      'description': '共情-肯定-建议-约定四段式提示',
    },
    {
      'title': 'Turtle 参数解释',
      'description': '适合孩子理解的参数释义与动画建议',
    },
  ];

  void selectCategory(ResourceCategory category) {
    if (category == _selectedCategory) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void enqueueBundle(String id) {
    _bundles = _bundles
        .map(
          (bundle) => bundle.id == id
              ? bundle.copyWith(
                  addedToQueue: true,
                  status: bundle.status == DownloadStatus.cached
                      ? bundle.status
                      : DownloadStatus.queued,
                )
              : bundle,
        )
        .toList();
    notifyListeners();
  }

  void startDownload(String id) {
    final target = _bundles.firstWhere((b) => b.id == id);
    if (target.status == DownloadStatus.cached ||
        target.status == DownloadStatus.downloading) {
      return;
    }
    _bundles = _bundles
        .map(
          (bundle) => bundle.id == id
              ? bundle.copyWith(
                  status: DownloadStatus.downloading,
                  progress: 0.1,
                )
              : bundle,
        )
        .toList();
    notifyListeners();

    _downloadTimers[id]?.cancel();
    _downloadTimers[id] = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        final bundle =
            _bundles.firstWhere((element) => element.id == id);
        final nextProgress = (bundle.progress + 0.25).clamp(0.0, 1.0);
        if (nextProgress >= 1.0) {
          timer.cancel();
          _downloadTimers.remove(id);
          _bundles = _bundles
              .map(
                (item) => item.id == id
                    ? item.copyWith(
                        status: DownloadStatus.cached,
                        progress: 1.0,
                        addedToQueue: false,
                      )
                    : item,
              )
              .toList();
          notifyListeners();
          return;
        }
        _bundles = _bundles
            .map(
              (item) => item.id == id
                  ? item.copyWith(progress: nextProgress)
                  : item,
            )
            .toList();
        notifyListeners();
      },
    );
  }

  void updateOfflineAutoSync(bool value) {
    _offlineInfo = _offlineInfo.copyWith(autoUpdate: value);
    notifyListeners();
  }

  void syncOfflinePackage() {
    final remaining = _offlineInfo.totalSizeGb - _offlineInfo.cachedGb;
    if (remaining <= 0.01) return;
    final increment = (_offlineInfo.totalSizeGb * 0.15).clamp(0.0, remaining);
    _offlineInfo = _offlineInfo.copyWith(
      cachedGb: (_offlineInfo.cachedGb + increment)
          .clamp(0.0, _offlineInfo.totalSizeGb),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _downloadTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
