import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/document.dart';
import '../../domain/usecases/get_all_documents.dart';
import '../../domain/usecases/search_documents.dart';
import '../../domain/usecases/delete_document.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final GetAllDocuments getAllDocuments;
  final SearchDocuments searchDocuments;
  final DeleteDocument deleteDocument;

  DocumentBloc({
    required this.getAllDocuments,
    required this.searchDocuments,
    required this.deleteDocument,
  }) : super(const DocumentState()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<SearchDocumentsEvent>(_onSearchDocuments);
    on<DeleteDocumentEvent>(_onDeleteDocument);
    on<ClearSearch>(_onClearSearch);
    on<ToggleSearch>(_onToggleSearch);
    on<SearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onLoadDocuments(LoadDocuments event, Emitter<DocumentState> emit) async {
    emit(state.copyWith(status: DocumentStatus.loading, errorMessage: null));
    final result = await getAllDocuments();
    result.fold(
      (failure) => emit(state.copyWith(
            status: DocumentStatus.error,
            errorMessage: failure.toString(),
            documents: [],
          )),
      (List<Document> list) => emit(state.copyWith(
            status: DocumentStatus.loaded,
            documents: list,
            errorMessage: null,
          )),
    );
  }

  Future<void> _onSearchDocuments(SearchDocumentsEvent event, Emitter<DocumentState> emit) async {
    if (event.query.trim().isEmpty) {
      add(const LoadDocuments());
      return;
    }
    emit(state.copyWith(status: DocumentStatus.loading, searchQuery: event.query));
    final result = await searchDocuments(event.query);
    result.fold(
      (failure) => emit(state.copyWith(
            status: DocumentStatus.error,
            errorMessage: failure.toString(),
            documents: [],
          )),
      (List<Document> list) => emit(state.copyWith(
            status: DocumentStatus.loaded,
            documents: list,
            errorMessage: null,
          )),
    );
  }

  Future<void> _onDeleteDocument(DeleteDocumentEvent event, Emitter<DocumentState> emit) async {
    final result = await deleteDocument(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadDocuments()),
    );
  }

  void _onClearSearch(ClearSearch event, Emitter<DocumentState> emit) {
    emit(state.copyWith(searchQuery: null, isSearching: false));
    add(const LoadDocuments());
  }

  void _onToggleSearch(ToggleSearch event, Emitter<DocumentState> emit) {
    emit(state.copyWith(isSearching: !state.isSearching, searchQuery: state.isSearching ? null : state.searchQuery));
    if (!state.isSearching) {
      add(const LoadDocuments());
    }
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<DocumentState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    add(SearchDocumentsEvent(event.query));
  }
}
