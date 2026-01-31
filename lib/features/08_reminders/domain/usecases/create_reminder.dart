import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for creating a reminder
class CreateReminder {
  final ReminderRepository repository;

  CreateReminder(this.repository);

  Future<Either<Failure, Reminder>> call({
    required String title,
    String? description,
    required DateTime reminderDate,
    required ReminderType type,
    bool isRecurring = false,
    RecurrencePattern recurrencePattern = RecurrencePattern.none,
    String? linkedDocumentId,
    double? amount,
    String? merchant,
  }) async {
    final now = DateTime.now();
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: title,
      description: description,
      reminderDate: reminderDate,
      type: type,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      linkedDocumentId: linkedDocumentId,
      amount: amount,
      merchant: merchant,
      createdAt: now,
      updatedAt: now,
    );

    return await repository.createReminder(reminder);
  }
}
