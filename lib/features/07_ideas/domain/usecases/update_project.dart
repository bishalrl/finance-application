import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class UpdateProject {
  final IdeaRepository repository;

  UpdateProject(this.repository);

  Future<Either<Failure, Project>> call(Project project) =>
      repository.updateProject(project);
}
