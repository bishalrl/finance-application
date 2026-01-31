import 'package:equatable/equatable.dart';

/// Reminder type enum
enum ReminderType {
  billPayment,
  documentExpiry,
  subscription,
  custom, none,
}

/// Recurrence pattern enum
enum RecurrencePattern {
  daily,
  weekly,
  monthly,
  yearly,
  none,
}

/// Reminder entity
class Reminder extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime reminderDate;
  final ReminderType type;
  final bool isRecurring;
  final RecurrencePattern recurrencePattern;
  final bool isCompleted;
  final String? linkedDocumentId;
  final double? amount; // For bill payments
  final String? merchant; // For bill payments/subscriptions
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.reminderDate,
    required this.type,
    this.isRecurring = false,
    this.recurrencePattern = RecurrencePattern.none,
    this.isCompleted = false,
    this.linkedDocumentId,
    this.amount,
    this.merchant,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Gets the next occurrence date for recurring reminders
  DateTime getNextOccurrence() {
    if (!isRecurring || recurrencePattern == RecurrencePattern.none) {
      return reminderDate;
    }

    final now = DateTime.now();
    DateTime next = reminderDate;

    // Calculate next occurrence
    while (next.isBefore(now)) {
      next = _addRecurrence(next);
    }

    return next;
  }

  /// Adds recurrence period to a date
  DateTime _addRecurrence(DateTime date) {
    switch (recurrencePattern) {
      case RecurrencePattern.daily:
        return date.add(const Duration(days: 1));
      case RecurrencePattern.weekly:
        return date.add(const Duration(days: 7));
      case RecurrencePattern.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurrencePattern.yearly:
        return DateTime(date.year + 1, date.month, date.day);
      case RecurrencePattern.none:
        return date;
    }
  }

  /// Checks if reminder is overdue
  bool get isOverdue => !isCompleted && reminderDate.isBefore(DateTime.now());

  /// Gets days until reminder (negative if overdue)
  int get daysUntilReminder {
    final diff = reminderDate.difference(DateTime.now()).inDays;
    return diff;
  }

  /// Gets urgency level: 'high', 'medium', 'low'
  String get urgencyLevel {
    if (isOverdue) return 'high';
    final days = daysUntilReminder;
    if (days <= 3) return 'high';
    if (days <= 7) return 'medium';
    return 'low';
  }

  /// Creates a copy with updated fields
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderDate,
    ReminderType? type,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
    bool? isCompleted,
    String? linkedDocumentId,
    double? amount,
    String? merchant,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedDocumentId: linkedDocumentId ?? this.linkedDocumentId,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        reminderDate,
        type,
        isRecurring,
        recurrencePattern,
        isCompleted,
        linkedDocumentId,
        amount,
        merchant,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
