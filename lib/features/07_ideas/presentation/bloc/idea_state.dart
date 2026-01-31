import 'package:equatable/equatable.dart';
import '../../domain/entities/idea.dart';

enum IdeasListStatus { initial, loading, loaded, error }

class IdeaState extends Equatable {
  final IdeasListStatus status;
  final List<Idea> ideas;
  final String? errorMessage;

  const IdeaState({
    this.status = IdeasListStatus.initial,
    this.ideas = const [],
    this.errorMessage,
  });

  IdeaState copyWith({
    IdeasListStatus? status,
    List<Idea>? ideas,
    String? errorMessage,
  }) {
    return IdeaState(
      status: status ?? this.status,
      ideas: ideas ?? this.ideas,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, ideas, errorMessage];
}
