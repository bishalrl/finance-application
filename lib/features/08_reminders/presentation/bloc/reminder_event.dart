import 'package:equatable/equatable.dart';
import '../../domain/entities/reminder.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class LoadReminders extends ReminderEvent {
  const LoadReminders();
}

class CreateReminderEvent extends ReminderEvent {
  final String title;
  final String? description;
  final DateTime reminderDate;
  final ReminderType type;
  final bool isRecurring;
  final RecurrencePattern recurrencePattern;

  const CreateReminderEvent({
    required this.title,
    this.description,
    required this.reminderDate,
    required this.type,
    this.isRecurring = false,
    this.recurrencePattern = RecurrencePattern.none,
  });

  @override
  List<Object?> get props => [title, description, reminderDate, type, isRecurring, recurrencePattern];
}

class MarkReminderCompleteEvent extends ReminderEvent {
  final String id;

  const MarkReminderCompleteEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteReminderEvent extends ReminderEvent {
  final String id;

  const DeleteReminderEvent(this.id);

  @override
  List<Object?> get props => [id];
}
