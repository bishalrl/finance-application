import 'package:equatable/equatable.dart';
import '../../domain/entities/document.dart';

enum DocumentStatus { initial, loading, loaded, error }

class DocumentState extends Equatable {
  final DocumentStatus status;
  final List<Document> documents;
  final String? searchQuery;
  final String? errorMessage;
  final bool isSearching;

  const DocumentState({
    this.status = DocumentStatus.initial,
    this.documents = const [],
    this.searchQuery,
    this.errorMessage,
    this.isSearching = false,
  });

  DocumentState copyWith({
    DocumentStatus? status,
    List<Document>? documents,
    String? searchQuery,
    String? errorMessage,
    bool? isSearching,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [status, documents, searchQuery, errorMessage, isSearching];
}
