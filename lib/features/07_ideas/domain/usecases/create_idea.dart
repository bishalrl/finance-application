import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/idea.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class CreateIdea {
  final IdeaRepository repository;
  CreateIdea(this.repository);

  Future<Either<Failure, Idea>> call({
    required String title,
    String? description,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final idea = Idea(
      id: const Uuid().v4(),
      title: title,
      description: description,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    return await repository.createIdea(idea);
  }
}
