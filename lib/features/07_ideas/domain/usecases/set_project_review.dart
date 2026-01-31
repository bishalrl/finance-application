import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class SetProjectReview {
  final IdeaRepository repository;

  SetProjectReview(this.repository);

  Future<Either<Failure, Project>> call(String id, DateTime? nextReviewDate) =>
      repository.setProjectReview(id, nextReviewDate);
}
