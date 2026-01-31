import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_datasource.dart';
import '../datasources/notification_datasource.dart';
import '../models/reminder_model.dart';


/// Implementation of ReminderRepository
class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderLocalDataSource _localDataSource;
  final NotificationDataSource _notificationDataSource;

  ReminderRepositoryImpl({
    required ReminderLocalDataSource localDataSource,
    required NotificationDataSource notificationDataSource,
  })  : _localDataSource = localDataSource,
        _notificationDataSource = notificationDataSource;

  @override
  Future<Either<Failure, Reminder>> createReminder(Reminder reminder) async {
    try {
      final reminderModel = ReminderModel.fromEntity(reminder);
      await _localDataSource.saveReminder(reminderModel);
      
      // Schedule notification
      await _notificationDataSource.scheduleNotification(reminder);
      
      return Right(reminder);
    } catch (e) {
      return Left(CacheFailure('Failed to create reminder: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getAllReminders() async {
    try {
      final reminders = await _localDataSource.getAllReminders();
      return Right(reminders.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get reminders: $e'));
    }
  }

  @override
  Future<Either<Failure, Reminder>> getReminderById(String id) async {
    try {
      final reminder = await _localDataSource.getReminderById(id);
      if (reminder == null) {
        return Left(CacheFailure('Reminder not found'));
      }
      return Right(reminder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get reminder: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getUpcomingReminders() async {
    try {
      final reminders = await _localDataSource.getUpcomingReminders();
      return Right(reminders.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get upcoming reminders: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getOverdueReminders() async {
    try {
      final reminders = await _localDataSource.getOverdueReminders();
      return Right(reminders.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get overdue reminders: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getRemindersByType(ReminderType type) async {
    try {
      final reminders = await _localDataSource.getRemindersByType(type);
      return Right(reminders.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get reminders by type: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getRemindersByDocument(String documentId) async {
    try {
      final reminders = await _localDataSource.getRemindersByDocument(documentId);
      return Right(reminders.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get reminders by document: $e'));
    }
  }

  @override
  Future<Either<Failure, Reminder>> updateReminder(Reminder reminder) async {
    try {
      final reminderModel = ReminderModel.fromEntity(reminder);
      await _localDataSource.updateReminder(reminderModel);
      
      // Reschedule notification if date changed
      if (!reminder.isCompleted) {
        await _notificationDataSource.cancelNotification(reminder.id);
        await _notificationDataSource.scheduleNotification(reminder);
      }
      
      return Right(reminder);
    } catch (e) {
      return Left(CacheFailure('Failed to update reminder: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReminder(String id) async {
    try {
      await _notificationDataSource.cancelNotification(id);
      await _localDataSource.deleteReminder(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete reminder: $e'));
    }
  }

  @override
  Future<Either<Failure, Reminder>> markAsComplete(String id) async {
    try {
      final reminderResult = await getReminderById(id);
      return reminderResult.fold(
        (failure) => Left(failure),
        (reminder) async {
          final updatedReminder = reminder.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Cancel notification
          await _notificationDataSource.cancelNotification(id);
          
          // If recurring, create next occurrence
          if (reminder.isRecurring && reminder.recurrencePattern != ReminderType.none) {
            final nextDate = reminder.getNextOccurrence();
            final nextReminder = reminder.copyWith(
              id: '${reminder.id}_${DateTime.now().millisecondsSinceEpoch}',
              reminderDate: nextDate,
              isCompleted: false,
              completedAt: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await createReminder(nextReminder);
          }
          
          return await updateReminder(updatedReminder);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to mark reminder as complete: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleNotification(Reminder reminder) async {
    try {
      await _notificationDataSource.scheduleNotification(reminder);
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure('Failed to schedule notification: $e'));
    }
  }
}
