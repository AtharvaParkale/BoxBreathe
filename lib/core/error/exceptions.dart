class CacheException implements Exception {}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException([this.message = '', this.code]);
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = '']);
}
