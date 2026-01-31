import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/planner_moment.dart';
import '../../domain/usecases/get_today_moments.dart';
import '../../domain/usecases/get_moments_for_day.dart';
import '../../domain/usecases/get_moments_in_range.dart';
import '../../domain/usecases/create_moment.dart';
import '../../domain/usecases/update_moment.dart';
import '../../domain/usecases/acknowledge_moment.dart';
import '../../domain/usecases/delete_moment.dart';
import '../../domain/usecases/snooze_moment.dart';
import 'planner_event.dart';
import 'planner_state.dart';

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final GetTodayMoments getTodayMoments;
  final GetMomentsForDay getMomentsForDay;
  final GetMomentsInRange getMomentsInRange;
  final CreateMoment createMoment;
  final UpdateMoment updateMoment;
  final AcknowledgeMoment acknowledgeMoment;
  final DeleteMoment deleteMoment;
  final SnoozeMoment snoozeMoment;

  PlannerBloc({
    required this.getTodayMoments,
    required this.getMomentsForDay,
    required this.getMomentsInRange,
    required this.createMoment,
    required this.updateMoment,
    required this.acknowledgeMoment,
    required this.deleteMoment,
    required this.snoozeMoment,
  }) : super(const PlannerState()) {
    on<LoadTodayMoments>(_onLoadTodayMoments);
    on<LoadMomentsForDay>(_onLoadMomentsForDay);
    on<LoadMomentsInRange>(_onLoadMomentsInRange);
    on<CreateMomentEvent>(_onCreateMoment);
    on<UpdateMomentEvent>(_onUpdateMoment);
    on<AcknowledgeMomentEvent>(_onAcknowledgeMoment);
    on<SnoozeMomentEvent>(_onSnoozeMoment);
    on<DeleteMomentEvent>(_onDeleteMoment);
    on<RefreshPlanner>(_onRefreshPlanner);
  }

  Future<void> _onLoadTodayMoments(LoadTodayMoments event, Emitter<PlannerState> emit) async {
    emit(state.copyWith(status: PlannerStatus.loading, errorMessage: null));
    final result = await getTodayMoments();
    result.fold(
      (failure) => emit(state.copyWith(
            status: PlannerStatus.error,
            errorMessage: failure.toString(),
            todayMoments: [],
          )),
      (list) => emit(state.copyWith(
            status: PlannerStatus.loaded,
            todayMoments: list,
            selectedDay: null,
            selectedDayMoments: [],
            rangeStart: null,
            rangeEnd: null,
            rangeMoments: [],
            errorMessage: null,
          )),
    );
  }

  Future<void> _onLoadMomentsForDay(LoadMomentsForDay event, Emitter<PlannerState> emit) async {
    emit(state.copyWith(status: PlannerStatus.loading, errorMessage: null));
    final result = await getMomentsForDay(event.day);
    result.fold(
      (failure) => emit(state.copyWith(
            status: PlannerStatus.error,
            errorMessage: failure.toString(),
            selectedDayMoments: [],
          )),
      (list) => emit(state.copyWith(
            status: PlannerStatus.loaded,
            selectedDay: event.day,
            selectedDayMoments: list,
            rangeStart: null,
            rangeEnd: null,
            rangeMoments: [],
            errorMessage: null,
          )),
    );
  }

  Future<void> _onLoadMomentsInRange(LoadMomentsInRange event, Emitter<PlannerState> emit) async {
    emit(state.copyWith(status: PlannerStatus.loading, errorMessage: null));
    final result = await getMomentsInRange(event.start, event.end);
    result.fold(
      (failure) => emit(state.copyWith(
            status: PlannerStatus.error,
            errorMessage: failure.toString(),
            rangeMoments: [],
          )),
      (list) => emit(state.copyWith(
            status: PlannerStatus.loaded,
            rangeStart: event.start,
            rangeEnd: event.end,
            rangeMoments: list,
            selectedDay: null,
            selectedDayMoments: [],
            errorMessage: null,
          )),
    );
  }

  Future<void> _onCreateMoment(CreateMomentEvent event, Emitter<PlannerState> emit) async {
    final result = await createMoment(
      type: event.type,
      title: event.title,
      note: event.note,
      date: event.date,
      dateEnd: event.dateEnd,
      reminderAt: event.reminderAt,
      importance: event.importance,
      amount: event.amount,
      isRecurring: event.isRecurring,
      recurrenceRule: event.recurrenceRule,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadTodayMoments()),
    );
  }

  Future<void> _onUpdateMoment(UpdateMomentEvent event, Emitter<PlannerState> emit) async {
    final result = await updateMoment(event.moment);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadTodayMoments()),
    );
  }

  Future<void> _onAcknowledgeMoment(AcknowledgeMomentEvent event, Emitter<PlannerState> emit) async {
    final result = await acknowledgeMoment(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadTodayMoments()),
    );
  }

  Future<void> _onSnoozeMoment(SnoozeMomentEvent event, Emitter<PlannerState> emit) async {
    final result = await snoozeMoment(event.id, event.newReminderAt);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadTodayMoments()),
    );
  }

  Future<void> _onDeleteMoment(DeleteMomentEvent event, Emitter<PlannerState> emit) async {
    final result = await deleteMoment(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadTodayMoments()),
    );
  }

  Future<void> _onRefreshPlanner(RefreshPlanner event, Emitter<PlannerState> emit) async {
    if (state.selectedDay != null) {
      add(LoadMomentsForDay(state.selectedDay!));
    } else if (state.rangeStart != null && state.rangeEnd != null) {
      add(LoadMomentsInRange(state.rangeStart!, state.rangeEnd!));
    } else {
      add(const LoadTodayMoments());
    }
  }
}
