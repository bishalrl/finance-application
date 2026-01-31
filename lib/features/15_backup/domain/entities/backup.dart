import 'package:equatable/equatable.dart';

class Backup extends Equatable {
  final String id;
  final String filePath;
  final DateTime createdAt;
  final int sizeBytes;
  final String? recoveryKey;

  const Backup({
    required this.id,
    required this.filePath,
    required this.createdAt,
    this.sizeBytes = 0,
    this.recoveryKey,
  });

  @override
  List<Object?> get props => [id, filePath, createdAt, sizeBytes, recoveryKey];
}
