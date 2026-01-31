import 'package:equatable/equatable.dart';

/// A project is a living thought, not a delivery pipeline.
/// Answers: "Why am I doing this?" "Do I still care?"
/// No task list, no velocity, no overdue.
class Project extends Equatable {
  final String id;
  final String title;
  final String vision;
  final List<String> notes;
  final List<String> attachmentIds;
  final int likes;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.title,
    this.vision = '',
    this.notes = const [],
    this.attachmentIds = const [],
    this.likes = 0,
    this.lastReviewedAt,
    this.nextReviewDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get needsReview {
    if (nextReviewDate == null) return false;
    return DateTime.now().isAfter(nextReviewDate!);
  }

  Project copyWith({
    String? id,
    String? title,
    String? vision,
    List<String>? notes,
    List<String>? attachmentIds,
    int? likes,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      vision: vision ?? this.vision,
      notes: notes ?? this.notes,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      likes: likes ?? this.likes,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        vision,
        notes,
        attachmentIds,
        likes,
        lastReviewedAt,
        nextReviewDate,
        createdAt,
        updatedAt,
      ];
}
