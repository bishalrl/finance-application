import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/idea.dart';
import '../../domain/usecases/get_ideas_inbox.dart';
import '../../domain/usecases/create_idea.dart';
import '../../domain/usecases/like_idea.dart';
import 'idea_event.dart';
import 'idea_state.dart';

class IdeaBloc extends Bloc<IdeaEvent, IdeaState> {
  final GetIdeasInbox getIdeasInbox;
  final CreateIdea createIdea;
  final LikeIdea likeIdea;

  IdeaBloc({
    required this.getIdeasInbox,
    required this.createIdea,
    required this.likeIdea,
  }) : super(const IdeaState()) {
    on<LoadIdeas>(_onLoadIdeas);
    on<CreateIdeaEvent>(_onCreateIdea);
    on<LikeIdeaEvent>(_onLikeIdea);
  }

  Future<void> _onLoadIdeas(LoadIdeas event, Emitter<IdeaState> emit) async {
    emit(state.copyWith(status: IdeasListStatus.loading, errorMessage: null));
    final result = await getIdeasInbox();
    result.fold(
      (failure) => emit(state.copyWith(
            status: IdeasListStatus.error,
            errorMessage: failure.toString(),
            ideas: [],
          )),
      (List<Idea> list) => emit(state.copyWith(
            status: IdeasListStatus.loaded,
            ideas: list,
            errorMessage: null,
          )),
    );
  }

  Future<void> _onCreateIdea(CreateIdeaEvent event, Emitter<IdeaState> emit) async {
    final result = await createIdea(
      title: event.title,
      description: event.description,
      tags: event.tags,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadIdeas()),
    );
  }

  Future<void> _onLikeIdea(LikeIdeaEvent event, Emitter<IdeaState> emit) async {
    final result = await likeIdea(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.toString())),
      (_) => add(const LoadIdeas()),
    );
  }
}
