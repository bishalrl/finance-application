import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

class SetupBiometric {
  final AuthRepository repository;
  SetupBiometric(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.setupBiometric();
  }
}
