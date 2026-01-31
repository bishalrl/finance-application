import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/get_all_projects.dart';
import '../../domain/usecases/get_project_by_id.dart';
import '../../domain/usecases/create_project.dart';
import '../../domain/usecases/update_project.dart';
import '../../domain/usecases/like_project.dart';
import '../../domain/usecases/set_project_review.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetAllProjects getAllProjects;
  final GetProjectById getProjectById;
  final CreateProject createProject;
  final UpdateProject updateProject;
  final LikeProject likeProject;
  final SetProjectReview setProjectReview;

  ProjectBloc({
    required this.getAllProjects,
    required this.getProjectById,
    required this.createProject,
    required this.updateProject,
    required this.likeProject,
    required this.setProjectReview,
  }) : super(const ProjectState()) {
    on<LoadProjects>(_onLoadProjects);
    on<SortProjects>(_onSortProjects);
    on<CreateProjectEvent>(_onCreateProject);
    on<UpdateProjectEvent>(_onUpdateProject);
    on<LikeProjectEvent>(_onLikeProject);
    on<SetProjectReviewEvent>(_onSetProjectReview);
    on<DeleteProjectEvent>(_onDeleteProject);
    on<ToggleViewMode>(_onToggleViewMode);
  }

  Future<void> _onLoadProjects(LoadProjects event, Emitter<ProjectState> emit) async {
    emit(state.copyWith(status: ProjectListStatus.loading, errorMessage: null));
    final result = await getAllProjects();
    result.fold(
      (failure) => emit(state.copyWith(
            status: ProjectListStatus.error,
            errorMessage: failure.toString(),
            projects: [],
          )),
      (list) => emit(state.copyWith(
            status: ProjectListStatus.loaded,
            projects: list,
            errorMessage: null,
          )),
    );
  }

  void _onSortProjects(SortProjects event, Emitter<ProjectState> emit) {
    emit(state.copyWith(sortOption: event.sortOption));
  }

  Future<void> _onCreateProject(CreateProjectEvent event, Emitter<ProjectState> emit) async {
    final now = DateTime.now();
    final project = Project(
      id: const Uuid().v4(),
      title: event.title,
      vision: event.vision,
      createdAt: now,
      updatedAt: now,
    );
    final result = await createProject(project);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadProjects()),
    );
  }

  Future<void> _onUpdateProject(UpdateProjectEvent event, Emitter<ProjectState> emit) async {
    final result = await updateProject(event.project);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadProjects()),
    );
  }

  Future<void> _onLikeProject(LikeProjectEvent event, Emitter<ProjectState> emit) async {
    final result = await likeProject(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadProjects()),
    );
  }

  Future<void> _onSetProjectReview(SetProjectReviewEvent event, Emitter<ProjectState> emit) async {
    final result = await setProjectReview(event.id, event.nextReviewDate);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadProjects()),
    );
  }

  Future<void> _onDeleteProject(DeleteProjectEvent event, Emitter<ProjectState> emit) async {
    // Delete not in repository yet - add if needed
    add(const LoadProjects());
  }

  void _onToggleViewMode(ToggleViewMode event, Emitter<ProjectState> emit) {
    emit(state.copyWith(isGridView: !state.isGridView));
  }
}
