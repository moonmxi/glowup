import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

class NativePickedImage {
  const NativePickedImage({
    required this.bytes,
    required this.name,
    this.path,
    this.mimeType,
  });

  final Uint8List bytes;
  final String? path;
  final String name;
  final String? mimeType;
}

class NativePickedAudio {
  const NativePickedAudio({
    required this.name,
    this.path,
    this.bytes,
    this.mimeType,
  });

  final String? path;
  final Uint8List? bytes;
  final String name;
  final String? mimeType;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

Future<NativePickedImage?> pickNativeImage() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final platformFile = result.files.first;
    final data = await _resolveBytes(platformFile);
    if (data == null) {
      throw PlatformException(
        code: 'read_failed',
        message: '无法读取所选图片文件，请重试。',
      );
    }
    final mimeType = lookupMimeType(
      platformFile.name,
      headerBytes: data.length >= 12 ? data.sublist(0, 12) : data,
    );
    return NativePickedImage(
      bytes: data,
      name: platformFile.name,
      path: kIsWeb ? null : platformFile.path,
      mimeType: mimeType,
    );
  } on PlatformException {
    rethrow;
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    throw PlatformException(
      code: 'picker_failure',
      message: '选取图片失败：$error',
    );
  }
}

Future<NativePickedAudio?> pickNativeAudio() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final platformFile = result.files.first;
    final bytes = await _resolveBytes(platformFile);
    if (bytes == null) {
      throw PlatformException(
        code: 'read_failed',
        message: '无法读取所选音频文件，请重试。',
      );
    }
    final mimeType = lookupMimeType(
      platformFile.name,
      headerBytes: bytes.length >= 12 ? bytes.sublist(0, 12) : bytes,
    );
    return NativePickedAudio(
      name: platformFile.name,
      path: kIsWeb ? null : platformFile.path,
      bytes: bytes,
      mimeType: mimeType,
    );
  } on PlatformException {
    rethrow;
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    throw PlatformException(
      code: 'picker_failure',
      message: '选择音频失败：$error',
    );
  }
}

Future<Uint8List?> _resolveBytes(PlatformFile file) async {
  if (file.bytes != null) {
    return Uint8List.fromList(file.bytes!);
  }
  if (file.readStream != null) {
    return _readFromStream(file.readStream!);
  }
  return null;
}

Future<Uint8List> _readFromStream(Stream<List<int>> stream) async {
  final completer = Completer<Uint8List>();
  final chunks = <int>[];
  late final StreamSubscription<List<int>> sub;
  sub = stream.listen(
    chunks.addAll,
    onError: (Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      if (!completer.isCompleted) {
        completer.completeError(error, stack);
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(Uint8List.fromList(chunks));
      }
    },
    cancelOnError: true,
  );
  return completer.future.whenComplete(() => sub.cancel());
}
