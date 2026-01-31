part of 'add_document_bloc.dart';

@immutable
sealed class AddDocumentEvent {}

class PickFile extends AddDocumentEvent {}

class TitleChanged extends AddDocumentEvent {
  final String title;

  TitleChanged(this.title);
}

class DescriptionChanged extends AddDocumentEvent {
  final String description;

  DescriptionChanged(this.description);
}

class TagsInputChanged extends AddDocumentEvent {
  final String tagsInput;

  TagsInputChanged(this.tagsInput);
}

class AddTag extends AddDocumentEvent {
  final String tag;

  AddTag(this.tag);
}

class RemoveTag extends AddDocumentEvent {
  final String tag;

  RemoveTag(this.tag);
}

class SaveDocument extends AddDocumentEvent {}

class ResetAddDocumentState extends AddDocumentEvent {}
