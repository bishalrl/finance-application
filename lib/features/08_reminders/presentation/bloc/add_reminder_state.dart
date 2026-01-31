part of 'add_reminder_bloc.dart';

@immutable
sealed class AddReminderState {}

class AddReminderInitial extends AddReminderState {
  final String title;
  final String description;
  final DateTime reminderDate;
  final ReminderType type;
  final bool isSubmitting;
  final String? errorMessage;

  AddReminderInitial({
    this.title = '',
    this.description = '',
    DateTime? reminderDate,
    this.type = ReminderType.custom,
    this.isSubmitting = false,
    this.errorMessage,
  }) : reminderDate = reminderDate ?? DateTime.now().add(const Duration(hours: 1));

  AddReminderInitial copyWith({
    String? title,
    String? description,
    DateTime? reminderDate,
    ReminderType? type,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AddReminderInitial(
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      type: type ?? this.type,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class AddReminderSuccess extends AddReminderState {}

class AddReminderFailure extends AddReminderState {
  final String message;

  AddReminderFailure(this.message);
}
