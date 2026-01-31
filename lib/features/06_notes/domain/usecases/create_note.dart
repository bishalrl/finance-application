import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class CreateNote {
  final NoteRepository repository;
  CreateNote(this.repository);

  Future<Either<Failure, Note>> call({
    required String title,
    required String content,
    String? folderId,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      folderId: folderId,
      tags: tags,
    );
    return await repository.createNote(note);
  }
}
