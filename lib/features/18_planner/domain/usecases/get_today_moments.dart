import 'package:dartz/dartz.dart';
import '../entities/planner_moment.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class GetTodayMoments {
  final PlannerRepository repository;

  GetTodayMoments(this.repository);

  Future<Either<Failure, List<PlannerMoment>>> call() =>
      repository.getTodayMoments();
}
