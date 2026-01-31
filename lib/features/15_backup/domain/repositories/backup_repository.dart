import 'package:dartz/dartz.dart';
import '../entities/backup.dart';
import '../../../../core/errors/failures.dart';

abstract class BackupRepository {
  Future<Either<Failure, Backup>> createBackup(String password);
  Future<Either<Failure, void>> restoreBackup(String filePath, String password);
  Future<Either<Failure, List<Backup>>> getAllBackups();
}
