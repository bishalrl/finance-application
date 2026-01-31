import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class GetAllProjects {
  final IdeaRepository repository;

  GetAllProjects(this.repository);

  Future<Either<Failure, List<Project>>> call() =>
      repository.getAllProjects();
}
