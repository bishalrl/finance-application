import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class CreateProject {
  final IdeaRepository repository;

  CreateProject(this.repository);

  Future<Either<Failure, Project>> call(Project project) =>
      repository.createProject(project);
}
