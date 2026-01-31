import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/note.dart';
import '../entities/note_folder.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class OrganizeInFolders {
  final NoteRepository repository;
  OrganizeInFolders(this.repository);

  Future<Either<Failure, NoteFolder>> createFolder(String name, {String? parentFolderId}) async {
    final folder = NoteFolder(
      id: const Uuid().v4(),
      name: name,
      parentFolderId: parentFolderId,
      createdAt: DateTime.now(),
    );
    return await repository.createFolder(folder);
  }

  Future<Either<Failure, Note>> moveNoteToFolder(Note note, String? folderId) async {
    final updatedNote = note.copyWith(folderId: folderId);
    return await repository.updateNote(updatedNote);
  }
}
