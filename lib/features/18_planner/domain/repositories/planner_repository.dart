import 'package:dartz/dartz.dart';
import '../entities/planner_moment.dart';
import '../../../../core/errors/failures.dart';

abstract class PlannerRepository {
  Future<Either<Failure, List<PlannerMoment>>> getTodayMoments();
  Future<Either<Failure, List<PlannerMoment>>> getMomentsForDay(DateTime day);
  Future<Either<Failure, List<PlannerMoment>>> getMomentsInRange(DateTime start, DateTime end);
  Future<Either<Failure, PlannerMoment?>> getMomentById(String id);
  Future<Either<Failure, PlannerMoment>> createMoment(PlannerMoment moment);
  Future<Either<Failure, PlannerMoment>> updateMoment(PlannerMoment moment);
  Future<Either<Failure, void>> acknowledgeMoment(String id);
  Future<Either<Failure, void>> deleteMoment(String id);
  Future<Either<Failure, PlannerMoment>> snoozeMoment(String id, DateTime newReminderAt);
}
