import 'package:dartz/dartz.dart';
import '../entities/planner_moment.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class GetMomentsInRange {
  final PlannerRepository repository;

  GetMomentsInRange(this.repository);

  Future<Either<Failure, List<PlannerMoment>>> call(DateTime start, DateTime end) =>
      repository.getMomentsInRange(start, end);
}
