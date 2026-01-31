import 'package:equatable/equatable.dart';

enum IdeaStatus { inbox, inProgress, completed, archived }

class Idea extends Equatable {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final int likes;
  final IdeaStatus status;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Idea({
    required this.id,
    required this.title,
    this.description,
    this.tags = const [],
    this.likes = 0,
    this.status = IdeaStatus.inbox,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  Idea copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    int? likes,
    IdeaStatus? status,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, tags, likes, status, projectId, createdAt, updatedAt];
}
