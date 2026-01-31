import 'package:dartz/dartz.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for scheduling a notification for a reminder
class ScheduleNotification {
  final ReminderRepository repository;

  ScheduleNotification(this.repository);

  Future<Either<Failure, void>> call(Reminder reminder) async {
    return await repository.scheduleNotification(reminder);
  }
}
