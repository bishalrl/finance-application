import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_folder.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';
import '../models/note_model.dart';
import '../models/note_folder_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource _localDataSource;

  NoteRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Note>> createNote(Note note) async {
    try {
      final model = NoteModel.fromEntity(note);
      await _localDataSource.saveNote(model);
      return Right(note);
    } catch (e) {
      return Left(CacheFailure('Failed to create note: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getAllNotes() async {
    try {
      final notes = await _localDataSource.getAllNotes();
      return Right(notes.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get notes: $e'));
    }
  }

  @override
  Future<Either<Failure, Note>> getNoteById(String id) async {
    try {
      final note = await _localDataSource.getNoteById(id);
      if (note == null) return Left(CacheFailure('Note not found'));
      return Right(note.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get note: $e'));
    }
  }

  @override
  Future<Either<Failure, Note>> updateNote(Note note) async {
    try {
      final model = NoteModel.fromEntity(note.copyWith(updatedAt: DateTime.now()));
      await _localDataSource.saveNote(model);
      return Right(note);
    } catch (e) {
      return Left(CacheFailure('Failed to update note: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      await _localDataSource.deleteNote(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete note: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> searchNotes(String query) async {
    try {
      final notes = await _localDataSource.searchNotes(query);
      return Right(notes.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to search notes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getNotesByFolder(String? folderId) async {
    try {
      final notes = await _localDataSource.getNotesByFolder(folderId);
      return Right(notes.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get notes by folder: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getStarredNotes() async {
    try {
      final notes = await _localDataSource.getStarredNotes();
      return Right(notes.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get starred notes: $e'));
    }
  }

  /// Max folder nesting depth (foundation: "Nested folders allowed, limited depth to avoid chaos").
  static const int maxFolderDepth = 3;

  @override
  Future<Either<Failure, NoteFolder>> createFolder(NoteFolder folder) async {
    try {
      final allFolders = await _localDataSource.getAllFolders();
      NoteFolderModel? findById(String id) {
        for (final f in allFolders) {
          if (f.id == id) return f;
        }
        return null;
      }
      int depthOf(String? parentId) {
        if (parentId == null) return 0;
        final parent = findById(parentId);
        if (parent == null) return 0;
        return 1 + depthOf(parent.parentFolderId);
      }
      final parentDepth = depthOf(folder.parentFolderId);
      if (parentDepth + 1 > maxFolderDepth) {
        return Left(ValidationFailure(
          'Maximum folder depth ($maxFolderDepth) reached. Create folders closer to root.',
        ));
      }
      final model = NoteFolderModel.fromEntity(folder);
      await _localDataSource.saveFolder(model);
      return Right(folder);
    } catch (e) {
      return Left(CacheFailure('Failed to create folder: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NoteFolder>>> getAllFolders() async {
    try {
      final folders = await _localDataSource.getAllFolders();
      return Right(folders.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get folders: $e'));
    }
  }
}
