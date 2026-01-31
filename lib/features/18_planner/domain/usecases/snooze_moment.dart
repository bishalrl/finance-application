import 'package:dartz/dartz.dart';
import '../entities/planner_moment.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class SnoozeMoment {
  final PlannerRepository repository;

  SnoozeMoment(this.repository);

  Future<Either<Failure, PlannerMoment>> call(String id, DateTime newReminderAt) =>
      repository.snoozeMoment(id, newReminderAt);
}
