part of 'project_detail_bloc.dart';

@immutable
sealed class ProjectDetailState {}

class ProjectDetailInitial extends ProjectDetailState {
  final Project? project;
  final String visionInput;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  ProjectDetailInitial({
    this.project,
    this.visionInput = '',
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  ProjectDetailInitial copyWith({
    Project? project,
    String? visionInput,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ProjectDetailInitial(
      project: project ?? this.project,
      visionInput: visionInput ?? this.visionInput,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class ProjectDetailSuccess extends ProjectDetailState {}

class ProjectDetailFailure extends ProjectDetailState {
  final String message;

  ProjectDetailFailure(this.message);
}
