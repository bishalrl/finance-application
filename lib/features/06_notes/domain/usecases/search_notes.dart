import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/failures.dart';

class SearchNotes {
  final NoteRepository repository;
  SearchNotes(this.repository);

  Future<Either<Failure, List<Note>>> call(String query) async {
    if (query.trim().isEmpty) {
      return await repository.getAllNotes();
    }
    return await repository.searchNotes(query);
  }
}
