import 'package:dartz/dartz.dart';
import '../entities/planner_moment.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class GetMomentsForDay {
  final PlannerRepository repository;

  GetMomentsForDay(this.repository);

  Future<Either<Failure, List<PlannerMoment>>> call(DateTime day) =>
      repository.getMomentsForDay(day);
}
