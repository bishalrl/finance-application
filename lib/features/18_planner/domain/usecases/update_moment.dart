import 'package:dartz/dartz.dart';
import '../entities/planner_moment.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class UpdateMoment {
  final PlannerRepository repository;

  UpdateMoment(this.repository);

  Future<Either<Failure, PlannerMoment>> call(PlannerMoment moment) async {
    final updated = moment.copyWith(updatedAt: DateTime.now());
    return repository.updateMoment(updated);
  }
}
