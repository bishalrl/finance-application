import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import 'package:life_vault/core/security/key_manager.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, bool>> setupPin(String pin) async {
    print('AuthRepositoryImpl: setupPin called.');
    try {
      print('AuthRepositoryImpl: Calling _localDataSource.setupPin...');
      final success = await _localDataSource.setupPin(pin);
      if (success) {
        print('AuthRepositoryImpl: _localDataSource.setupPin succeeded.');
        return const Right(true);
      } else {
        print('AuthRepositoryImpl: _localDataSource.setupPin failed, returning AuthenticationFailure.');
        return Left(AuthenticationFailure('Failed to setup PIN'));
      }
    } catch (e) {
      if (e is KeyDerivationException) {
        print('AuthRepositoryImpl: Caught KeyDerivationException: ${e.message}'); // Log the specific message
        return Left(AuthenticationFailure('Failed to setup PIN: ${e.message}'));
      }
      print('AuthRepositoryImpl: Caught unexpected exception: $e');
      return Left(AuthenticationFailure('Failed to setup PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final success = await _localDataSource.verifyPin(pin);
      return success ? const Right(true) : Left(AuthenticationFailure('Invalid PIN'));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to verify PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> setupBiometric() async {
    try {
      final success = await _localDataSource.setupBiometric();
      return success ? const Right(true) : Left(AuthenticationFailure('Failed to setup biometric'));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to setup biometric: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyBiometric() async {
    try {
      final success = await _localDataSource.verifyBiometric();
      return success ? const Right(true) : Left(AuthenticationFailure('Biometric verification failed'));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to verify biometric: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPin() async {
    try {
      final hasPin = await _localDataSource.hasPin();
      return Right(hasPin);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to check PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasBiometric() async {
    try {
      final hasBiometric = await _localDataSource.hasBiometric();
      return Right(hasBiometric);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to check biometric: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> lockApp() async {
    // Lock app logic - clear sensitive data from memory
    return const Right(null);
  }
}
