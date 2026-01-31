import 'package:dartz/dartz.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class DeleteMoment {
  final PlannerRepository repository;

  DeleteMoment(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.deleteMoment(id);
}
