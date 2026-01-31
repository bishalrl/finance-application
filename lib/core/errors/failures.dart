import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// General failure
class GeneralFailure extends Failure {
  const GeneralFailure(super.message);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Authentication failure
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

/// Encryption failure
class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message);
}

/// File operation failure
class FileOperationFailure extends Failure {
  const FileOperationFailure(super.message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Subscription failure
class SubscriptionFailure extends Failure {
  const SubscriptionFailure(super.message);
}
