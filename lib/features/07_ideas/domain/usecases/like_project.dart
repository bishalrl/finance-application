import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class LikeProject {
  final IdeaRepository repository;

  LikeProject(this.repository);

  Future<Either<Failure, Project>> call(String id) =>
      repository.likeProject(id);
}
