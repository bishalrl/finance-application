part of 'note_editor_bloc.dart';

@immutable
sealed class NoteEditorEvent {}

class LoadNote extends NoteEditorEvent {
  final String? noteId;

  LoadNote(this.noteId);
}

class TitleChanged extends NoteEditorEvent {
  final String title;

  TitleChanged(this.title);
}

class ContentChanged extends NoteEditorEvent {
  final String content;

  ContentChanged(this.content);
}

class TagInputChanged extends NoteEditorEvent {
  final String tagInput;

  TagInputChanged(this.tagInput);
}

class AddTag extends NoteEditorEvent {}

class RemoveTag extends NoteEditorEvent {
  final String tag;

  RemoveTag(this.tag);
}

class AutosaveNote extends NoteEditorEvent {}

class SaveNote extends NoteEditorEvent {}
