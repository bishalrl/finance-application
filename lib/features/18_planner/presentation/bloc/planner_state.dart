import 'package:equatable/equatable.dart';
import '../../domain/entities/planner_moment.dart';

enum PlannerStatus { initial, loading, loaded, error }

class PlannerState extends Equatable {
  final PlannerStatus status;
  final List<PlannerMoment> todayMoments;
  final List<PlannerMoment> selectedDayMoments;
  final DateTime? selectedDay;
  final List<PlannerMoment> rangeMoments;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final String? errorMessage;

  const PlannerState({
    this.status = PlannerStatus.initial,
    this.todayMoments = const [],
    this.selectedDayMoments = const [],
    this.selectedDay,
    this.rangeMoments = const [],
    this.rangeStart,
    this.rangeEnd,
    this.errorMessage,
  });

  PlannerState copyWith({
    PlannerStatus? status,
    List<PlannerMoment>? todayMoments,
    List<PlannerMoment>? selectedDayMoments,
    DateTime? selectedDay,
    List<PlannerMoment>? rangeMoments,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? errorMessage,
  }) {
    return PlannerState(
      status: status ?? this.status,
      todayMoments: todayMoments ?? this.todayMoments,
      selectedDayMoments: selectedDayMoments ?? this.selectedDayMoments,
      selectedDay: selectedDay ?? this.selectedDay,
      rangeMoments: rangeMoments ?? this.rangeMoments,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      errorMessage: errorMessage,
    );
  }

  List<PlannerMoment> get displayMoments {
    if (selectedDay != null && selectedDayMoments.isNotEmpty) return selectedDayMoments;
    if (rangeStart != null && rangeEnd != null && rangeMoments.isNotEmpty) return rangeMoments;
    return todayMoments;
  }

  @override
  List<Object?> get props => [
        status,
        todayMoments,
        selectedDayMoments,
        selectedDay,
        rangeMoments,
        rangeStart,
        rangeEnd,
        errorMessage,
      ];
}
