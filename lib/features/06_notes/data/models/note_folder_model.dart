import 'package:hive/hive.dart';
import '../../domain/entities/note_folder.dart';



@HiveType(typeId: 4)
class NoteFolderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? parentFolderId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final int noteCount;

  NoteFolderModel({
    required this.id,
    required this.name,
    this.parentFolderId,
    required this.createdAt,
    this.noteCount = 0,
  });

  factory NoteFolderModel.fromEntity(NoteFolder entity) {
    return NoteFolderModel(
      id: entity.id,
      name: entity.name,
      parentFolderId: entity.parentFolderId,
      createdAt: entity.createdAt,
      noteCount: entity.noteCount,
    );
  }

  NoteFolder toEntity() {
    return NoteFolder(
      id: id,
      name: name,
      parentFolderId: parentFolderId,
      createdAt: createdAt,
      noteCount: noteCount,
    );
  }
}
