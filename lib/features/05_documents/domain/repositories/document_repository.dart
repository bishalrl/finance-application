import '../entities/document.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';

/// Repository interface for document operations
abstract class DocumentRepository {
  /// Adds a new document
  Future<Either<Failure, Document>> addDocument(Document document, List<int> fileBytes);

  /// Gets all documents
  Future<Either<Failure, List<Document>>> getAllDocuments();

  /// Gets a document by ID
  Future<Either<Failure, Document>> getDocumentById(String id);

  /// Updates a document
  Future<Either<Failure, Document>> updateDocument(Document document);

  /// Deletes a document
  Future<Either<Failure, void>> deleteDocument(String id);

  /// Searches documents
  Future<Either<Failure, List<Document>>> searchDocuments(String query);

  /// Gets documents by category
  Future<Either<Failure, List<Document>>> getDocumentsByCategory(String categoryId);

  /// Gets expired documents
  Future<Either<Failure, List<Document>>> getExpiredDocuments();

  /// Gets documents expiring soon
  Future<Either<Failure, List<Document>>> getDocumentsExpiringSoon();

  /// Gets vault documents
  Future<Either<Failure, List<Document>>> getVaultDocuments();

  /// Gets decrypted file bytes for a document
  Future<Either<Failure, List<int>>> getDecryptedFileBytes(String documentId);
}
