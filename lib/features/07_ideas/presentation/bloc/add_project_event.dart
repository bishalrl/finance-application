part of 'add_project_bloc.dart';

@immutable
sealed class AddProjectEvent {}

class TitleChanged extends AddProjectEvent {
  final String title;

  TitleChanged(this.title);
}

class VisionChanged extends AddProjectEvent {
  final String vision;

  VisionChanged(this.vision);
}

class SubmitProject extends AddProjectEvent {}

class ResetAddProjectState extends AddProjectEvent {}
