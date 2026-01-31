import 'package:dartz/dartz.dart';
import '../entities/idea.dart';
import '../entities/project.dart';
import '../../../../core/errors/failures.dart';

abstract class IdeaRepository {
  Future<Either<Failure, Idea>> createIdea(Idea idea);
  Future<Either<Failure, List<Idea>>> getIdeasInbox();
  Future<Either<Failure, Idea>> likeIdea(String id);
  Future<Either<Failure, List<Idea>>> sortByLikes();
  Future<Either<Failure, Project>> createProject(Project project);
  Future<Either<Failure, List<Project>>> getAllProjects();
  Future<Either<Failure, Project?>> getProjectById(String id);
  Future<Either<Failure, Project>> updateProject(Project project);
  Future<Either<Failure, Project>> likeProject(String id);
  Future<Either<Failure, Project>> setProjectReview(String id, DateTime? nextReviewDate);
  Future<Either<Failure, Idea>> moveToProject(String ideaId, String projectId);
}
