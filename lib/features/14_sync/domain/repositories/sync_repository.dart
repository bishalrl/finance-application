import 'package:dartz/dartz.dart';
import '../entities/sync_status.dart';
import '../../../../core/errors/failures.dart';

abstract class SyncRepository {
  Future<Either<Failure, SyncStatusEntity>> syncData();
  Future<Either<Failure, void>> uploadChanges();
  Future<Either<Failure, void>> downloadChanges();
  Future<Either<Failure, SyncStatusEntity>> getSyncStatus();
}
