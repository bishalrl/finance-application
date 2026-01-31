import '../../domain/entities/planner_moment.dart';

/// Map-based model for Hive storage (no type adapter).
class PlannerMomentModel {
  static const String keyId = 'id';
  static const String keyType = 'type';
  static const String keyTitle = 'title';
  static const String keyNote = 'note';
  static const String keyDate = 'date';
  static const String keyDateEnd = 'dateEnd';
  static const String keyReminderAt = 'reminderAt';
  static const String keyStatus = 'status';
  static const String keyImportance = 'importance';
  static const String keyAmount = 'amount';
  static const String keyCreatedAt = 'createdAt';
  static const String keyUpdatedAt = 'updatedAt';
  static const String keyIsRecurring = 'isRecurring';
  static const String keyRecurrenceRule = 'recurrenceRule';

  static Map<String, dynamic> toMap(PlannerMoment moment) {
    return {
      keyId: moment.id,
      keyType: moment.type.index,
      keyTitle: moment.title,
      keyNote: moment.note,
      keyDate: moment.date.toIso8601String(),
      keyDateEnd: moment.dateEnd?.toIso8601String(),
      keyReminderAt: moment.reminderAt?.toIso8601String(),
      keyStatus: moment.status.index,
      keyImportance: moment.importance.index,
      keyAmount: moment.amount,
      keyCreatedAt: moment.createdAt.toIso8601String(),
      keyUpdatedAt: moment.updatedAt.toIso8601String(),
      keyIsRecurring: moment.isRecurring,
      keyRecurrenceRule: moment.recurrenceRule,
    };
  }

  static PlannerMoment fromMap(Map<String, dynamic> map) {
    return PlannerMoment(
      id: map[keyId] as String,
      type: MomentType.values[(map[keyType] as int?) ?? 0],
      title: map[keyTitle] as String,
      note: map[keyNote] as String?,
      date: DateTime.parse(map[keyDate] as String),
      dateEnd: map[keyDateEnd] != null ? DateTime.parse(map[keyDateEnd] as String) : null,
      reminderAt: map[keyReminderAt] != null ? DateTime.parse(map[keyReminderAt] as String) : null,
      status: MomentStatus.values[(map[keyStatus] as int?) ?? 0],
      importance: MomentImportance.values[(map[keyImportance] as int?) ?? 1],
      amount: (map[keyAmount] as num?)?.toDouble(),
      createdAt: DateTime.parse(map[keyCreatedAt] as String),
      updatedAt: DateTime.parse(map[keyUpdatedAt] as String),
      isRecurring: map[keyIsRecurring] as bool? ?? false,
      recurrenceRule: map[keyRecurrenceRule] as String?,
    );
  }
}
