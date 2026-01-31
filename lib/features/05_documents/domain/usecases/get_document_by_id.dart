import 'package:dartz/dartz.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for getting a document by ID
class GetDocumentById {
  final DocumentRepository repository;

  GetDocumentById(this.repository);

  Future<Either<Failure, Document>> call(String id) async {
    return await repository.getDocumentById(id);
  }
}
