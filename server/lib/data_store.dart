import 'dart:convert';
import 'dart:io';

import 'models.dart';

class DataStore {
  DataStore({required Directory root})
      : dataDir = Directory('${root.path}/data'),
        storageDir = Directory('${root.path}/storage');

  final Directory dataDir;
  final Directory storageDir;

  List<User> users = <User>[];
  List<Classroom> classrooms = <Classroom>[];
  List<Story> stories = <Story>[];
  List<ContentEntry> contents = <ContentEntry>[];

  Future<void> init() async {
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    users = await _loadList('users.json', (json) => User.fromJson(json));
    classrooms = await _loadList('classrooms.json', (json) => Classroom.fromJson(json));
    stories = await _loadList('stories.json', (json) => Story.fromJson(json));
    contents = await _loadList('content.json', (json) => ContentEntry.fromJson(json));
  }

  Future<void> persistAll() async {
    await Future.wait([
      saveUsers(),
      saveClassrooms(),
      saveStories(),
      saveContents(),
    ]);
  }

  Future<void> saveUsers() => _saveList('users.json', users.map((u) => u.toJson()).toList());

  Future<void> saveClassrooms() =>
      _saveList('classrooms.json', classrooms.map((c) => c.toJson()).toList());

  Future<void> saveStories() => _saveList('stories.json', stories.map((s) => s.toJson()).toList());

  Future<void> saveContents() =>
      _saveList('content.json', contents.map((c) => c.toJson()).toList());

  Future<File> storeBinary(String fileName, List<int> bytes) async {
    final file = File('${storageDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> storeText(String fileName, String text) async {
    final file = File('${storageDir.path}/$fileName');
    await file.writeAsString(text, flush: true);
    return file;
  }

  Future<List<T>> _loadList<T>(
    String fileName,
    T Function(Map<String, dynamic>) builder,
  ) async {
    final file = File('${dataDir.path}/$fileName');
    if (!await file.exists()) {
      await file.writeAsString('[]', flush: true);
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <T>[];
    }
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(builder)
          .toList();
    }
    return <T>[];
  }

  Future<void> _saveList(String fileName, List<Map<String, dynamic>> data) async {
    final file = File('${dataDir.path}/$fileName');
    await file.writeAsString(encodeJson(data), flush: true);
  }
}
