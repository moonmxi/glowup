import 'dart:typed_data';

Future<bool> triggerUrlDownload(String url, String fileName) async {
  // Downloads are not supported on this platform fallback.
  return false;
}

Future<bool> triggerBytesDownload(
  Uint8List bytes, {
  required String fileName,
  String? mimeType,
}) async {
  // Downloads are not supported on this platform fallback.
  return false;
}
