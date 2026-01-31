import 'package:dartz/dartz.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for getting all documents
class GetAllDocuments {
  final DocumentRepository repository;

  GetAllDocuments(this.repository);

  Future<Either<Failure, List<Document>>> call() async {
    return await repository.getAllDocuments();
  }
}
