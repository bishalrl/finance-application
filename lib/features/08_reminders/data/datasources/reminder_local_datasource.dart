import 'package:hive/hive.dart';
import 'package:life_vault/core/database/hive_service.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';
import '../models/reminder_model.dart';

/// Local data source for reminder operations
class ReminderLocalDataSource {
  final HiveService _hiveService;

  ReminderLocalDataSource(this._hiveService);

  /// Saves a reminder
  Future<void> saveReminder(ReminderModel reminder) async {
    try {
      final box = _hiveService.getBox(HiveService.remindersBox);
      await box.put(reminder.id, reminder);
    } catch (e) {
      throw ReminderStorageException('Failed to save reminder: $e');
    }
  }

  /// Gets a reminder by ID
  Future<ReminderModel?> getReminderById(String id) async {
    try {
      final box = _hiveService.getBox(HiveService.remindersBox);
      return box.get(id) as ReminderModel?;
    } catch (e) {
      throw ReminderStorageException('Failed to get reminder: $e');
    }
  }

  /// Gets all reminders
  Future<List<ReminderModel>> getAllReminders() async {
    try {
      final box = _hiveService.getBox(HiveService.remindersBox);
      return box.values.cast<ReminderModel>().toList();
    } catch (e) {
      throw ReminderStorageException('Failed to get all reminders: $e');
    }
  }

  /// Gets upcoming reminders (not completed, future dates)
  Future<List<ReminderModel>> getUpcomingReminders() async {
    try {
      final allReminders = await getAllReminders();
      final now = DateTime.now();
      return allReminders.where((reminder) => 
        !reminder.isCompleted && reminder.reminderDate.isAfter(now)
      ).toList()..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    } catch (e) {
      throw ReminderStorageException('Failed to get upcoming reminders: $e');
    }
  }

  /// Gets overdue reminders
  Future<List<ReminderModel>> getOverdueReminders() async {
    try {
      final allReminders = await getAllReminders();
      final now = DateTime.now();
      return allReminders.where((reminder) => 
        !reminder.isCompleted && reminder.reminderDate.isBefore(now)
      ).toList();
    } catch (e) {
      throw ReminderStorageException('Failed to get overdue reminders: $e');
    }
  }

  /// Gets reminders by type
  Future<List<ReminderModel>> getRemindersByType(ReminderType type) async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((reminder) => reminder.type == type).toList();
    } catch (e) {
      throw ReminderStorageException('Failed to get reminders by type: $e');
    }
  }

  /// Gets reminders linked to a document
  Future<List<ReminderModel>> getRemindersByDocument(String documentId) async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((reminder) => 
        reminder.linkedDocumentId == documentId
      ).toList();
    } catch (e) {
      throw ReminderStorageException('Failed to get reminders by document: $e');
    }
  }

  /// Deletes a reminder
  Future<void> deleteReminder(String id) async {
    try {
      final box = _hiveService.getBox(HiveService.remindersBox);
      await box.delete(id);
    } catch (e) {
      throw ReminderStorageException('Failed to delete reminder: $e');
    }
  }

  /// Updates a reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await saveReminder(reminder);
    } catch (e) {
      throw ReminderStorageException('Failed to update reminder: $e');
    }
  }
}

class ReminderStorageException implements Exception {
  final String message;
  ReminderStorageException(this.message);
  
  @override
  String toString() => 'ReminderStorageException: $message';
}
