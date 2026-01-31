/// Base exception class
class AppException implements Exception {
  final String message;
  AppException(this.message);
  
  @override
  String toString() => message;
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Server exception
class ServerException extends AppException {
  ServerException(super.message);
}

/// Authentication exception
class AuthenticationException extends AppException {
  AuthenticationException(super.message);
}

/// Encryption exception
class EncryptionException extends AppException {
  EncryptionException(super.message);
}

/// File operation exception
class FileOperationException extends AppException {
  FileOperationException(super.message);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Permission exception
class PermissionException extends AppException {
  PermissionException(super.message);
}
