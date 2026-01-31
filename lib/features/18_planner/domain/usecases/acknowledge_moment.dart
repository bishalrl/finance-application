import 'package:dartz/dartz.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class AcknowledgeMoment {
  final PlannerRepository repository;

  AcknowledgeMoment(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.acknowledgeMoment(id);
}
