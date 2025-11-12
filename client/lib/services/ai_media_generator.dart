import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class BackgroundImageResult {
  BackgroundImageResult({
    required this.imageUrl,
    required this.prompt,
    this.responseJson,
  });

  final String imageUrl;
  final String prompt;
  final Map<String, dynamic>? responseJson;
}

class AiMediaGenerator {
  AiMediaGenerator({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<BackgroundImageResult> generateBackgroundImage({
    required String theme,
    required String styleHint,
  }) async {
    final prompt = _buildPrompt(theme, styleHint);
    final response = await _client.post(
      Uri.parse(AiApiConfig.imageGenerateUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'size': '1024x1024',
        'sequential_image_generation': 'disabled',
        'stream': false,
        'response_format': 'url',
        'watermark': false,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('背景图生成失败: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      final url = first['url']?.toString();
      if (url != null && url.isNotEmpty) {
        return BackgroundImageResult(
          imageUrl: url,
          prompt: prompt,
          responseJson: data,
        );
      }
    }
    throw Exception('未能获取背景图链接');
  }

  String _buildPrompt(String theme, String styleHint) {
    final buffer = StringBuffer();
    buffer.writeln('Create a warmly lit elementary art classroom environment prepared for a thematic lesson.');
    buffer.writeln('Lesson theme: $theme.');
    if (styleHint.trim().isNotEmpty) {
      buffer.writeln('Infuse visual cues from the lesson plan: $styleHint.');
    }
    buffer.writeln('Show handcrafted details such as student artwork walls, organized tables with art supplies, soft textiles, and natural wooden textures.');
    buffer.writeln('Lighting should be sunrise-warm with gentle shadows, highlighting a collaborative learning mood.');
    buffer.writeln('Use cinematic framing with a welcoming focal point, medium-wide composition, and subtle depth of field.');
    buffer.writeln('Avoid recognizable faces; characters should remain abstract silhouettes or implied presence to ensure reusability and student privacy.');
    buffer.writeln('Style tags: cozy classroom, tactile materials, storybook illustration, uplifting color palette.');
    return buffer.toString();
  }
}
