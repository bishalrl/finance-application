import 'package:dartz/dartz.dart';
import '../entities/idea.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class LikeIdea {
  final IdeaRepository repository;
  LikeIdea(this.repository);

  Future<Either<Failure, Idea>> call(String id) async {
    return await repository.likeIdea(id);
  }
}
