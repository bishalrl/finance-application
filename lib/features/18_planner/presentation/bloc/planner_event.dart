import 'package:equatable/equatable.dart';
import '../../domain/entities/planner_moment.dart';

abstract class PlannerEvent extends Equatable {
  const PlannerEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodayMoments extends PlannerEvent {
  const LoadTodayMoments();
}

class LoadMomentsForDay extends PlannerEvent {
  final DateTime day;

  const LoadMomentsForDay(this.day);

  @override
  List<Object?> get props => [day];
}

class LoadMomentsInRange extends PlannerEvent {
  final DateTime start;
  final DateTime end;

  const LoadMomentsInRange(this.start, this.end);

  @override
  List<Object?> get props => [start, end];
}

class CreateMomentEvent extends PlannerEvent {
  final MomentType type;
  final String title;
  final String? note;
  final DateTime date;
  final DateTime? dateEnd;
  final DateTime? reminderAt;
  final MomentImportance importance;
  final double? amount;
  final bool isRecurring;
  final String? recurrenceRule;

  const CreateMomentEvent({
    required this.type,
    required this.title,
    this.note,
    required this.date,
    this.dateEnd,
    this.reminderAt,
    this.importance = MomentImportance.normal,
    this.amount,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  @override
  List<Object?> get props => [type, title, note, date, dateEnd, reminderAt, importance, amount, isRecurring, recurrenceRule];
}

class UpdateMomentEvent extends PlannerEvent {
  final PlannerMoment moment;

  const UpdateMomentEvent(this.moment);

  @override
  List<Object?> get props => [moment];
}

class AcknowledgeMomentEvent extends PlannerEvent {
  final String id;

  const AcknowledgeMomentEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SnoozeMomentEvent extends PlannerEvent {
  final String id;
  final DateTime newReminderAt;

  const SnoozeMomentEvent(this.id, this.newReminderAt);

  @override
  List<Object?> get props => [id, newReminderAt];
}

class DeleteMomentEvent extends PlannerEvent {
  final String id;

  const DeleteMomentEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshPlanner extends PlannerEvent {
  const RefreshPlanner();
}
