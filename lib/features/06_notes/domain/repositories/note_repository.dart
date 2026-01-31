import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../entities/note_folder.dart';
import '../../../../core/errors/failures.dart';

abstract class NoteRepository {
  Future<Either<Failure, Note>> createNote(Note note);
  Future<Either<Failure, List<Note>>> getAllNotes();
  Future<Either<Failure, Note>> getNoteById(String id);
  Future<Either<Failure, Note>> updateNote(Note note);
  Future<Either<Failure, void>> deleteNote(String id);
  Future<Either<Failure, List<Note>>> searchNotes(String query);
  Future<Either<Failure, List<Note>>> getNotesByFolder(String? folderId);
  Future<Either<Failure, List<Note>>> getStarredNotes();
  Future<Either<Failure, NoteFolder>> createFolder(NoteFolder folder);
  Future<Either<Failure, List<NoteFolder>>> getAllFolders();
}
