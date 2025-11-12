import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

class ResolvedPlatformFile {
  const ResolvedPlatformFile({
    required this.bytes,
    required this.name,
    this.path,
    this.mimeType,
  });

  final Uint8List bytes;
  final String name;
  final String? path;
  final String? mimeType;
}

/// Reads the content of a [PlatformFile] into memory so that it can be
/// uploaded or processed on platforms that lack direct file system access
/// (e.g. the web).
Future<ResolvedPlatformFile?> resolvePlatformFile(PlatformFile file) async {
  try {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.readStream != null) {
      bytes = await _readFromStream(file.readStream!);
    }
    if (bytes == null) return null;
    final mimeType = lookupMimeType(
      file.name,
      headerBytes: bytes.length >= 12 ? bytes.sublist(0, 12) : bytes,
    );
    return ResolvedPlatformFile(
      bytes: bytes,
      name: file.name,
      path: kIsWeb ? null : file.path,
      mimeType: mimeType,
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    return null;
  }
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
