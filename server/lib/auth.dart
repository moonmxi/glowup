import 'dart:io';

import 'data_store.dart';
import 'models.dart';
import 'utils.dart';

class AuthManager {
  AuthManager(this.store);

  final DataStore store;
  final Map<String, String> _tokenToUser = <String, String>{};

  User? authenticate(HttpRequest request) {
    final header = request.headers.value(HttpHeaders.authorizationHeader);
    if (header == null) return null;
    final token = _extractToken(header);
    if (token == null) return null;
    return userForToken(token);
  }

  String? _extractToken(String header) {
    if (header.toLowerCase().startsWith('bearer ')) {
      return header.substring(7).trim();
    }
    return header.trim().isEmpty ? null : header.trim();
  }

  User? userForToken(String token) {
    final userId = _tokenToUser[token];
    if (userId == null) return null;
    for (final user in store.users) {
      if (user.id == userId) return user;
    }
    return null;
  }

  String issueToken(User user) {
    final token = generateToken();
    _tokenToUser[token] = user.id;
    return token;
  }

  void revokeToken(String token) {
    _tokenToUser.remove(token);
  }
}
