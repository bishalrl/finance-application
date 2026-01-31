part of 'note_editor_bloc.dart';

@immutable
sealed class NoteEditorState {}

class NoteEditorInitial extends NoteEditorState {
  final Note? note;
  final String title;
  final String content;
  final List<String> tags;
  final String tagInput;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  NoteEditorInitial({
    this.note,
    this.title = '',
    this.content = '',
    this.tags = const [],
    this.tagInput = '',
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  NoteEditorInitial copyWith({
    Note? note,
    String? title,
    String? content,
    List<String>? tags,
    String? tagInput,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return NoteEditorInitial(
      note: note ?? this.note,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      tagInput: tagInput ?? this.tagInput,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class NoteEditorSuccess extends NoteEditorState {}

class NoteEditorFailure extends NoteEditorState {
  final String message;

  NoteEditorFailure(this.message);
}
