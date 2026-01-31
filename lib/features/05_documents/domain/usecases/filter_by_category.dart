import 'package:dartz/dartz.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for filtering documents by category
class FilterByCategory {
  final DocumentRepository repository;

  FilterByCategory(this.repository);

  Future<Either<Failure, List<Document>>> call(String categoryId) async {
    return await repository.getDocumentsByCategory(categoryId);
  }
}
