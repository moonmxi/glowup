import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import 'api_config.dart';

String _extractContent(Map<String, dynamic> data) {
  final output = data['output'];
  if (output is List && output.isNotEmpty) {
    final buffer = StringBuffer();
    for (final item in output) {
      if (item is Map<String, dynamic>) {
        final content = item['content'];
        if (content is List && content.isNotEmpty) {
          for (final part in content) {
            if (part is Map && part['text'] is String) {
              buffer.write(part['text']);
            }
          }
        } else if (content is String) {
          buffer.write(content);
        }
      } else if (item is String) {
        buffer.write(item);
      }
    }
    final text = buffer.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }

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

class AiImageAnalyzer {
  AiImageAnalyzer({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> analyzeImageBytes({
    required Uint8List imageBytes,
    String? fileName,
    String question = '请描述这张图片的内容',
  }) async {
    final header = imageBytes.length >= 12 ? imageBytes.sublist(0, 12) : imageBytes;
    final mime = lookupMimeType(fileName ?? '', headerBytes: header) ?? 'image/png';
    final base64Data = base64Encode(imageBytes);
  final visionPrompt =
    '孩子的问题：$question\n作品主题：<<请填写>>\n使用媒材：<<请填写>>\n孩子自述：<<请填写>>\n请从色彩、构图、情绪三个角度给出三段鼓励式反馈，每段约 120~160 字，结合作品细节提出可操作的建议，并引用适合儿童理解的灵感来源，结尾邀请孩子继续探索。';

    // Prefer the newer Responses API for multimodal prompts.
    try {
      final response = await _client.post(
        Uri.parse(AiApiConfig.responsesUrl),
        headers: AiApiConfig.defaultHeaders(),
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'max_output_tokens': 600,
          'input': [
            {
              'role': 'system',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '你是 “GlowUp 小光”，一位陪伴小学美术课堂的温暖导师。请以真诚、共情的语气反馈孩子作品：第一段真诚肯定亮点，第二段给出可以尝试的改进方法并点出具体细节，第三段分享生活或艺术灵感，鼓励继续探索。引用艺术家、技法或生活观察时要自然简洁，避免分数评价与否定语，并使用生动中文在结尾邀请孩子再次创作。',
                },
              ],
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'input_text',
                  'text': visionPrompt,
                },
                {
                  'type': 'input_image',
                  'image_url': 'data:$mime;base64,$base64Data',
                },
              ],
            },
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _extractContent(data).trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    } catch (_) {
      // Swallow and fall back to chat completions below.
    }

    final fallbackResponse = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                '你是 “GlowUp 小光”，一位陪伴小学美术课堂的温暖导师。请以真诚、共情的语气反馈孩子作品：第一段真诚肯定亮点，第二段给出可以尝试的改进方法并点出具体细节，第三段分享生活或艺术灵感，鼓励继续探索。引用艺术家、技法或生活观察时要自然简洁，避免分数评价与否定语，并使用生动中文在结尾邀请孩子再次创作。',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': visionPrompt,
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mime;base64,$base64Data'},
              },
            ],
          },
        ],
        'max_tokens': 600,
      }),
    );
    if (fallbackResponse.statusCode != 200) {
      throw Exception('图片分析失败: ${fallbackResponse.statusCode}');
    }
    final data = jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
    return _extractContent(data);
  }
}

class AiLessonPlanner {
  AiLessonPlanner({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> generateLessonPlan({
    required String subject,
    required String grade,
    required List<String> options,
    required String description,
  }) async {
    final headers = AiApiConfig.defaultHeaders();
    final focusLine =
        options.isEmpty ? '创意表达与自信分享' : options.join('、');
    final payload = {
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'input': [
        {
          'role': 'system',
          'content':
              '你是 GlowUp 小光，一位熟悉中国小学艺术课堂与“双减”背景的教案助手。请以教师易读、可执行的语言输出 UTF-8 JSON，严格遵守既定键名，不要加入额外字段或解释，确保建议兼顾课堂安全与多元能力发展。',
        },
        {
          'role': 'user',
      'content':
        '请为$grade 的$subject 课程设计 45 分钟教案，课堂重点：$focusLine。课堂背景：${description.trim().isEmpty ? '老师希望孩子们在有限的素材中保持好奇心' : description.trim()}。\n'
          '请按照下列 JSON 结构回复，仅输出 JSON：\n'
                  '{\n'
                  '  "objectives": ["目标1", "目标2"],\n'
                  '  "materials": ["材料1", "材料2"],\n'
                  '  "stages": [\n'
                  '    {\n'
                  '      "name": "环节名称",\n'
                  '      "duration": "10分钟",\n'
                  '      "goal": "本环节目标",\n'
                  '      "activities": ["课堂活动步骤"],\n'
                  '      "teacherActions": ["教师引导要点"],\n'
                  '      "studentActivities": ["学生参与方式"],\n'
                  '      "keyQuestions": ["互动提问"],\n'
                  '      "materials": ["该环节使用的材料"]\n'
                  '    }\n'
                  '  ],\n'
                  '  "questions": ["整堂课可持续追问的问题"],\n'
                  '  "differentiation": ["对不同水平学生的差异化建议"],\n'
                  '  "summary": ["课堂总结重点"],\n'
                  '  "extensions": ["课后延伸任务或家庭活动"]\n'
                  '}\n'
                  '请确保 objectives 以动词开头、duration 之和为 45分钟，activities 与 teacherActions 可直接操作，differentiation 针对不同学习水平列出策略，extensions 至少提供两条家庭延伸建议，如无内容请返回空数组。',
        },
      ],
    };
    final response = await _client.post(
      Uri.parse(AiApiConfig.responsesUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('教案生成失败: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final output = data['output'];
    if (output is List && output.isNotEmpty) {
      final first = output.first;
      if (first is Map && first['content'] is List && first['content'].isNotEmpty) {
        final firstItem = first['content'][0];
        if (firstItem is Map && firstItem['text'] is String) {
          return firstItem['text'] as String;
        }
      }
    }
    return data.toString();
  }
}

class AiChatMentor {
  AiChatMentor({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> replyTo(String message) async {
    final response = await _client.post(
      Uri.parse(AiApiConfig.chatCompletionsUrl),
      headers: AiApiConfig.defaultHeaders(),
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                '你是 “GlowUp 小光”，一位陪伴孩子成长的 AI 伙伴。请以温暖积极的中文分三段回应：先共情接住孩子情绪并真诚肯定努力，再提供富有想象力的建议或练习点子，最后邀请孩子观察生活、记录灵感并在下次分享，同时提醒表达与安全需尊重自己与他人。全程保持鼓励、无责备的语气。',
          },
          {
            'role': 'user',
      'content':
        '孩子说：“$message”。当前心情：<<请填写>>，最近课堂主题：<<请填写>>。请生成 3 段中文回应：第一段先接住情绪并肯定孩子的努力或感受，第二段给出启发式建议或灵感路径，第三段邀请孩子观察生活、记录灵感并在下次分享。避免生硬总结，保持自然口吻。',
          },
        ],
        'max_tokens': 400,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('聊天生成失败: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractContent(data);
  }
}
