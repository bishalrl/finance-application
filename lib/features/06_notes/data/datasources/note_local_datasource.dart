import 'package:hive/hive.dart';
import 'package:life_vault/core/database/hive_service.dart';
import '../models/note_model.dart';
import '../models/note_folder_model.dart';

/// Local data source for note operations
class NoteLocalDataSource {
  final HiveService _hiveService;

  NoteLocalDataSource(this._hiveService);

  /// Saves a note
  Future<void> saveNote(NoteModel note) async {
    try {
      final box = _hiveService.getBox(HiveService.notesBox);
      await box.put(note.id, note);
    } catch (e) {
      throw NoteStorageException('Failed to save note: $e');
    }
  }

  /// Gets a note by ID
  Future<NoteModel?> getNoteById(String id) async {
    try {
      final box = _hiveService.getBox(HiveService.notesBox);
      return box.get(id) as NoteModel?;
    } catch (e) {
      throw NoteStorageException('Failed to get note: $e');
    }
  }

  /// Gets all notes
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final box = _hiveService.getBox(HiveService.notesBox);
      return box.values.cast<NoteModel>().toList();
    } catch (e) {
      throw NoteStorageException('Failed to get all notes: $e');
    }
  }

  /// Gets notes by folder
  Future<List<NoteModel>> getNotesByFolder(String? folderId) async {
    try {
      final allNotes = await getAllNotes();
      return allNotes.where((note) => note.folderId == folderId).toList();
    } catch (e) {
      throw NoteStorageException('Failed to get notes by folder: $e');
    }
  }

  /// Gets starred notes
  Future<List<NoteModel>> getStarredNotes() async {
    try {
      final allNotes = await getAllNotes();
      return allNotes.where((note) => note.isStarred).toList();
    } catch (e) {
      throw NoteStorageException('Failed to get starred notes: $e');
    }
  }

  /// Searches notes
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final allNotes = await getAllNotes();
      final lowerQuery = query.toLowerCase();
      return allNotes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(lowerQuery);
        final contentMatch = note.content.toLowerCase().contains(lowerQuery);
        final tagMatch = note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        return titleMatch || contentMatch || tagMatch;
      }).toList();
    } catch (e) {
      throw NoteStorageException('Failed to search notes: $e');
    }
  }

  /// Deletes a note
  Future<void> deleteNote(String id) async {
    try {
      final box = _hiveService.getBox(HiveService.notesBox);
      await box.delete(id);
    } catch (e) {
      throw NoteStorageException('Failed to delete note: $e');
    }
  }

  /// Saves a folder
  Future<void> saveFolder(NoteFolderModel folder) async {
    try {
      final box = _hiveService.getBox(HiveService.notesBox); // Using same box for now
      await box.put('folder_${folder.id}', folder);
    } catch (e) {
      throw NoteStorageException('Failed to save folder: $e');
    }
  }

  /// Gets all folders
  Future<List<NoteFolderModel>> getAllFolders() async {
    try {
      final box = _hiveService.getBox(HiveService.notesBox);
      return box.values
          .whereType<NoteFolderModel>()
          .toList();
    } catch (e) {
      throw NoteStorageException('Failed to get folders: $e');
    }
  }
}

class NoteStorageException implements Exception {
  final String message;
  NoteStorageException(this.message);
  
  @override
  String toString() => 'NoteStorageException: $message';
}
