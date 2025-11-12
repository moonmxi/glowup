import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../utils/download_helper.dart';

enum GenerationStatus { idle, submitting, running, completed, failed }

class GenerationError {
  const GenerationError(this.message);
  final String message;
}

class VideoGenerationState extends ChangeNotifier {
  VideoGenerationState({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  String prompt =
    '30秒课堂开场动画脚本：主题「晨光里的色彩冒险」，温暖的美术教室内，孩子们围坐圆桌准备创作。镜头从窗外阳光推入到孩子们的惊喜表情，配合柔和音乐、粉彩色调与细腻的粉尘漂浮感，营造充满希望与互动的氛围。';
  String orientation = 'portrait';
  String size = 'small';

  GenerationStatus status = GenerationStatus.idle;
  double progress = 0;
  String? taskId;
  String? remoteUrl;
  GenerationError? error;

  Timer? _pollingTimer;

  Future<void> generate({
    required String promptText,
    required String orientationValue,
    required String sizeValue,
  }) async {
    _cancelPolling();
    status = GenerationStatus.submitting;
    progress = 0;
    remoteUrl = null;
    error = null;
    notifyListeners();

    prompt = promptText;
    orientation = orientationValue;
    size = sizeValue;

    final payload = <String, dynamic>{
      'images': <String>[],
      'model': 'sora-2',
      'orientation': orientation,
      'prompt': prompt,
      'size': size,
    };

    try {
      final response = await _client.post(
        Uri.parse(AiApiConfig.videoSubmitUrl),
        headers: AiApiConfig.defaultHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        _setFailure('提交失败：${response.body}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final id = data['id']?.toString();
      if (id == null || id.isEmpty) {
        _setFailure('未返回任务 ID');
        return;
      }

      taskId = id;
      status = GenerationStatus.running;
      notifyListeners();

      _startPolling();
    } catch (e) {
      _setFailure('提交异常：$e');
    }
  }

  Future<String?> generateAndWait({
    required String promptText,
    required String orientationValue,
    required String sizeValue,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final completer = Completer<String?>();
    void listener() {
      if (status == GenerationStatus.completed) {
        if (!completer.isCompleted) {
          completer.complete(remoteUrl);
        }
      } else if (status == GenerationStatus.failed) {
        if (!completer.isCompleted) {
          completer.completeError(error ?? GenerationError('视频生成失败'));
        }
      }
    }

    addListener(listener);
    try {
      await generate(
        promptText: promptText,
        orientationValue: orientationValue,
        sizeValue: sizeValue,
      );
      if (status == GenerationStatus.completed && !completer.isCompleted) {
        completer.complete(remoteUrl);
      } else if (status == GenerationStatus.failed && !completer.isCompleted) {
        completer.completeError(error ?? GenerationError('视频生成失败'));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException catch (_) {
      _setFailure('视频生成超时，请稍后再试');
      final failure = error ?? GenerationError('视频生成超时，请稍后再试');
      throw failure;
    } finally {
      removeListener(listener);
    }
  }

  Future<bool> downloadVideo({String? fileName}) async {
    final url = remoteUrl;
    if (url == null || url.isEmpty) {
      error = const GenerationError('暂无可下载的视频，请先生成。');
      notifyListeners();
      return false;
    }
    final suggestedName = fileName ??
        'glowup_video_${taskId ?? DateTime.now().millisecondsSinceEpoch}.mp4';
    final success = await triggerUrlDownload(url, suggestedName);
    if (!success) {
      error = const GenerationError('浏览器暂不支持自动下载，请尝试右键视频另存为。');
      notifyListeners();
    }
    return success;
  }

  void prefillFromStory(String script) {
    prompt = script;
    notifyListeners();
  }

  void _startPolling() {
    final id = taskId;
    if (id == null) {
      return;
    }
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final uri = Uri.parse(AiApiConfig.videoFetchUrl)
            .replace(queryParameters: {'id': id});
        final response = await _client.get(
          uri,
          headers: AiApiConfig.defaultHeaders(json: false),
        );
        if (response.statusCode != 200) {
          return;
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statusValue = data['status']?.toString();
        final progressValue = data['progress'];
        if (progressValue is num) {
          progress = (progressValue.toDouble() / 100).clamp(0, 1);
        }
        notifyListeners();

        if (statusValue == 'completed') {
          remoteUrl = data['video_url']?.toString();
          status = GenerationStatus.completed;
          progress = 1;
          _cancelPolling();
          notifyListeners();
        } else if (statusValue == 'failed') {
          _setFailure('生成失败');
        }
      } catch (e) {
        _setFailure('查询失败：$e');
      }
    });
  }

  void _setFailure(String message) {
    status = GenerationStatus.failed;
    error = GenerationError(message);
    _cancelPolling();
    notifyListeners();
  }

  void reset() {
    _cancelPolling();
    status = GenerationStatus.idle;
    progress = 0;
    taskId = null;
    remoteUrl = null;
    error = null;
    notifyListeners();
  }

  void _cancelPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _cancelPolling();
    _client.close();
    super.dispose();
  }
}

class ImageGenerationState extends ChangeNotifier {
  ImageGenerationState({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  GenerationStatus status = GenerationStatus.idle;
  double progress = 0;
  String prompt =
    'A sun-washed elementary art studio right before class begins, featuring handcrafted posters about the theme, neatly arranged watercolor sets, soft textiles, and playful paper mobiles gently swaying in warm morning light.';
  String size = '1024x1024';
  String? remoteUrl;
  GenerationError? error;

  Timer? _progressTimer;

  Future<void> generateImage({
    required String promptText,
    required String sizeValue,
  }) async {
    status = GenerationStatus.submitting;
    progress = 0;
    error = null;
    remoteUrl = null;
    notifyListeners();

    prompt = promptText;
    size = sizeValue;

    _startProgressSimulation();

    final payload = {
      'model': 'dall-e-3',
      'prompt': prompt,
      'size': size,
      'sequential_image_generation': 'disabled',
      'stream': false,
      'response_format': 'url',
      'watermark': false,
    };

    try {
      final response = await _client.post(
        Uri.parse(AiApiConfig.imageGenerateUrl),
        headers: AiApiConfig.defaultHeaders(),
        body: jsonEncode(payload),
      );

      _cancelProgressTimer();

      if (response.statusCode != 200) {
        _setFailure('生成失败：${response.body}');
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['data'];
      if (list is List && list.isNotEmpty) {
        final first = list.first as Map<String, dynamic>;
        remoteUrl = first['url']?.toString();
        status = GenerationStatus.completed;
        progress = 1.0;
        notifyListeners();
        // No local caching on web; users can download via browser when needed.
      } else {
        _setFailure('未返回图片链接');
      }
    } catch (e) {
      _cancelProgressTimer();
      _setFailure('生成异常：$e');
    }
  }

  void _startProgressSimulation() {
    status = GenerationStatus.running;
    progress = 0.1;
    notifyListeners();

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (progress < 0.9) {
        progress += 0.1;
        notifyListeners();
      }
    });
  }

  void _cancelProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<bool> downloadImage({String? fileName}) async {
    final url = remoteUrl;
    if (url == null || url.isEmpty) {
      error = const GenerationError('暂无可下载的图片，请先生成。');
      notifyListeners();
      return false;
    }
    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('下载失败：${response.statusCode}');
      }
      final suggestedName = fileName ??
          'glowup_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final success = await triggerBytesDownload(
        response.bodyBytes,
        fileName: suggestedName,
        mimeType: response.headers['content-type'],
      );
      if (!success) {
        error = const GenerationError('浏览器暂不支持自动下载，请右键图片另存为。');
        notifyListeners();
      }
      return success;
    } catch (e) {
      error = GenerationError('图片下载失败：$e');
      notifyListeners();
      return false;
    }
  }

  void _setFailure(String message) {
    status = GenerationStatus.failed;
    error = GenerationError(message);
    _cancelProgressTimer();
    notifyListeners();
  }

  void reset() {
    status = GenerationStatus.idle;
    progress = 0;
    error = null;
    remoteUrl = null;
    _cancelProgressTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelProgressTimer();
    _client.close();
    super.dispose();
  }
}

const Object _noValue = Object();

class GeneratedTrack {
  const GeneratedTrack({
    required this.id,
    required this.title,
    this.audioUrl,
    this.imageUrl,
    this.audioBytes,
    this.coverBytes,
    this.isCachingAudio = false,
    this.isCachingCover = false,
  });

  final String id;
  final String title;
  final String? audioUrl;
  final String? imageUrl;
  final Uint8List? audioBytes;
  final Uint8List? coverBytes;
  final bool isCachingAudio;
  final bool isCachingCover;

  GeneratedTrack copyWith({
    Object? audioBytes = _noValue,
    Object? coverBytes = _noValue,
    bool? isCachingAudio,
    bool? isCachingCover,
  }) {
    return GeneratedTrack(
      id: id,
      title: title,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      audioBytes: identical(audioBytes, _noValue)
          ? this.audioBytes
          : audioBytes as Uint8List?,
      coverBytes: identical(coverBytes, _noValue)
          ? this.coverBytes
          : coverBytes as Uint8List?,
      isCachingAudio: isCachingAudio ?? this.isCachingAudio,
      isCachingCover: isCachingCover ?? this.isCachingCover,
    );
  }
}

class MusicGenerationState extends ChangeNotifier {
  MusicGenerationState({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  GenerationStatus status = GenerationStatus.idle;
  double progress = 0;
  String prompt = '彩虹晨练';
  String description = '节奏从 92 BPM 渐进到 110 BPM，先以木琴与手鼓唤醒课堂，再加入弦乐与轻快口风琴，引导孩子在创意任务与律动练习间切换，整体保持明亮愉悦的调性。';
  String style = 'kids-pop';
  bool instrumental = false;

  String? taskId;
  GenerationError? error;
  List<GeneratedTrack> tracks = const [];

  Timer? _pollingTimer;

  Future<void> generateMusic({
    required String promptText,
    required String descriptionText,
    required String styleValue,
    required bool instrumentalValue,
  }) async {
    _cancelPolling();
    status = GenerationStatus.submitting;
    progress = 0;
    error = null;
    tracks = const [];
    notifyListeners();

    prompt = promptText;
    description = descriptionText;
    style = styleValue;
    instrumental = instrumentalValue;

    final payload = {
      'gpt_description_prompt': description,
      'make_instrumental': instrumental,
      'mv': 'chirp-v4',
      'prompt': prompt,
      'style': style,
    };

    try {
      final response = await _client.post(
        Uri.parse(AiApiConfig.musicSubmitUrl),
        headers: AiApiConfig.defaultHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        _setFailure('提交失败：${response.body}');
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final id = data['data']?.toString();
      if (id == null || id.isEmpty) {
        _setFailure('未返回任务 ID');
        return;
      }
      taskId = id;
      status = GenerationStatus.running;
      notifyListeners();
      _startPolling();
    } catch (e) {
      _setFailure('提交异常：$e');
    }
  }

  Future<List<GeneratedTrack>> generateAndWait({
    required String promptText,
    required String descriptionText,
    required String styleValue,
    required bool instrumentalValue,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final completer = Completer<List<GeneratedTrack>>();
    void listener() {
      if (status == GenerationStatus.completed) {
        if (!completer.isCompleted) {
          completer.complete(tracks);
        }
      } else if (status == GenerationStatus.failed) {
        if (!completer.isCompleted) {
          completer.completeError(error ?? GenerationError('音乐生成失败'));
        }
      }
    }

    addListener(listener);
    try {
      await generateMusic(
        promptText: promptText,
        descriptionText: descriptionText,
        styleValue: styleValue,
        instrumentalValue: instrumentalValue,
      );
      if (status == GenerationStatus.completed && !completer.isCompleted) {
        completer.complete(tracks);
      } else if (status == GenerationStatus.failed && !completer.isCompleted) {
        completer.completeError(error ?? GenerationError('音乐生成失败'));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException catch (_) {
      _setFailure('音乐生成超时，请稍后再试');
      final failure = error ?? GenerationError('音乐生成超时，请稍后再试');
      throw failure;
    } finally {
      removeListener(listener);
    }
  }

  Future<void> downloadAudio(String trackId) async {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) {
      error = GenerationError('未找到对应的音轨');
      notifyListeners();
      return;
    }
    var track = tracks[index];
    final url = track.audioUrl;
    if (url == null || url.isEmpty) {
      error = GenerationError('音频链接不存在，无法下载');
      notifyListeners();
      return;
    }
    if (track.isCachingAudio) {
      return;
    }
    track = track.copyWith(isCachingAudio: true);
    _updateTrack(trackId, track);
    try {
      final bytes = track.audioBytes ?? await _fetchBytes(url);
      final success = await triggerBytesDownload(
        bytes,
        fileName: _suggestFileName(track.title, 'mp3'),
        mimeType: 'audio/mpeg',
      );
      track = track.copyWith(
        audioBytes: bytes,
        isCachingAudio: false,
      );
      _updateTrack(trackId, track);
      if (!success) {
        error = const GenerationError('浏览器暂不支持自动下载，请右键音频另存为。');
        notifyListeners();
      } else {
        error = null;
      }
    } catch (e) {
      track = track.copyWith(isCachingAudio: false);
      _updateTrack(trackId, track);
      error = GenerationError('音频下载失败：$e');
      notifyListeners();
    }
  }

  Future<Uint8List?> ensureAudioBytes(String trackId) async {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) {
      error = GenerationError('未找到对应的音轨');
      notifyListeners();
      return null;
    }
    var track = tracks[index];
    final url = track.audioUrl;
    if (url == null || url.isEmpty) {
      error = GenerationError('音频链接不存在，无法加载');
      notifyListeners();
      return null;
    }
    if (track.audioBytes != null) {
      return track.audioBytes;
    }
    try {
      final bytes = await _fetchBytes(url);
      track = track.copyWith(audioBytes: bytes);
      _updateTrack(trackId, track);
      return bytes;
    } catch (e) {
      error = GenerationError('音频加载失败：$e');
      notifyListeners();
      return null;
    }
  }

  Future<void> downloadCover(String trackId) async {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) {
      error = GenerationError('未找到对应的音轨封面');
      notifyListeners();
      return;
    }
    var track = tracks[index];
    final url = track.imageUrl;
    if (url == null || url.isEmpty) {
      error = GenerationError('封面链接不存在，无法下载');
      notifyListeners();
      return;
    }
    if (track.isCachingCover) {
      return;
    }
    track = track.copyWith(isCachingCover: true);
    _updateTrack(trackId, track);
    try {
      final bytes = track.coverBytes ?? await _fetchBytes(url);
      final success = await triggerBytesDownload(
        bytes,
        fileName: _suggestFileName('${track.title}_cover', 'jpg'),
        mimeType: 'image/jpeg',
      );
      track = track.copyWith(
        coverBytes: bytes,
        isCachingCover: false,
      );
      _updateTrack(trackId, track);
      if (!success) {
        error = const GenerationError('浏览器暂不支持自动下载，请右键图片另存为。');
        notifyListeners();
      } else {
        error = null;
      }
    } catch (e) {
      track = track.copyWith(isCachingCover: false);
      _updateTrack(trackId, track);
      error = GenerationError('封面下载失败：$e');
      notifyListeners();
    }
  }

  Future<Uint8List?> ensureCoverBytes(String trackId) async {
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) {
      error = GenerationError('未找到对应的音轨封面');
      notifyListeners();
      return null;
    }
    var track = tracks[index];
    final url = track.imageUrl;
    if (url == null || url.isEmpty) {
      error = GenerationError('封面链接不存在，无法加载');
      notifyListeners();
      return null;
    }
    if (track.coverBytes != null) {
      return track.coverBytes;
    }
    try {
      final bytes = await _fetchBytes(url);
      track = track.copyWith(coverBytes: bytes);
      _updateTrack(trackId, track);
      return bytes;
    } catch (e) {
      error = GenerationError('封面加载失败：$e');
      notifyListeners();
      return null;
    }
  }

  void _updateTrack(String trackId, GeneratedTrack updated) {
    tracks = tracks
        .map((track) => track.id == trackId ? updated : track)
        .toList(growable: false);
    notifyListeners();
  }

  void _startPolling() {
    final id = taskId;
    if (id == null) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final response = await _client.get(
          Uri.parse('${AiApiConfig.musicFetchUrl}$id'),
          headers: AiApiConfig.defaultHeaders(json: false),
        );
        if (response.statusCode != 200) {
          return;
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final payload = data['data'] as Map<String, dynamic>? ?? {};
        final statusValue = payload['status']?.toString();
        final progressValue = payload['progress'];
        if (progressValue is num) {
          progress = (progressValue.toDouble() / 100).clamp(0, 1);
        }
        notifyListeners();

        if (statusValue == 'SUCCESS') {
          final results = payload['data'];
          if (results is List && results.isNotEmpty) {
            tracks = results.map((item) {
              final map = item as Map<String, dynamic>;
              final idValue = map['id']?.toString() ??
                  map['title']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString();
              return GeneratedTrack(
                id: idValue,
                title: map['title']?.toString() ?? 'untitled',
                audioUrl: map['audio_url']?.toString(),
                imageUrl: map['image_url']?.toString(),
              );
            }).toList(growable: false);
          }
          status = GenerationStatus.completed;
          progress = 1;
          _cancelPolling();
          notifyListeners();
        } else if (statusValue == 'FAILED' || statusValue == 'ERROR') {
          _setFailure('音乐生成失败');
        }
      } catch (e) {
        _setFailure('查询失败：$e');
      }
    });
  }

  void _setFailure(String message) {
    status = GenerationStatus.failed;
    error = GenerationError(message);
    _cancelPolling();
    notifyListeners();
  }

  void prefillFromStory({
    required String title,
    required String description,
    String? lyric,
  }) {
    prompt = title;
    final parts = <String>[
      description.trim(),
      if (lyric != null && lyric.trim().isNotEmpty) lyric.trim(),
    ];
    description = parts.where((e) => e.isNotEmpty).join('\n');
    notifyListeners();
  }

  void reset() {
    _cancelPolling();
    status = GenerationStatus.idle;
    progress = 0;
    taskId = null;
    tracks = const [];
    error = null;
    notifyListeners();
  }

  void _cancelPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<Uint8List> _fetchBytes(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('下载失败，状态码 ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  String _suggestFileName(String title, String extension) {
    final base = title.trim().isEmpty ? 'track' : title.trim();
    final sanitized = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final normalizedExt =
        extension.startsWith('.') ? extension.substring(1) : extension;
    final ext = normalizedExt.isEmpty ? 'bin' : normalizedExt;
    return '$sanitized.$ext';
  }

  @override
  void dispose() {
    _cancelPolling();
    _client.close();
    super.dispose();
  }
}
