import 'package:dartz/dartz.dart';
import 'package:life_vault/core/database/hive_service.dart';
import 'package:life_vault/core/errors/failures.dart';
import 'package:life_vault/core/security/encryption_service.dart';
import '../../domain/entities/backup.dart';
import '../../domain/repositories/backup_repository.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class BackupRepositoryImpl implements BackupRepository {
  final HiveService _hiveService;
  final EncryptionService _encryptionService;

  BackupRepositoryImpl(this._hiveService, this._encryptionService);

  @override
  Future<Either<Failure, Backup>> createBackup(String password) async {
    try {
      // Gather all encrypted boxes
      // Compress into archive
      // Encrypt with backup password
      // Save to user-selected location
      
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create();
      }

      final backupId = const Uuid().v4();
      final backupPath = '${backupDir.path}/backup_$backupId.lvbak';
      
      // In real implementation, this would:
      // 1. Export all Hive boxes
      // 2. Compress
      // 3. Encrypt with password
      // 4. Save to file
      
      final backup = Backup(
        id: backupId,
        filePath: backupPath,
        createdAt: DateTime.now(),
      );

      return Right(backup);
    } catch (e) {
      return Left(GeneralFailure('Failed to create backup: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreBackup(String filePath, String password) async {
    try {
      // Decrypt backup
      // Verify integrity
      // Replace current data
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure('Failed to restore backup: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Backup>>> getAllBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        return const Right([]);
      }

      final files = backupDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.lvbak'))
          .map((f) => Backup(
                id: f.path.split('/').last,
                filePath: f.path,
                createdAt: f.lastModifiedSync(),
                sizeBytes: f.lengthSync(),
              ))
          .toList();

      return Right(files);
    } catch (e) {
      return Left(GeneralFailure('Failed to get backups: $e'));
    }
  }
}
