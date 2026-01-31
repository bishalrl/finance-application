import '../../domain/entities/project.dart';

/// Map-based model for Hive storage (no type adapter).
class ProjectModel {
  static Map<String, dynamic> toMap(Project project) {
    return {
      'id': project.id,
      'title': project.title,
      'vision': project.vision,
      'notes': project.notes,
      'attachmentIds': project.attachmentIds,
      'likes': project.likes,
      'lastReviewedAt': project.lastReviewedAt?.toIso8601String(),
      'nextReviewDate': project.nextReviewDate?.toIso8601String(),
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
    };
  }

  static Project fromMap(Map<dynamic, dynamic> map) {
    return Project(
      id: map['id'] as String,
      title: map['title'] as String,
      vision: map['vision'] as String? ?? '',
      notes: (map['notes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      attachmentIds: (map['attachmentIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      lastReviewedAt: map['lastReviewedAt'] != null ? DateTime.parse(map['lastReviewedAt'] as String) : null,
      nextReviewDate: map['nextReviewDate'] != null ? DateTime.parse(map['nextReviewDate'] as String) : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
