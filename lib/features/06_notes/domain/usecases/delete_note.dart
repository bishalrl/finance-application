import 'package:dartz/dartz.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class DeleteNote {
  final NoteRepository repository;

  DeleteNote(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteNote(id);
  }
}
