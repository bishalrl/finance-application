import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:life_vault/features/06_notes/domain/entities/note.dart';
import 'package:life_vault/features/06_notes/domain/usecases/create_note.dart';
import 'package:life_vault/features/06_notes/domain/usecases/get_note_by_id.dart';
import 'package:life_vault/features/06_notes/domain/usecases/update_note.dart';
import 'package:life_vault/features/06_notes/presentation/bloc/note_bloc.dart';
import 'package:life_vault/features/06_notes/presentation/bloc/note_event.dart' as note_list_event;

part 'note_editor_event.dart';
part 'note_editor_state.dart';

const _autosaveDebounceMs = 1500;

class NoteEditorBloc extends Bloc<NoteEditorEvent, NoteEditorState> {
  final GetNoteById _getNoteById;
  final CreateNote _createNote;
  final UpdateNote _updateNote;
  final NoteBloc _noteBloc; // To trigger refresh in notes list

  Timer? _autosaveTimer;

  NoteEditorBloc({
    required GetNoteById getNoteById,
    required CreateNote createNote,
    required UpdateNote updateNote,
    required NoteBloc noteBloc,
  })  : _getNoteById = getNoteById,
        _createNote = createNote,
        _updateNote = updateNote,
        _noteBloc = noteBloc,
        super(NoteEditorInitial()) {
    on<LoadNote>(_onLoadNote);
    on<TitleChanged>(_onTitleChanged);
    on<ContentChanged>(_onContentChanged);
    on<TagInputChanged>(_onTagInputChanged);
    on<AddTag>(_onAddTag);
    on<RemoveTag>(_onRemoveTag);
    on<AutosaveNote>(_onAutosaveNote);
    on<SaveNote>(_onSaveNote);
  }

  Future<void> _onLoadNote(LoadNote event, Emitter<NoteEditorState> emit) async {
    emit((state as NoteEditorInitial).copyWith(isLoading: true, errorMessage: null));
    if (event.noteId == null || event.noteId!.isEmpty) {
      emit((state as NoteEditorInitial).copyWith(isLoading: false, title: '', content: '', tags: []));
      return;
    }

    final result = await _getNoteById(event.noteId!);
    result.fold(
      (failure) => emit((state as NoteEditorInitial).copyWith(isLoading: false, errorMessage: failure.message)),
      (note) => emit((state as NoteEditorInitial).copyWith(
            isLoading: false,
            note: note,
            title: note.title,
            content: note.content,
            tags: note.tags,
            errorMessage: null,
          )),
    );
  }

  void _onTitleChanged(TitleChanged event, Emitter<NoteEditorState> emit) {
    emit((state as NoteEditorInitial).copyWith(title: event.title));
    _triggerAutosave();
  }

  void _onContentChanged(ContentChanged event, Emitter<NoteEditorState> emit) {
    emit((state as NoteEditorInitial).copyWith(content: event.content));
    _triggerAutosave();
  }

  void _onTagInputChanged(TagInputChanged event, Emitter<NoteEditorState> emit) {
    emit((state as NoteEditorInitial).copyWith(tagInput: event.tagInput));
  }

  void _onAddTag(AddTag event, Emitter<NoteEditorState> emit) {
    final currentState = state as NoteEditorInitial;
    final t = currentState.tagInput.trim().toLowerCase();
    if (t.isEmpty || currentState.tags.contains(t)) return;

    final updatedTags = [...currentState.tags, t];
    emit(currentState.copyWith(tags: updatedTags, tagInput: ''));
    _triggerAutosave();
  }

  void _onRemoveTag(RemoveTag event, Emitter<NoteEditorState> emit) {
    final currentState = state as NoteEditorInitial;
    final updatedTags = currentState.tags.where((x) => x != event.tag).toList();
    emit(currentState.copyWith(tags: updatedTags));
    _triggerAutosave();
  }

  void _triggerAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: _autosaveDebounceMs), () {
      add(AutosaveNote());
    });
  }

  Future<void> _onAutosaveNote(AutosaveNote event, Emitter<NoteEditorState> emit) async {
    final currentState = state as NoteEditorInitial;
    if (currentState.isSaving) return;

    final title = currentState.title.trim();
    final content = currentState.content;

    if (title.isEmpty && currentState.note == null) return;

    emit(currentState.copyWith(isSaving: true, errorMessage: null));

    if (currentState.note != null) {
      final updatedNote = currentState.note!.copyWith(
        title: title.isEmpty ? currentState.note!.title : title,
        content: content,
        tags: currentState.tags,
        updatedAt: DateTime.now(),
      );
      final result = await _updateNote(updatedNote);
      result.fold(
        (failure) => emit(currentState.copyWith(isSaving: false, errorMessage: failure.message)),
        (_) => emit(currentState.copyWith(isSaving: false, note: updatedNote)),
      );
    } else {
      final result = await _createNote(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        tags: currentState.tags,
      );
      result.fold(
        (failure) => emit(currentState.copyWith(isSaving: false, errorMessage: failure.message)),
        (note) => emit(currentState.copyWith(isSaving: false, note: note, errorMessage: null)),
      );
    }
    _noteBloc.add(const note_list_event.LoadNotes()); // Refresh notes list
  }

  Future<void> _onSaveNote(SaveNote event, Emitter<NoteEditorState> emit) async {
    final currentState = state as NoteEditorInitial;

    final title = currentState.title.trim();
    if (title.isEmpty) {
      emit(currentState.copyWith(errorMessage: 'Title is required'));
      return;
    }

    emit(currentState.copyWith(isSaving: true, errorMessage: null));

    if (currentState.note != null) {
      final updatedNote = currentState.note!.copyWith(
        title: title,
        content: currentState.content,
        tags: currentState.tags,
        updatedAt: DateTime.now(),
      );
      final result = await _updateNote(updatedNote);
      result.fold(
        (failure) => emit(NoteEditorFailure(failure.message)),
        (_) {
          _noteBloc.add(const note_list_event.LoadNotes()); // Refresh notes list
          emit(NoteEditorSuccess());
        },
      );
    } else {
      final result = await _createNote(
        title: title,
        content: currentState.content,
        tags: currentState.tags,
      );
      result.fold(
        (failure) => emit(NoteEditorFailure(failure.message)),
        (_) {
          _noteBloc.add(const note_list_event.LoadNotes()); // Refresh notes list
          emit(NoteEditorSuccess());
        },
      );
    }
  }

  @override
  Future<void> close() {
    _autosaveTimer?.cancel();
    return super.close();
  }
}
