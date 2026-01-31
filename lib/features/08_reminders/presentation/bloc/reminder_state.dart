import 'package:equatable/equatable.dart';
import '../../domain/entities/reminder.dart';

enum ReminderListStatus { initial, loading, loaded, error }

class ReminderState extends Equatable {
  final ReminderListStatus status;
  final List<Reminder> reminders;
  final String? errorMessage;

  const ReminderState({
    this.status = ReminderListStatus.initial,
    this.reminders = const [],
    this.errorMessage,
  });

  ReminderState copyWith({
    ReminderListStatus? status,
    List<Reminder>? reminders,
    String? errorMessage,
  }) {
    return ReminderState(
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, reminders, errorMessage];
}
