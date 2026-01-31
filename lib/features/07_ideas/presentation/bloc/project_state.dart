import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';
import 'project_event.dart';

enum ProjectListStatus { initial, loading, loaded, error }

class ProjectState extends Equatable {
  final ProjectListStatus status;
  final List<Project> projects;
  final ProjectSortOption sortOption;
  final String? errorMessage;
  final bool isGridView;

  const ProjectState({
    this.status = ProjectListStatus.initial,
    this.projects = const [],
    this.sortOption = ProjectSortOption.importance,
    this.errorMessage,
    this.isGridView = true, // Default to grid view
  });

  List<Project> get sortedProjects {
    final list = List<Project>.from(projects);
    switch (sortOption) {
      case ProjectSortOption.importance:
        list.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case ProjectSortOption.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case ProjectSortOption.needsReview:
        list.sort((a, b) {
          final aReview = a.needsReview ? 1 : 0;
          final bReview = b.needsReview ? 1 : 0;
          if (aReview != bReview) return bReview.compareTo(aReview);
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
      case ProjectSortOption.alphabetical:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  ProjectState copyWith({
    ProjectListStatus? status,
    List<Project>? projects,
    ProjectSortOption? sortOption,
    String? errorMessage,
    bool? isGridView,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      sortOption: sortOption ?? this.sortOption,
      errorMessage: errorMessage,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  @override
  List<Object?> get props => [status, projects, sortOption, errorMessage, isGridView];
}
