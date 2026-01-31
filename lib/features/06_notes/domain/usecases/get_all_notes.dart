import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class GetAllNotes {
  final NoteRepository repository;
  GetAllNotes(this.repository);

  Future<Either<Failure, List<Note>>> call() async {
    return await repository.getAllNotes();
  }
}
