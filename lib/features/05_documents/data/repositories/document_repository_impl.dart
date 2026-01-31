import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/exceptions.dart';
import 'package:life_vault/core/errors/failures.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../datasources/file_storage_datasource.dart';
import '../models/document_model.dart';


/// Implementation of DocumentRepository
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;
  final FileStorageDataSource _fileStorageDataSource;

  DocumentRepositoryImpl({
    required DocumentLocalDataSource localDataSource,
    required FileStorageDataSource fileStorageDataSource,
  })  : _localDataSource = localDataSource,
        _fileStorageDataSource = fileStorageDataSource;

  @override
  Future<Either<Failure, Document>> addDocument(
    Document document,
    List<int> fileBytes,
  ) async {
    try {
      // Validate file size (business rule: 50MB free, 200MB pro)
      // This will be checked in use case based on subscription
      
      // Encrypt and save file
      final encryptedFilePath = await _fileStorageDataSource.saveEncryptedFile(
        Uint8List.fromList(fileBytes),
        document.filePath,
        document.id,
      );

      // Create document model with encrypted file path
      final documentModel = DocumentModel.fromEntity(
        document.copyWith(encryptedFilePath: encryptedFilePath),
      );

      // Save document metadata
      await _localDataSource.saveDocument(documentModel);

      // Return entity
      return Right(documentModel.toEntity());
    } on FileOperationException catch (e) {
      return Left(FileOperationFailure(e.message));
    } on EncryptionException catch (e) {
      return Left(EncryptionFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure('Failed to add document: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> getAllDocuments() async {
    try {
      final documents = await _localDataSource.getAllDocuments();
      return Right(documents.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get documents: $e'));
    }
  }

  @override
  Future<Either<Failure, Document>> getDocumentById(String id) async {
    try {
      final document = await _localDataSource.getDocumentById(id);
      if (document == null) {
        return Left(CacheFailure('Document not found'));
      }
      return Right(document.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get document: $e'));
    }
  }

  @override
  Future<Either<Failure, Document>> updateDocument(Document document) async {
    try {
      final documentModel = DocumentModel.fromEntity(document);
      await _localDataSource.updateDocument(documentModel);
      return Right(document);
    } catch (e) {
      return Left(CacheFailure('Failed to update document: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String id) async {
    try {
      // Get document to delete file
      final document = await _localDataSource.getDocumentById(id);
      if (document != null && document.encryptedFilePath != null) {
        await _fileStorageDataSource.deleteFile(document.encryptedFilePath!);
      }

      // Delete document metadata
      await _localDataSource.deleteDocument(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete document: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> searchDocuments(String query) async {
    try {
      final documents = await _localDataSource.searchDocuments(query);
      return Right(documents.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to search documents: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> getDocumentsByCategory(
    String categoryId,
  ) async {
    try {
      final documents = await _localDataSource.getDocumentsByCategory(categoryId);
      return Right(documents.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get documents by category: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> getExpiredDocuments() async {
    try {
      final documents = await _localDataSource.getExpiredDocuments();
      return Right(documents.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get expired documents: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> getDocumentsExpiringSoon() async {
    try {
      final documents = await _localDataSource.getDocumentsExpiringSoon();
      return Right(documents.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get documents expiring soon: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> getVaultDocuments() async {
    try {
      final documents = await _localDataSource.getVaultDocuments();
      return Right(documents.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get vault documents: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> getDecryptedFileBytes(
    String documentId,
  ) async {
    try {
      final document = await _localDataSource.getDocumentById(documentId);
      if (document == null || document.encryptedFilePath == null) {
        return Left(CacheFailure('Document or file not found'));
      }

      final decryptedBytes = await _fileStorageDataSource.getDecryptedFile(
        document.encryptedFilePath!,
      );

      return Right(decryptedBytes.toList());
    } on FileOperationException catch (e) {
      return Left(FileOperationFailure(e.message));
    } on EncryptionException catch (e) {
      return Left(EncryptionFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure('Failed to get decrypted file: $e'));
    }
  }
}
