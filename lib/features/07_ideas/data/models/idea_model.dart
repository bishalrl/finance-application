import 'package:hive/hive.dart';
import '../../domain/entities/idea.dart';


@HiveType(typeId: 5)
class IdeaModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final List<String> tags;
  @HiveField(4)
  final int likes;
  @HiveField(5)
  final IdeaStatus status;
  @HiveField(6)
  final String? projectId;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;

  IdeaModel({
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

  factory IdeaModel.fromEntity(Idea entity) {
    return IdeaModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      tags: List.from(entity.tags),
      likes: entity.likes,
      status: entity.status,
      projectId: entity.projectId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Idea toEntity() {
    return Idea(
      id: id,
      title: title,
      description: description,
      tags: List.from(tags),
      likes: likes,
      status: status,
      projectId: projectId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
