import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/local_config.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppApiService {
  AppApiService._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get _baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return LocalConfig.serverBaseUrl;
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  static Map<String, String> _headers({String? token}) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String role,
    String? classroomCode,
    String? classroomName,
  }) {
    final payload = <String, dynamic>{
      'username': username,
      'password': password,
      'role': role,
      if (classroomCode != null && classroomCode.isNotEmpty)
        'classroomCode': classroomCode.trim().toUpperCase(),
      if (classroomName != null && classroomName.isNotEmpty)
        'classroomName': classroomName.trim(),
    };
    return _post('/auth/register', body: payload);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _post('/auth/login', body: {
      'username': username,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> fetchCurrentUser(String token) {
    return _get('/auth/me', token: token);
  }

  static Future<Map<String, dynamic>> createClassroom({
    required String token,
    required String name,
  }) {
    return _post(
      '/classrooms',
      token: token,
      body: {'name': name},
    );
  }

  static Future<Map<String, dynamic>> joinClassroom({
    required String token,
    required String code,
  }) {
    return _post(
      '/classrooms/join',
      token: token,
      body: {'code': code},
    );
  }

  static Future<Map<String, dynamic>> listClassrooms(String token) {
    return _get('/classrooms', token: token);
  }

  static Future<Map<String, dynamic>> deleteClassroom({
    required String token,
    required String classroomId,
  }) {
    return _delete('/classrooms/$classroomId', token: token);
  }

  static Future<Map<String, dynamic>> createStory({
    required String token,
    required String title,
    required List<String> classroomIds,
    String? theme,
  }) {
    return _post('/stories', token: token, body: {
      'title': title,
      'classroomIds': classroomIds,
      if (theme != null && theme.isNotEmpty) 'theme': theme,
    });
  }

  static Future<Map<String, dynamic>> updateStory({
    required String token,
    required String storyId,
    Map<String, dynamic>? data,
  }) {
    return _put('/stories/$storyId',
        token: token, body: data ?? <String, dynamic>{});
  }

  static Future<Map<String, dynamic>> deleteStory({
    required String token,
    required String storyId,
  }) {
    return _delete('/stories/$storyId', token: token);
  }

  static Future<Map<String, dynamic>> listStories(String token) {
    return _get('/stories', token: token);
  }

  static Future<Map<String, dynamic>> fetchStory({
    required String token,
    required String storyId,
  }) {
    return _get('/stories/$storyId', token: token);
  }

  static Future<Map<String, dynamic>> uploadContent({
    required String token,
    required String title,
    required String kind,
    required String visibility,
    required List<String> classroomIds,
    String? description,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? metadata,
    bool teacherGenerated = false,
    bool aiGenerated = false,
    String? storyId,
  }) {
    return _post('/content', token: token, body: {
      'title': title,
      'kind': kind,
      'visibility': visibility,
      'classroomIds': classroomIds,
      'description': description ?? '',
      if (preview != null) 'preview': preview,
      if (metadata != null) 'metadata': metadata,
      'teacherGenerated': teacherGenerated,
      'aiGenerated': aiGenerated,
      if (storyId != null) 'storyId': storyId,
    });
  }

  static Future<Map<String, dynamic>> deleteContent({
    required String token,
    required String contentId,
  }) {
    return _delete('/content/$contentId', token: token);
  }

  static String resolveUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUri = Uri.parse(_baseUrl);
    final resolved =
        baseUri.resolve(trimmed.startsWith('/') ? trimmed : '/$trimmed');
    return resolved.toString();
  }

  static Future<Map<String, dynamic>> uploadFile({
    required String token,
    required String title,
    required String kind,
    required String visibility,
    required List<String> classroomIds,
    required Uint8List fileBytes,
    required String fileName,
    String? mimeType,
    String? description,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? preview,
    bool teacherGenerated = false,
    bool aiGenerated = false,
    String? storyId,
  }) async {
    final uri = _uri('/content');
    final request = http.MultipartRequest('POST', uri);

    // 添加认证头
    request.headers['Authorization'] = 'Bearer $token';

    // 添加文件
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    // 添加表单字段
    request.fields['title'] = title;
    request.fields['kind'] = kind;
    request.fields['visibility'] = visibility;
    request.fields['classroomIds'] = classroomIds.join(',');
    request.fields['description'] = description ?? '';
    request.fields['teacherGenerated'] = teacherGenerated.toString();
    request.fields['aiGenerated'] = aiGenerated.toString();
    if (storyId != null) {
      request.fields['storyId'] = storyId;
    }
    if (metadata != null) {
      request.fields['metadata'] = jsonEncode(metadata);
    }
    if (preview != null) {
      request.fields['preview'] = jsonEncode(preview);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw ApiException('上传失败: ${response.statusCode} - $responseBody');
    }
  }

  static Future<Map<String, dynamic>> fetchContentFeed({
    required String token,
    String scope = 'classes',
    String? classId,
    String? kind,
  }) {
    final query = <String, String>{
      'scope': scope,
      if (classId != null && classId.isNotEmpty) 'classId': classId,
      if (kind != null && kind.isNotEmpty) 'kind': kind,
    };
    return _get('/content/feed', token: token, query: query);
  }

  static Future<Map<String, dynamic>> toggleContentLike({
    required String token,
    required String contentId,
  }) {
    return _post('/content/$contentId/like', token: token);
  }

  static Future<Map<String, dynamic>> commentOnContent({
    required String token,
    required String contentId,
    required String content,
  }) {
    return _post('/content/$contentId/comment',
        token: token, body: {'content': content});
  }

  static Future<Map<String, dynamic>> importStoryBundle({
    required String token,
    required Map<String, dynamic> story,
    required List<String> classroomIds,
    String? title,
  }) {
    return _post(
      '/stories/import',
      token: token,
      body: {
        'story': story,
        'classroomIds': classroomIds,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
  }

  static Future<Map<String, dynamic>> fetchTopContent() {
    return _get('/showcase/top');
  }

  static Future<Map<String, dynamic>> listShowcaseItems({
    String category = 'all',
    String? token,
  }) {
    return _get(
      '/showcase/items',
      token: token,
      query: {'category': category},
    );
  }

  static Future<Map<String, dynamic>> fetchShowcaseCategories() {
    return _get('/showcase/categories');
  }

  static Future<Map<String, dynamic>> _get(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await http.get(
      _uri(path, query),
      headers: _headers(token: token),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(token: token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(token: token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _delete(
    String path, {
    String? token,
  }) async {
    final response = await http.delete(
      _uri(path),
      headers: _headers(token: token),
    );
    return _handle(response);
  }

  static Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic> decode() {
      if (response.body.isEmpty) return <String, dynamic>{};
      final dynamic body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return body;
      }
      return <String, dynamic>{'data': body};
    }

    final body = decode();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message =
        body['error'] ?? body['message'] ?? response.reasonPhrase ?? '请求失败';
    throw ApiException(message.toString());
  }
}
