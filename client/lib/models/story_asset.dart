import 'package:flutter/foundation.dart';

enum StoryAssetStatus { idle, generating, ready, uploading, uploaded, failed }

class StoryAsset {
  StoryAsset({
    required this.kind,
    required this.label,
    this.summary,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
    this.status = StoryAssetStatus.idle,
    this.error,
  })  : preview = preview ?? const <String, dynamic>{},
        metadata = metadata ?? const <String, dynamic>{};

  final String kind;
  final String label;
  final String? summary;
  final Map<String, dynamic> preview;
  final Map<String, dynamic> metadata;
  final StoryAssetStatus status;
  final String? error;

  StoryAsset copyWith({
    String? summary,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
    StoryAssetStatus? status,
    String? error,
  }) {
    return StoryAsset(
      kind: kind,
      label: label,
      summary: summary ?? this.summary,
      preview: preview ?? this.preview,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'label': label,
      if (summary != null) 'summary': summary,
      'preview': preview,
      'metadata': metadata,
      'status': status.name,
      if (error != null) 'error': error,
    };
  }

  factory StoryAsset.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = StoryAssetStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => StoryAssetStatus.idle,
    );
    return StoryAsset(
      kind: (json['kind'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      summary: json['summary'] as String?,
      preview: Map<String, dynamic>.from(
        (json['preview'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      status: status,
      error: json['error'] as String?,
    );
  }
}

extension StoryAssetMapJson on Map<String, StoryAsset> {
  Map<String, dynamic> toJson() {
    return map((key, value) => MapEntry(key, value.toJson()));
  }
}

extension StoryAssetMapFromJson on Map<String, dynamic> {
  Map<String, StoryAsset> toStoryAssets() {
    return map((key, value) {
      if (value is Map<String, dynamic>) {
        return MapEntry(key, StoryAsset.fromJson(value));
      }
      debugPrint('Unexpected asset payload for $key: $value');
      return MapEntry(
        key,
        StoryAsset(kind: key, label: key.toUpperCase()),
      );
    });
  }
}

const List<Map<String, String>> kStoryAssetBlueprints = [
  {'kind': 'lesson_plan', 'label': '故事教案'},
  {'kind': 'background_image', 'label': 'AI 教学背景图'},
  {'kind': 'video', 'label': '开场动画脚本'},
  {'kind': 'music', 'label': '课堂音乐脚本'},
];
