import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/usecases/get_all_reminders.dart';
import '../../domain/usecases/create_reminder.dart';
import '../../domain/usecases/mark_as_complete.dart';
import '../../domain/usecases/delete_reminder.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final GetAllReminders getAllReminders;
  final CreateReminder createReminder;
  final MarkAsComplete markAsComplete;
  final DeleteReminder deleteReminder;

  ReminderBloc({
    required this.getAllReminders,
    required this.createReminder,
    required this.markAsComplete,
    required this.deleteReminder,
  }) : super(const ReminderState()) {
    on<LoadReminders>(_onLoadReminders);
    on<CreateReminderEvent>(_onCreateReminder);
    on<MarkReminderCompleteEvent>(_onMarkComplete);
    on<DeleteReminderEvent>(_onDeleteReminder);
  }

  Future<void> _onLoadReminders(LoadReminders event, Emitter<ReminderState> emit) async {
    emit(state.copyWith(status: ReminderListStatus.loading, errorMessage: null));
    final result = await getAllReminders();
    result.fold(
      (failure) => emit(state.copyWith(
            status: ReminderListStatus.error,
            errorMessage: failure.toString(),
            reminders: [],
          )),
      (List<Reminder> list) => emit(state.copyWith(
            status: ReminderListStatus.loaded,
            reminders: list,
            errorMessage: null,
          )),
    );
  }

  Future<void> _onCreateReminder(CreateReminderEvent event, Emitter<ReminderState> emit) async {
    final result = await createReminder(
      title: event.title,
      description: event.description,
      reminderDate: event.reminderDate,
      type: event.type,
      isRecurring: event.isRecurring,
      recurrencePattern: event.recurrencePattern,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadReminders()),
    );
  }

  Future<void> _onMarkComplete(MarkReminderCompleteEvent event, Emitter<ReminderState> emit) async {
    final result = await markAsComplete(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadReminders()),
    );
  }

  Future<void> _onDeleteReminder(DeleteReminderEvent event, Emitter<ReminderState> emit) async {
    final result = await deleteReminder(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadReminders()),
    );
  }
}
