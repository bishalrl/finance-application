import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_all_notes.dart';
import '../../domain/usecases/search_notes.dart';
import '../../domain/usecases/delete_note.dart';
import 'note_event.dart';
import 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final GetAllNotes getAllNotes;
  final SearchNotes searchNotes;
  final DeleteNote deleteNote;

  NoteBloc({
    required this.getAllNotes,
    required this.searchNotes,
    required this.deleteNote,
  }) : super(const NoteState()) {
    on<LoadNotes>(_onLoadNotes);
    on<SearchNotesEvent>(_onSearchNotes);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<ToggleSearch>(_onToggleSearch);
    on<SearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NoteState> emit) async {
    emit(state.copyWith(status: NoteStatus.loading, errorMessage: null));
    final result = await getAllNotes();
    result.fold(
      (failure) => emit(state.copyWith(
            status: NoteStatus.error,
            errorMessage: failure.toString(),
            notes: [],
          )),
      (List<Note> list) => emit(state.copyWith(
            status: NoteStatus.loaded,
            notes: list,
            errorMessage: null,
          )),
    );
  }

  Future<void> _onSearchNotes(SearchNotesEvent event, Emitter<NoteState> emit) async {
    if (event.query.trim().isEmpty) {
      add(const LoadNotes());
      return;
    }
    emit(state.copyWith(status: NoteStatus.loading, searchQuery: event.query));
    final result = await searchNotes(event.query);
    result.fold(
      (failure) => emit(state.copyWith(
            status: NoteStatus.error,
            errorMessage: failure.toString(),
            notes: [],
          )),
      (List<Note> list) => emit(state.copyWith(
            status: NoteStatus.loaded,
            notes: list,
            errorMessage: null,
          )),
    );
  }

  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NoteState> emit) async {
    final result = await deleteNote(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadNotes()),
    );
  }

  void _onToggleSearch(ToggleSearch event, Emitter<NoteState> emit) {
    emit(state.copyWith(isSearching: !state.isSearching, searchQuery: state.isSearching ? '' : state.searchQuery));
    if (!state.isSearching) {
      add(const LoadNotes());
    }
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<NoteState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    add(SearchNotesEvent(event.query));
  }
}
