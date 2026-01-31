import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';

enum NoteStatus { initial, loading, loaded, error }

class NoteState extends Equatable {
  final NoteStatus status;
  final List<Note> notes;
  final String? errorMessage;
  final bool isSearching;
  final String searchQuery;

  const NoteState({
    this.status = NoteStatus.initial,
    this.notes = const [],
    this.errorMessage,
    this.isSearching = false,
    this.searchQuery = '',
  });

  NoteState copyWith({
    NoteStatus? status,
    List<Note>? notes,
    String? errorMessage,
    bool? isSearching,
    String? searchQuery,
  }) {
    return NoteState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      errorMessage: errorMessage ?? this.errorMessage,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [status, notes, errorMessage, isSearching, searchQuery];
}
