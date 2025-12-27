import 'dart:convert';
import 'dart:math';

final _random = Random.secure();

String generateId([int length = 16]) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
}

String generateCode([int length = 6]) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
}

String generateToken() {
  final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
  return base64UrlEncode(bytes);
}
