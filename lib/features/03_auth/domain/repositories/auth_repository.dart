import 'package:dartz/dartz.dart';
import '../entities/user_auth.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> setupPin(String pin);
  Future<Either<Failure, bool>> verifyPin(String pin);
  Future<Either<Failure, bool>> setupBiometric();
  Future<Either<Failure, bool>> verifyBiometric();
  Future<Either<Failure, bool>> hasPin();
  Future<Either<Failure, bool>> hasBiometric();
  Future<Either<Failure, void>> lockApp();
}
