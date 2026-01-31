import 'package:dartz/dartz.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for updating a document
class UpdateDocument {
  final DocumentRepository repository;

  UpdateDocument(this.repository);

  Future<Either<Failure, Document>> call(Document document) async {
    // Update the updatedAt timestamp
    final updatedDocument = document.copyWith(updatedAt: DateTime.now());
    return await repository.updateDocument(updatedDocument);
  }
}
