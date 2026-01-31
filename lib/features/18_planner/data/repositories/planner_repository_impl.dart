import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import '../../domain/entities/planner_moment.dart';
import '../../domain/repositories/planner_repository.dart';
import '../datasources/planner_local_datasource.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerLocalDataSource _localDataSource;

  PlannerRepositoryImpl({required PlannerLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<PlannerMoment>>> getTodayMoments() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final list = await _localDataSource.getMomentsForDay(start);
      return Right(list);
    } catch (e) {
      return Left(CacheFailure('Failed to get today moments: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PlannerMoment>>> getMomentsForDay(DateTime day) async {
    try {
      final list = await _localDataSource.getMomentsForDay(day);
      return Right(list);
    } catch (e) {
      return Left(CacheFailure('Failed to get moments for day: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PlannerMoment>>> getMomentsInRange(DateTime start, DateTime end) async {
    try {
      final list = await _localDataSource.getMomentsInRange(start, end);
      return Right(list);
    } catch (e) {
      return Left(CacheFailure('Failed to get moments in range: $e'));
    }
  }

  @override
  Future<Either<Failure, PlannerMoment?>> getMomentById(String id) async {
    try {
      final moment = await _localDataSource.getMomentById(id);
      return Right(moment);
    } catch (e) {
      return Left(CacheFailure('Failed to get moment: $e'));
    }
  }

  @override
  Future<Either<Failure, PlannerMoment>> createMoment(PlannerMoment moment) async {
    try {
      await _localDataSource.saveMoment(moment);
      return Right(moment);
    } catch (e) {
      return Left(CacheFailure('Failed to create moment: $e'));
    }
  }

  @override
  Future<Either<Failure, PlannerMoment>> updateMoment(PlannerMoment moment) async {
    try {
      await _localDataSource.updateMoment(moment);
      return Right(moment);
    } catch (e) {
      return Left(CacheFailure('Failed to update moment: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeMoment(String id) async {
    try {
      final moment = await _localDataSource.getMomentById(id);
      if (moment == null) return Left(CacheFailure('Moment not found'));
      final updated = moment.copyWith(
        status: MomentStatus.acknowledged,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.updateMoment(updated);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to acknowledge moment: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMoment(String id) async {
    try {
      await _localDataSource.deleteMoment(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete moment: $e'));
    }
  }

  @override
  Future<Either<Failure, PlannerMoment>> snoozeMoment(String id, DateTime newReminderAt) async {
    try {
      final moment = await _localDataSource.getMomentById(id);
      if (moment == null) return Left(CacheFailure('Moment not found'));
      final updated = moment.copyWith(
        reminderAt: newReminderAt,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.updateMoment(updated);
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure('Failed to snooze moment: $e'));
    }
  }
}
