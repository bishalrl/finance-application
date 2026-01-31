import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectEvent {
  const LoadProjects();
}

enum ProjectSortOption { importance, recent, needsReview, alphabetical }

class SortProjects extends ProjectEvent {
  final ProjectSortOption sortOption;

  const SortProjects(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

class CreateProjectEvent extends ProjectEvent {
  final String title;
  final String vision;

  const CreateProjectEvent({required this.title, this.vision = ''});

  @override
  List<Object?> get props => [title, vision];
}

class UpdateProjectEvent extends ProjectEvent {
  final Project project;

  const UpdateProjectEvent(this.project);

  @override
  List<Object?> get props => [project];
}

class LikeProjectEvent extends ProjectEvent {
  final String id;

  const LikeProjectEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SetProjectReviewEvent extends ProjectEvent {
  final String id;
  final DateTime? nextReviewDate;

  const SetProjectReviewEvent(this.id, this.nextReviewDate);

  @override
  List<Object?> get props => [id, nextReviewDate];
}

class DeleteProjectEvent extends ProjectEvent {
  final String id;

  const DeleteProjectEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleViewMode extends ProjectEvent {
  const ToggleViewMode();
}
