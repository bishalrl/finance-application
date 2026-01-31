import 'package:dartz/dartz.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for marking a reminder as complete
class MarkAsComplete {
  final ReminderRepository repository;

  MarkAsComplete(this.repository);

  Future<Either<Failure, Reminder>> call(String id) async {
    return await repository.markAsComplete(id);
  }
}
