import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:life_vault/features/07_ideas/presentation/bloc/project_bloc.dart';
import 'package:life_vault/features/07_ideas/presentation/bloc/project_event.dart' as project_list_event;
import 'package:life_vault/features/07_ideas/presentation/bloc/project_state.dart';

part 'add_project_event.dart';
part 'add_project_state.dart';

class AddProjectBloc extends Bloc<AddProjectEvent, AddProjectState> {
  final ProjectBloc _projectBloc;

  AddProjectBloc({required ProjectBloc projectBloc})
      : _projectBloc = projectBloc,
        super(AddProjectInitial()) {
    on<TitleChanged>(_onTitleChanged);
    on<VisionChanged>(_onVisionChanged);
    on<SubmitProject>(_onSubmitProject);
    on<ResetAddProjectState>(_onResetAddProjectState);
  }

  void _onTitleChanged(TitleChanged event, Emitter<AddProjectState> emit) {
    emit((state as AddProjectInitial).copyWith(title: event.title, errorMessage: null));
  }

  void _onVisionChanged(VisionChanged event, Emitter<AddProjectState> emit) {
    emit((state as AddProjectInitial).copyWith(vision: event.vision, errorMessage: null));
  }

  Future<void> _onSubmitProject(SubmitProject event, Emitter<AddProjectState> emit) async {
    final currentState = state as AddProjectInitial;

    if (currentState.title.trim().isEmpty) {
      emit(currentState.copyWith(errorMessage: 'Title is required'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, errorMessage: null));

    _projectBloc.add(project_list_event.CreateProjectEvent(
      title: currentState.title,
      vision: currentState.vision,
    ));

    // Listen for the ProjectBloc to confirm creation or error
    await for (var projectState in _projectBloc.stream) {
      if (projectState.status == ProjectListStatus.loaded) {
        emit(AddProjectSuccess());
        return;
      } else if (projectState.status == ProjectListStatus.error) {
        emit(AddProjectFailure(projectState.errorMessage ?? 'Failed to add project'));
        return;
      }
    }
  }

  void _onResetAddProjectState(ResetAddProjectState event, Emitter<AddProjectState> emit) {
    emit(AddProjectInitial());
  }
}
