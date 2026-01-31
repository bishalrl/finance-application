part of 'add_project_bloc.dart';

@immutable
sealed class AddProjectState {}

class AddProjectInitial extends AddProjectState {
  final String title;
  final String vision;
  final bool isSubmitting;
  final String? errorMessage;

  AddProjectInitial({
    this.title = '',
    this.vision = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  AddProjectInitial copyWith({
    String? title,
    String? vision,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AddProjectInitial(
      title: title ?? this.title,
      vision: vision ?? this.vision,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class AddProjectSuccess extends AddProjectState {}

class AddProjectFailure extends AddProjectState {
  final String message;

  AddProjectFailure(this.message);
}
