import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class GetProjectById {
  final IdeaRepository repository;

  GetProjectById(this.repository);

  Future<Either<Failure, Project?>> call(String id) =>
      repository.getProjectById(id);
}
