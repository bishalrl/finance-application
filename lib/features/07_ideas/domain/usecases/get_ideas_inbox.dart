import 'package:dartz/dartz.dart';
import '../entities/idea.dart';
import '../repositories/idea_repository.dart';
import '../../../../core/errors/failures.dart';

class GetIdeasInbox {
  final IdeaRepository repository;

  GetIdeasInbox(this.repository);

  Future<Either<Failure, List<Idea>>> call() async {
    return await repository.getIdeasInbox();
  }
}
