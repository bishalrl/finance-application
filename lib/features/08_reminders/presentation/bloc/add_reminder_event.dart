part of 'add_reminder_bloc.dart';

@immutable
sealed class AddReminderEvent {}

class TitleChanged extends AddReminderEvent {
  final String title;

  TitleChanged(this.title);
}

class DescriptionChanged extends AddReminderEvent {
  final String description;

  DescriptionChanged(this.description);
}

class DateChanged extends AddReminderEvent {
  final DateTime date;

  DateChanged(this.date);
}

class TimeChanged extends AddReminderEvent {
  final TimeOfDay time;

  TimeChanged(this.time);
}

class TypeChanged extends AddReminderEvent {
  final ReminderType type;

  TypeChanged(this.type);
}

class SubmitReminder extends AddReminderEvent {}

class ResetAddReminderState extends AddReminderEvent {}
