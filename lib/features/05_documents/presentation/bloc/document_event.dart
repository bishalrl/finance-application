import 'package:equatable/equatable.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  const LoadDocuments();
}

class SearchDocumentsEvent extends DocumentEvent {
  final String query;

  const SearchDocumentsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class DeleteDocumentEvent extends DocumentEvent {
  final String id;

  const DeleteDocumentEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearSearch extends DocumentEvent {
  const ClearSearch();
}

class ToggleSearch extends DocumentEvent {
  const ToggleSearch();
}

class SearchQueryChanged extends DocumentEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
