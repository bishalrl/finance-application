import 'package:equatable/equatable.dart';

/// Note folder entity for organization
class NoteFolder extends Equatable {
  final String id;
  final String name;
  final String? parentFolderId;
  final DateTime createdAt;
  final int noteCount;

  const NoteFolder({
    required this.id,
    required this.name,
    this.parentFolderId,
    required this.createdAt,
    this.noteCount = 0,
  });

  @override
  List<Object?> get props => [id, name, parentFolderId, createdAt, noteCount];
}
