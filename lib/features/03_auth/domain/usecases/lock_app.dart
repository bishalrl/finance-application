import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

class LockApp {
  final AuthRepository repository;
  LockApp(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.lockApp();
  }
}
