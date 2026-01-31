import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class UpdateNote {
  final NoteRepository repository;
  UpdateNote(this.repository);

  Future<Either<Failure, Note>> call(Note note) async {
    return await repository.updateNote(note);
  }
}
