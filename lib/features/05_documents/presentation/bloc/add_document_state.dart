part of 'add_document_bloc.dart';

@immutable
sealed class AddDocumentState {}

class AddDocumentInitial extends AddDocumentState {
  final List<int>? fileBytes;
  final String? fileName;
  final String? fileType;
  final String title;
  final String description;
  final List<String> tags;
  final String tagsInput;
  final bool isSaving;
  final String? errorMessage;

  AddDocumentInitial({
    this.fileBytes,
    this.fileName,
    this.fileType,
    this.title = '',
    this.description = '',
    this.tags = const [],
    this.tagsInput = '',
    this.isSaving = false,
    this.errorMessage,
  });

  AddDocumentInitial copyWith({
    List<int>? fileBytes,
    String? fileName,
    String? fileType,
    String? title,
    String? description,
    List<String>? tags,
    String? tagsInput,
    bool? isSaving,
    String? errorMessage,
  }) {
    return AddDocumentInitial(
      fileBytes: fileBytes ?? this.fileBytes,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      tagsInput: tagsInput ?? this.tagsInput,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class AddDocumentSuccess extends AddDocumentState {}

class AddDocumentFailure extends AddDocumentState {
  final String message;

  AddDocumentFailure(this.message);
}
