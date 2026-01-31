import 'package:dartz/dartz.dart';
import '../entities/idea.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class MoveToProject {
  final IdeaRepository repository;
  MoveToProject(this.repository);

  Future<Either<Failure, Idea>> call(String ideaId, String projectId) async {
    return await repository.moveToProject(ideaId, projectId);
  }
}
