import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

String _extractContent(Map<String, dynamic> data) {
  final choices = data['choices'];
  if (choices is List && choices.isNotEmpty) {
    final first = choices.first;
    final message = first['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String) {
        return content.trim();
      }
      if (content is List) {
        final buffer = StringBuffer();
        for (final part in content) {
          if (part is Map && part['text'] is String) {
            buffer.write(part['text']);
          }
        }
        final text = buffer.toString();
        if (text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }
  }
  return data.toString();
}

class AiStoryAssetResult {
  AiStoryAssetResult({
    required this.summary,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
  })  : preview = preview ?? const <String, dynamic>{},
        metadata = metadata ?? const <String, dynamic>{};

  final String summary;
  final Map<String, dynamic> preview;
  final Map<String, dynamic> metadata;
}

class AiStoryWeaver {
  AiStoryWeaver({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AiStoryAssetResult> generateVideoStoryboard({
    required String theme,
  }) async {
    final text = await _chat([
  {
    'role': 'system',
    'content':
    '你是 GlowUp 小光，一位熟悉小学艺术课堂的脚本设计者。请严格输出 JSON，字段：summary（字符串）、segments（数组，元素需包含 scene 与 narration 字段，可选 cameraHint / musicCue）、ambientSound（字符串）、script（多行字符串，便于复制）。禁止输出 JSON 以外的任何字符，并确保镜头语言贴合 6-10 岁儿童、强调课堂价值观、动作清晰可视。',
  },
  {
    'role': 'user',
    'content':
    '请写一个 30 秒的课堂开场动画脚本，主题是“$theme”，需要 4-5 个镜头，让孩子在 6 秒内理解情境并保持互动感。请结合当日课堂目标与教师引导语，确保 segments 中依次描述画面、旁白与可能的镜头或音乐提示，只返回符合要求的 JSON。',
  },
    ]);
    final data = _tryDecodeJson(text);
    final segments = <Map<String, String>>[];
    final rawSegments = data['segments'];
    if (rawSegments is List) {
      for (final item in rawSegments) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final scene = _stringField(map, 'scene') ?? '';
          final narration = _stringField(map, 'narration') ?? '';
          final camera = _stringField(map, 'cameraHint') ?? '';
          final music = _stringField(map, 'musicCue') ?? '';
          if (scene.isEmpty && narration.isEmpty && camera.isEmpty && music.isEmpty) {
            continue;
          }
          segments.add({
            'scene': scene,
            'narration': narration,
            if (camera.isNotEmpty) 'cameraHint': camera,
            if (music.isNotEmpty) 'musicCue': music,
          });
        } else if (item != null) {
          final textValue = item.toString();
          if (textValue.trim().isEmpty) continue;
          final parts = textValue.split(RegExp(r'[｜|]'));
          final scene = parts.isNotEmpty ? parts.first.trim() : '';
          final narration = parts.length > 1 ? parts.sublist(1).join('｜').trim() : '';
          segments.add({
            'scene': scene,
            'narration': narration,
          });
        }
      }
    }
    final script = _stringField(data, 'script') ??
        (segments.isNotEmpty
            ? segments
                .map((segment) {
                  final scene = segment['scene'] ?? '';
                  final narration = segment['narration'] ?? '';
                  if (scene.isEmpty) return narration;
                  if (narration.isEmpty) return scene;
                  return '$scene\n旁白：$narration';
                })
                .whereType<String>()
                .where((line) => line.trim().isNotEmpty)
                .join('\n\n')
            : text);
    final ambient = _stringField(data, 'ambientSound') ?? '';
    final summary = _stringField(data, 'summary') ??
        '小光为“$theme”整理了${segments.isEmpty ? '一个' : '${segments.length}个'}镜头，帮助孩子迅速进入课堂情境。';
    return AiStoryAssetResult(
      summary: summary,
      preview: {
        'type': 'storyboard',
        'segments': segments,
        'ambient': ambient,
        'script': script,
      },
      metadata: {
        ...data,
        'segments': segments,
        'ambientSound': ambient,
        'script': script,
        'rawText': text,
      },
    );
  }

  Future<AiStoryAssetResult> generateMusicCue({
    required String theme,
  }) async {
    final text = await _chat([
  {
    'role': 'system',
    'content':
    '你是 GlowUp 小光，一位为小学课堂设计音乐的助手。输出必须是 JSON 对象，字段：summary（字符串）、tempo（字符串）、mode（字符串）、structure（数组，元素包含 label、duration、purpose 字段）、encouragement（字符串，写给老师的鼓励）。不要输出其它文字，并保证建议贴合小学课堂安全、便于教师操作。',
  },
  {
    'role': 'user',
    'content':
    '请为课堂主题“$theme”设计一段背景音乐方案，兼顾情绪引导与节奏练习，涵盖课堂导入、主体练习与收结环节。描述每段音乐的节奏能量变化、主要乐器以及适合的教学动作，只返回 JSON。',
  },
    ]);
    final data = _tryDecodeJson(text);
    final structureMaps = <Map<String, String>>[];
    final rawStructure = data['structure'];
    if (rawStructure is List) {
      for (final section in rawStructure) {
        if (section is Map) {
          final map = Map<String, dynamic>.from(section);
          final label = _stringField(map, 'label') ?? '';
          final duration = _stringField(map, 'duration') ?? '';
          final purpose = _stringField(map, 'purpose') ?? '';
          if (label.isEmpty && duration.isEmpty && purpose.isEmpty) {
            continue;
          }
          structureMaps.add({
            if (label.isNotEmpty) 'label': label,
            if (duration.isNotEmpty) 'duration': duration,
            if (purpose.isNotEmpty) 'purpose': purpose,
          });
        } else if (section != null) {
          final textValue = section.toString().trim();
          if (textValue.isNotEmpty) {
            structureMaps.add({'label': textValue});
          }
        }
      }
    }
    final structureLines = structureMaps
        .map((section) {
          final label = section['label'] ?? '';
          final duration = section['duration'];
          final purpose = section['purpose'];
          final buffer = StringBuffer();
          if (label.isNotEmpty) {
            buffer.write(label);
          }
          if (duration != null && duration.isNotEmpty) {
            buffer.write(buffer.isEmpty ? duration : '（$duration）');
          }
          if (purpose != null && purpose.isNotEmpty) {
            buffer.write(buffer.isEmpty ? purpose : '：$purpose');
          }
          return buffer.toString().trim();
        })
        .where((line) => line.isNotEmpty)
        .toList();
    final encouragement = _stringField(data, 'encouragement') ?? '';
    final summary = _stringField(data, 'summary') ??
        '小光为“$theme”设计了${structureMaps.isEmpty ? '一段' : '${structureMaps.length}段'}课堂音乐流程，配合节奏练习使用。';
    return AiStoryAssetResult(
      summary: summary,
      preview: {
        'type': 'music',
        'tempo': data['tempo'],
        'mode': data['mode'],
        'structure': structureMaps,
        'encouragement': encouragement,
      },
      metadata: {
        ...data,
        'structure': structureLines,
        'structureSegments': structureMaps,
        'encouragement': encouragement,
        'rawText': text,
      },
    );
  }

  Future<AiStoryAssetResult> generateColorReport({
    required List<String> colors,
    required String focus,
  }) async {
    final colorLine = colors.isEmpty ? '（未提供具体颜色）' : colors.join(', ');
    final text = await _chat([
  {
    'role': 'system',
    'content':
    '你是 GlowUp 小光，负责对孩子的美术作品进行色彩分析。输出 JSON，字段：summary、paletteAdvice（数组）、nextSteps（数组）、warmWords（字符串）。保持鼓励语气，切勿使用否定或评分语言。',
  },
  {
    'role': 'user',
    'content':
    '作品焦点是“$focus”，提取到的颜色有：$colorLine。请给出鼓励性的色彩点评，指出色彩搭配亮点与可尝试的小练习，并给老师家庭延伸建议，只返回 JSON。',
  },
    ]);
    final data = _tryDecodeJson(text);
    final paletteAdvice = _stringList(data, 'paletteAdvice');
    final nextSteps = _stringList(data, 'nextSteps');
    final summary = _stringField(data, 'summary') ??
        '小光针对“$focus”作品的主要色彩做了鼓励性点评，并给出课堂延伸建议。';
    return AiStoryAssetResult(
      summary: summary,
      preview: {
        'type': 'color_report',
        'palette': colors,
        'advice': paletteAdvice,
        'nextSteps': nextSteps,
      },
      metadata: {
        ...data,
        'rawText': text,
      },
    );
  }

  Future<AiStoryAssetResult> generateRhythmReport({
    required Duration duration,
    required List<double> beatEnergy,
    required List<double> pitchContour,
  }) async {
    final energyLine = beatEnergy.isEmpty
        ? '（无能量数据）'
        : beatEnergy.map((e) => e.toStringAsFixed(2)).join(', ');
    final pitchLine = pitchContour.isEmpty
        ? '（无音高数据）'
        : pitchContour.map((p) => p.toStringAsFixed(1)).join(', ');
    final text = await _chat([
  {
    'role': 'system',
    'content':
    '你是 GlowUp 小光，一位音乐课堂的节奏教练。输出 JSON，字段：summary、beatTips（数组）、pitchGuide（数组）、homePractice（字符串）。语言需兼具鼓励与操作性，避免评判。',
  },
  {
    'role': 'user',
    'content':
    '课堂录音时长 ${duration.inSeconds} 秒，节奏能量样本：$energyLine，音高轮廓：$pitchLine。请给孩子们易懂的反馈，包含课堂练习建议与课后巩固方法，只返回 JSON。',
  },
    ]);
    final data = _tryDecodeJson(text);
    final beatTips = _stringList(data, 'beatTips');
    final pitchGuide = _stringList(data, 'pitchGuide');
    final summary = _stringField(data, 'summary') ??
        '小光根据 ${duration.inSeconds} 秒课堂录音的节奏能量与音高走势，整理了鼓励与练习建议。';
    return AiStoryAssetResult(
      summary: summary,
      preview: {
        'type': 'rhythm_report',
        'beatTips': beatTips,
        'pitchGuide': pitchGuide,
        'duration': duration.inSeconds,
      },
      metadata: {
        ...data,
        'rawText': text,
      },
    );
  }

  Future<String> _chat(List<Map<String, dynamic>> messages) async {
    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 600,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('AI 生成失败: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractContent(data);
  }

  Map<String, dynamic> _tryDecodeJson(String text) {
    String trimmed = text.trim();
    Map<String, dynamic>? decoded;
    try {
      final direct = jsonDecode(trimmed);
      if (direct is Map<String, dynamic>) {
        decoded = direct;
      }
    } catch (_) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final candidate = trimmed.substring(start, end + 1);
        try {
          final nested = jsonDecode(candidate);
          if (nested is Map<String, dynamic>) {
            decoded = nested;
          }
        } catch (_) {
          // ignore
        }
      }
    }
    return decoded ?? {'raw': trimmed};
  }

  List<String> _stringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value.split(RegExp(r'[\n;,]+')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
    return const <String>[];
  }

  String? _stringField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }
}
