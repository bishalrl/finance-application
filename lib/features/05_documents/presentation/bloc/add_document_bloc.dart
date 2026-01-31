import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart';
import 'package:life_vault/features/05_documents/domain/usecases/add_document.dart';
import 'package:life_vault/features/05_documents/presentation/bloc/document_bloc.dart';
import 'package:life_vault/features/05_documents/presentation/bloc/document_event.dart' as doc_event;

part 'add_document_event.dart';
part 'add_document_state.dart';

class AddDocumentBloc extends Bloc<AddDocumentEvent, AddDocumentState> {
  final AddDocument _addDocument;
  final DocumentBloc _documentBloc;

  AddDocumentBloc({
    required AddDocument addDocument,
    required DocumentBloc documentBloc,
  })  : _addDocument = addDocument,
        _documentBloc = documentBloc,
        super(AddDocumentInitial()) {
    on<PickFile>(_onPickFile);
    on<TitleChanged>(_onTitleChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<TagsInputChanged>(_onTagsInputChanged);
    on<AddTag>(_onAddTag);
    on<RemoveTag>(_onRemoveTag);
    on<SaveDocument>(_onSaveDocument);
    on<ResetAddDocumentState>(_onResetAddDocumentState);
  }

  Future<void> _onPickFile(PickFile event, Emitter<AddDocumentState> emit) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    emit((state as AddDocumentInitial).copyWith(
      fileBytes: file.bytes,
      fileName: name,
      fileType: ext.isEmpty ? 'bin' : ext,
      title: name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name,
      errorMessage: null,
    ));
  }

  void _onTitleChanged(TitleChanged event, Emitter<AddDocumentState> emit) {
    emit((state as AddDocumentInitial).copyWith(title: event.title));
  }

  void _onDescriptionChanged(DescriptionChanged event, Emitter<AddDocumentState> emit) {
    emit((state as AddDocumentInitial).copyWith(description: event.description));
  }

  void _onTagsInputChanged(TagsInputChanged event, Emitter<AddDocumentState> emit) {
    emit((state as AddDocumentInitial).copyWith(tagsInput: event.tagsInput));
  }

  void _onAddTag(AddTag event, Emitter<AddDocumentState> emit) {
    final currentState = state as AddDocumentInitial;
    final newTags = event.tag.split(RegExp(r'[,\s]+')).map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty);
    final updatedTags = [...currentState.tags, ...newTags.where((t) => !currentState.tags.contains(t))];
    emit(currentState.copyWith(tags: updatedTags, tagsInput: ''));
  }

  void _onRemoveTag(RemoveTag event, Emitter<AddDocumentState> emit) {
    final currentState = state as AddDocumentInitial;
    final updatedTags = currentState.tags.where((tag) => tag != event.tag).toList();
    emit(currentState.copyWith(tags: updatedTags));
  }

  Future<void> _onSaveDocument(SaveDocument event, Emitter<AddDocumentState> emit) async {
    final currentState = state as AddDocumentInitial;

    if (currentState.fileBytes == null || currentState.fileName == null) {
      emit(currentState.copyWith(errorMessage: 'Pick a file first'));
      return;
    }
    if (currentState.title.trim().isEmpty) {
      emit(currentState.copyWith(errorMessage: 'Title is required'));
      return;
    }

    emit(currentState.copyWith(isSaving: true, errorMessage: null));

    final tagsToSave = [...currentState.tags];
    final extraTags = currentState.tagsInput.trim();
    if (extraTags.isNotEmpty) {
      final newTags = extraTags.split(RegExp(r'[,\s]+')).map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty);
      tagsToSave.addAll(newTags.where((t) => !tagsToSave.contains(t)));
    }

    final result = await _addDocument(
      title: currentState.title,
      fileBytes: currentState.fileBytes!,
      fileType: currentState.fileType!,
      description: currentState.description.trim().isEmpty ? null : currentState.description.trim(),
      tags: tagsToSave,
    );

    result.fold(
      (failure) => emit(AddDocumentFailure(failure.message)),
      (_) {
        _documentBloc.add(const doc_event.LoadDocuments());
        emit(AddDocumentSuccess());
      },
    );
  }

  void _onResetAddDocumentState(ResetAddDocumentState event, Emitter<AddDocumentState> emit) {
    emit(AddDocumentInitial());
  }
}
