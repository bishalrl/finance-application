import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:life_vault/features/07_ideas/domain/entities/project.dart';
import 'package:life_vault/features/07_ideas/domain/usecases/get_project_by_id.dart';
import 'package:life_vault/features/07_ideas/domain/usecases/update_project.dart';
import 'package:life_vault/features/07_ideas/domain/usecases/set_project_review.dart';
import 'package:life_vault/features/07_ideas/domain/usecases/like_project.dart';
import 'package:life_vault/features/07_ideas/presentation/bloc/project_bloc.dart';
import 'package:life_vault/features/07_ideas/presentation/bloc/project_event.dart' as project_list_event;

part 'project_detail_event.dart';
part 'project_detail_state.dart';

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState> {
  final GetProjectById _getProjectById;
  final UpdateProject _updateProject;
  final SetProjectReview _setProjectReview;
  final LikeProject _likeProject;
  final ProjectBloc _projectBloc; // To trigger refresh in projects list

  ProjectDetailBloc({
    required GetProjectById getProjectById,
    required UpdateProject updateProject,
    required SetProjectReview setProjectReview,
    required LikeProject likeProject,
    required ProjectBloc projectBloc,
  })  : _getProjectById = getProjectById,
        _updateProject = updateProject,
        _setProjectReview = setProjectReview,
        _likeProject = likeProject,
        _projectBloc = projectBloc,
        super(ProjectDetailInitial()) {
    on<LoadProjectDetail>(_onLoadProjectDetail);
    on<VisionChanged>(_onVisionChanged);
    on<SaveVision>(_onSaveVision);
    on<SetReviewReminder>(_onSetReviewReminder);
    on<LikeProjectFromDetail>(_onLikeProjectFromDetail);
  }

  Future<void> _onLoadProjectDetail(LoadProjectDetail event, Emitter<ProjectDetailState> emit) async {
    emit((state as ProjectDetailInitial).copyWith(isLoading: true, errorMessage: null));
    final result = await _getProjectById(event.projectId);
    result.fold(
      (failure) => emit((state as ProjectDetailInitial).copyWith(isLoading: false, errorMessage: failure.message)),
      (project) => emit((state as ProjectDetailInitial).copyWith(
            isLoading: false,
            project: project,
            visionInput: project!.vision,
            errorMessage: null,
          )),
    );
  }

  void _onVisionChanged(VisionChanged event, Emitter<ProjectDetailState> emit) {
    emit((state as ProjectDetailInitial).copyWith(visionInput: event.vision));
  }

  Future<void> _onSaveVision(SaveVision event, Emitter<ProjectDetailState> emit) async {
    final currentState = state as ProjectDetailInitial;
    if (currentState.project == null || currentState.visionInput == currentState.project!.vision) return;

    emit(currentState.copyWith(isSaving: true, errorMessage: null));

    final updatedProject = currentState.project!.copyWith(
      vision: currentState.visionInput,
      updatedAt: DateTime.now(),
    );
    final result = await _updateProject(updatedProject);
    result.fold(
      (failure) => emit(ProjectDetailFailure(failure.message)),
      (_) {
        _projectBloc.add(const project_list_event.LoadProjects()); // Refresh projects list
        emit(currentState.copyWith(isSaving: false, project: updatedProject));
      },
    );
  }

  Future<void> _onSetReviewReminder(SetReviewReminder event, Emitter<ProjectDetailState> emit) async {
    final currentState = state as ProjectDetailInitial;
    if (currentState.project == null) return;

    emit(currentState.copyWith(isSaving: true, errorMessage: null));

    final result = await _setProjectReview(currentState.project!.id, event.nextReviewDate);
    result.fold(
      (failure) => emit(ProjectDetailFailure(failure.message)),
      (_) {
        _projectBloc.add(const project_list_event.LoadProjects()); // Refresh projects list
        // Reload project detail to reflect new review date
        add(LoadProjectDetail(currentState.project!.id));
      },
    );
  }

  Future<void> _onLikeProjectFromDetail(LikeProjectFromDetail event, Emitter<ProjectDetailState> emit) async {
    final currentState = state as ProjectDetailInitial;
    if (currentState.project == null) return;

    final result = await _likeProject(currentState.project!.id);
    result.fold(
      (failure) => emit(ProjectDetailFailure(failure.message)),
      (_) {
        _projectBloc.add(const project_list_event.LoadProjects()); // Refresh projects list
        // Reload project detail to reflect new like count
        add(LoadProjectDetail(currentState.project!.id));
      },
    );
  }
}
