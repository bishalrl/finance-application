import 'package:equatable/equatable.dart';

enum SyncStatus { synced, syncing, error, notSynced }

class SyncStatusEntity extends Equatable {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final int pendingItems;

  const SyncStatusEntity({
    this.status = SyncStatus.notSynced,
    this.lastSyncTime,
    this.errorMessage,
    this.pendingItems = 0,
  });

  @override
  List<Object?> get props => [status, lastSyncTime, errorMessage, pendingItems];
}
