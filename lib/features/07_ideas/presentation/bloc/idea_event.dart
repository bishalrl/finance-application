import 'package:equatable/equatable.dart';

abstract class IdeaEvent extends Equatable {
  const IdeaEvent();

  @override
  List<Object?> get props => [];
}

class LoadIdeas extends IdeaEvent {
  const LoadIdeas();
}

class CreateIdeaEvent extends IdeaEvent {
  final String title;
  final String? description;
  final List<String> tags;

  const CreateIdeaEvent({
    required this.title,
    this.description,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [title, description, tags];
}

class LikeIdeaEvent extends IdeaEvent {
  final String id;

  const LikeIdeaEvent(this.id);

  @override
  List<Object?> get props => [id];
}
