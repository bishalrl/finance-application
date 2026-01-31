import 'package:hive/hive.dart';
import '../../domain/entities/note.dart';


@HiveType(typeId: 3)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final String? folderId;

  @HiveField(6)
  final List<String> tags;

  @HiveField(7)
  final bool isVault;

  @HiveField(8)
  final bool isStarred;

  @HiveField(9)
  final bool isPinned;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.tags = const [],
    this.isVault = false,
    this.isStarred = false,
    this.isPinned = false,
  });

  factory NoteModel.fromEntity(Note entity) {
    return NoteModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      folderId: entity.folderId,
      tags: List.from(entity.tags),
      isVault: entity.isVault,
      isStarred: entity.isStarred,
      isPinned: entity.isPinned,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      folderId: folderId,
      tags: List.from(tags),
      isVault: isVault,
      isStarred: isStarred,
      isPinned: isPinned,
    );
  }
}
