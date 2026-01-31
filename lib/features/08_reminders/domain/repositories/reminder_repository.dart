import 'package:dartz/dartz.dart';
import '../entities/reminder.dart';
import '../../../../core/errors/failures.dart';

/// Repository interface for reminder operations
abstract class ReminderRepository {
  /// Creates a reminder
  Future<Either<Failure, Reminder>> createReminder(Reminder reminder);

  /// Gets all reminders
  Future<Either<Failure, List<Reminder>>> getAllReminders();

  /// Gets a reminder by ID
  Future<Either<Failure, Reminder>> getReminderById(String id);

  /// Gets upcoming reminders
  Future<Either<Failure, List<Reminder>>> getUpcomingReminders();

  /// Gets overdue reminders
  Future<Either<Failure, List<Reminder>>> getOverdueReminders();

  /// Gets reminders by type
  Future<Either<Failure, List<Reminder>>> getRemindersByType(ReminderType type);

  /// Gets reminders linked to a document
  Future<Either<Failure, List<Reminder>>> getRemindersByDocument(String documentId);

  /// Updates a reminder
  Future<Either<Failure, Reminder>> updateReminder(Reminder reminder);

  /// Deletes a reminder
  Future<Either<Failure, void>> deleteReminder(String id);

  /// Marks a reminder as completed
  Future<Either<Failure, Reminder>> markAsComplete(String id);

  /// Schedules notification for a reminder
  Future<Either<Failure, void>> scheduleNotification(Reminder reminder);
}
