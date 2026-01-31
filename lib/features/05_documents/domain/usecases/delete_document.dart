import 'package:dartz/dartz.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for deleting a document
class DeleteDocument {
  final DocumentRepository repository;

  DeleteDocument(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteDocument(id);
  }
}
