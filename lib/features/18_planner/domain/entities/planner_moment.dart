import 'package:equatable/equatable.dart';

/// Type of planner moment — event, bill, or milestone.
enum MomentType {
  event,
  bill,
  milestone,
}

/// Status: upcoming, past, or acknowledged. No completed/failed.
enum MomentStatus {
  upcoming,
  past,
  acknowledged,
}

/// Soft importance (optional). No urgency bias.
enum MomentImportance {
  low,
  normal,
  high,
}

/// A planner moment: event, reminder, bill, or milestone.
/// Core unit is "what matters", not tasks. No red alerts, no punishment.
class PlannerMoment extends Equatable {
  final String id;
  final MomentType type;
  final String title;
  final String? note;
  final DateTime date;
  final DateTime? dateEnd; // optional range
  final DateTime? reminderAt;
  final MomentStatus status;
  final MomentImportance importance;
  /// For bills: optional amount
  final double? amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Recurring: e.g. daily habit — appears on that day, no backlog
  final bool isRecurring;
  final String? recurrenceRule; // e.g. 'daily', 'weekly'

  const PlannerMoment({
    required this.id,
    required this.type,
    required this.title,
    this.note,
    required this.date,
    this.dateEnd,
    this.reminderAt,
    required this.status,
    this.importance = MomentImportance.normal,
    this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  bool get isPast => date.isBefore(DateTime.now()) && (dateEnd == null || (dateEnd != null && dateEnd!.isBefore(DateTime.now())));
  bool get isUpcoming => !isPast && status != MomentStatus.acknowledged;
  bool get isRange => dateEnd != null;

  PlannerMoment copyWith({
    String? id,
    MomentType? type,
    String? title,
    String? note,
    DateTime? date,
    DateTime? dateEnd,
    DateTime? reminderAt,
    MomentStatus? status,
    MomentImportance? importance,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurrenceRule,
  }) {
    return PlannerMoment(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      dateEnd: dateEnd ?? this.dateEnd,
      reminderAt: reminderAt ?? this.reminderAt,
      status: status ?? this.status,
      importance: importance ?? this.importance,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        note,
        date,
        dateEnd,
        reminderAt,
        status,
        importance,
        amount,
        createdAt,
        updatedAt,
        isRecurring,
        recurrenceRule,
      ];
}
