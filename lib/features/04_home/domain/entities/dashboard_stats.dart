import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int documentCount;
  final int noteCount;
  final int reminderCount;
  final int ideaCount;
  final int expiredDocuments;
  final int upcomingReminders;

  const DashboardStats({
    this.documentCount = 0,
    this.noteCount = 0,
    this.reminderCount = 0,
    this.ideaCount = 0,
    this.expiredDocuments = 0,
    this.upcomingReminders = 0,
  });

  @override
  List<Object?> get props => [
        documentCount,
        noteCount,
        reminderCount,
        ideaCount,
        expiredDocuments,
        upcomingReminders,
      ];
}
