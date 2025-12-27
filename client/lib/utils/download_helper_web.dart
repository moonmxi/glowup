// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> triggerUrlDownload(String url, String fileName) async {
  final element = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(element);
  element.click();
  element.remove();
  return true;
}

Future<bool> triggerBytesDownload(
  Uint8List bytes, {
  required String fileName,
  String? mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  try {
    await triggerUrlDownload(objectUrl, fileName);
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
  return true;
}
