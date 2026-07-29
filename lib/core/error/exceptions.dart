class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server Error']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache Error']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Auth Error']);
}
