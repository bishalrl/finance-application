import 'package:hive/hive.dart';
import '../../domain/entities/reminder.dart';


@HiveType(typeId: 2)
class ReminderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime reminderDate;

  @HiveField(4)
  final ReminderType type;

  @HiveField(5)
  final bool isRecurring;

  @HiveField(6)
  final RecurrencePattern recurrencePattern;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final String? linkedDocumentId;

  @HiveField(9)
  final double? amount;

  @HiveField(10)
  final String? merchant;

  @HiveField(11)
  final DateTime? completedAt;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  ReminderModel({
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

  /// Converts entity to model
  factory ReminderModel.fromEntity(Reminder entity) {
    return ReminderModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      reminderDate: entity.reminderDate,
      type: entity.type,
      isRecurring: entity.isRecurring,
      recurrencePattern: entity.recurrencePattern,
      isCompleted: entity.isCompleted,
      linkedDocumentId: entity.linkedDocumentId,
      amount: entity.amount,
      merchant: entity.merchant,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts model to entity
  Reminder toEntity() {
    return Reminder(
      id: id,
      title: title,
      description: description,
      reminderDate: reminderDate,
      type: type,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      isCompleted: isCompleted,
      linkedDocumentId: linkedDocumentId,
      amount: amount,
      merchant: merchant,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
