import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';
import 'package:life_vault/features/08_reminders/domain/usecases/create_reminder.dart';
import 'package:life_vault/features/08_reminders/presentation/bloc/reminder_bloc.dart';
import 'package:life_vault/features/08_reminders/presentation/bloc/reminder_event.dart' as reminder_list_event;

part 'add_reminder_event.dart';
part 'add_reminder_state.dart';

class AddReminderBloc extends Bloc<AddReminderEvent, AddReminderState> {
  final CreateReminder _createReminder;
  final ReminderBloc _reminderBloc;

  AddReminderBloc({
    required CreateReminder createReminder,
    required ReminderBloc reminderBloc,
  })  : _createReminder = createReminder,
        _reminderBloc = reminderBloc,
        super(AddReminderInitial()) {
    on<TitleChanged>(_onTitleChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<DateChanged>(_onDateChanged);
    on<TimeChanged>(_onTimeChanged);
    on<TypeChanged>(_onTypeChanged);
    on<SubmitReminder>(_onSubmitReminder);
    on<ResetAddReminderState>(_onResetAddReminderState);
  }

  void _onTitleChanged(TitleChanged event, Emitter<AddReminderState> emit) {
    emit((state as AddReminderInitial).copyWith(title: event.title, errorMessage: null));
  }

  void _onDescriptionChanged(DescriptionChanged event, Emitter<AddReminderState> emit) {
    emit((state as AddReminderInitial).copyWith(description: event.description, errorMessage: null));
  }

  void _onDateChanged(DateChanged event, Emitter<AddReminderState> emit) {
    final currentState = state as AddReminderInitial;
    final newDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      currentState.reminderDate.hour,
      currentState.reminderDate.minute,
    );
    emit(currentState.copyWith(reminderDate: newDate, errorMessage: null));
  }

  void _onTimeChanged(TimeChanged event, Emitter<AddReminderState> emit) {
    final currentState = state as AddReminderInitial;
    final newTime = DateTime(
      currentState.reminderDate.year,
      currentState.reminderDate.month,
      currentState.reminderDate.day,
      event.time.hour,
      event.time.minute,
    );
    emit(currentState.copyWith(reminderDate: newTime, errorMessage: null));
  }

  void _onTypeChanged(TypeChanged event, Emitter<AddReminderState> emit) {
    emit((state as AddReminderInitial).copyWith(type: event.type, errorMessage: null));
  }

  Future<void> _onSubmitReminder(SubmitReminder event, Emitter<AddReminderState> emit) async {
    final currentState = state as AddReminderInitial;

    if (currentState.title.trim().isEmpty) {
      emit(currentState.copyWith(errorMessage: 'Title is required'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _createReminder(
      title: currentState.title,
      description: currentState.description.trim().isEmpty ? null : currentState.description.trim(),
      reminderDate: currentState.reminderDate,
      type: currentState.type,
      isRecurring: false, // Assuming non-recurring for now
      recurrencePattern: RecurrencePattern.none, // Assuming no recurrence for now
    );

    result.fold(
      (failure) => emit(AddReminderFailure(failure.message)),
      (_) {
        _reminderBloc.add(const reminder_list_event.LoadReminders()); // Refresh reminders list
        emit(AddReminderSuccess());
      },
    );
  }

  void _onResetAddReminderState(ResetAddReminderState event, Emitter<AddReminderState> emit) {
    emit(AddReminderInitial());
  }
}
