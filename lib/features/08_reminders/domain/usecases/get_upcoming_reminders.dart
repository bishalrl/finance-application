import 'package:dartz/dartz.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for getting upcoming reminders
class GetUpcomingReminders {
  final ReminderRepository repository;

  GetUpcomingReminders(this.repository);

  Future<Either<Failure, List<Reminder>>> call() async {
    return await repository.getUpcomingReminders();
  }
}
