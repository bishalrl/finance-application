import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

class SetupPin {
  final AuthRepository repository;
  SetupPin(this.repository);

  Future<Either<Failure, bool>> call(String pin) async {
    if (pin.length < 4) {
      return Left(ValidationFailure('PIN must be at least 4 digits'));
    }
    return await repository.setupPin(pin);
  }
}
