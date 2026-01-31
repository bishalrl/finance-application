import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class GetNoteById {
  final NoteRepository repository;

  GetNoteById(this.repository);

  Future<Either<Failure, Note>> call(String id) async {
    return await repository.getNoteById(id);
  }
}
