import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import '../../domain/entities/idea.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/idea_repository.dart';
import '../datasources/idea_local_datasource.dart';
import '../models/idea_model.dart';

class IdeaRepositoryImpl implements IdeaRepository {
  final IdeaLocalDataSource _localDataSource;

  IdeaRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Idea>> createIdea(Idea idea) async {
    try {
      final model = IdeaModel.fromEntity(idea);
      await _localDataSource.saveIdea(model);
      return Right(idea);
    } catch (e) {
      return Left(CacheFailure('Failed to create idea: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Idea>>> getIdeasInbox() async {
    try {
      final ideas = await _localDataSource.getIdeasInbox();
      return Right(ideas.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get ideas: $e'));
    }
  }

  @override
  Future<Either<Failure, Idea>> likeIdea(String id) async {
    try {
      final idea = await _localDataSource.getIdeaById(id);
      if (idea == null) return Left(CacheFailure('Idea not found'));
      final updated = IdeaModel(
        id: idea.id,
        title: idea.title,
        description: idea.description,
        tags: idea.tags,
        likes: idea.likes + 1,
        status: idea.status,
        projectId: idea.projectId,
        createdAt: idea.createdAt,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveIdea(updated);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to like idea: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Idea>>> sortByLikes() async {
    try {
      final ideas = await _localDataSource.getIdeasByLikes();
      return Right(ideas.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to sort ideas: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> createProject(Project project) async {
    try {
      await _localDataSource.saveProject(project);
      return Right(project);
    } catch (e) {
      return Left(CacheFailure('Failed to create project: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Project>>> getAllProjects() async {
    try {
      final projects = await _localDataSource.getAllProjects();
      return Right(projects);
    } catch (e) {
      return Left(CacheFailure('Failed to get projects: $e'));
    }
  }

  @override
  Future<Either<Failure, Project?>> getProjectById(String id) async {
    try {
      final project = await _localDataSource.getProjectById(id);
      return Right(project);
    } catch (e) {
      return Left(CacheFailure('Failed to get project: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject(Project project) async {
    try {
      final updated = project.copyWith(updatedAt: DateTime.now());
      await _localDataSource.updateProject(updated);
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure('Failed to update project: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> likeProject(String id) async {
    try {
      final project = await _localDataSource.getProjectById(id);
      if (project == null) return Left(CacheFailure('Project not found'));
      final updated = project.copyWith(likes: project.likes + 1, updatedAt: DateTime.now());
      await _localDataSource.updateProject(updated);
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure('Failed to like project: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> setProjectReview(String id, DateTime? nextReviewDate) async {
    try {
      final project = await _localDataSource.getProjectById(id);
      if (project == null) return Left(CacheFailure('Project not found'));
      final updated = project.copyWith(
        lastReviewedAt: DateTime.now(),
        nextReviewDate: nextReviewDate,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.updateProject(updated);
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure('Failed to set review: $e'));
    }
  }

  @override
  Future<Either<Failure, Idea>> moveToProject(String ideaId, String projectId) async {
    try {
      final idea = await _localDataSource.getIdeaById(ideaId);
      if (idea == null) return Left(CacheFailure('Idea not found'));
      final updated = IdeaModel(
        id: idea.id,
        title: idea.title,
        description: idea.description,
        tags: idea.tags,
        likes: idea.likes,
        status: IdeaStatus.inProgress,
        projectId: projectId,
        createdAt: idea.createdAt,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveIdea(updated);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to move idea: $e'));
    }
  }
}
