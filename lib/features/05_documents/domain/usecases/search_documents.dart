import 'package:dartz/dartz.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// Use case for searching documents
/// 
/// Business Logic:
/// - Searches in titles (weight: 10)
/// - Searches in tags (weight: 8)
/// - Searches in descriptions (weight: 5)
/// - Searches in categories (weight: 3)
/// - Results sorted by relevance
class SearchDocuments {
  final DocumentRepository repository;

  SearchDocuments(this.repository);

  Future<Either<Failure, List<Document>>> call(String query) async {
    if (query.trim().isEmpty) {
      // Return all documents if query is empty
      return await repository.getAllDocuments();
    }
    return await repository.searchDocuments(query);
  }
}
