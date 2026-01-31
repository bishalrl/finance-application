import 'package:hive/hive.dart';
import 'package:life_vault/core/database/database_helper.dart';
import 'package:life_vault/core/database/hive_service.dart';
import '../models/document_model.dart';


/// Local data source for document operations
class DocumentLocalDataSource {
  final HiveService _hiveService;
  final DatabaseHelper _databaseHelper;

  DocumentLocalDataSource(this._hiveService, this._databaseHelper);

  /// Saves a document
  Future<void> saveDocument(DocumentModel document) async {
    try {
      final box = _hiveService.getBox(HiveService.documentsBox);
      await box.put(document.id, document);
    } catch (e) {
      throw DocumentStorageException('Failed to save document: $e');
    }
  }

  /// Gets a document by ID
  Future<DocumentModel?> getDocumentById(String id) async {
    try {
      final box = _hiveService.getBox(HiveService.documentsBox);
      return box.get(id) as DocumentModel?;
    } catch (e) {
      throw DocumentStorageException('Failed to get document: $e');
    }
  }

  /// Gets all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final box = _hiveService.getBox(HiveService.documentsBox);
      return box.values.cast<DocumentModel>().toList();
    } catch (e) {
      throw DocumentStorageException('Failed to get all documents: $e');
    }
  }

  /// Gets documents by category
  Future<List<DocumentModel>> getDocumentsByCategory(String categoryId) async {
    try {
      final allDocuments = await getAllDocuments();
      return allDocuments.where((doc) => doc.categoryId == categoryId).toList();
    } catch (e) {
      throw DocumentStorageException('Failed to get documents by category: $e');
    }
  }

  /// Gets documents with expiry dates
  Future<List<DocumentModel>> getDocumentsWithExpiry() async {
    try {
      final allDocuments = await getAllDocuments();
      return allDocuments.where((doc) => doc.expiryDate != null).toList();
    } catch (e) {
      throw DocumentStorageException('Failed to get documents with expiry: $e');
    }
  }

  /// Gets expired documents
  Future<List<DocumentModel>> getExpiredDocuments() async {
    try {
      final allDocuments = await getAllDocuments();
      final now = DateTime.now();
      return allDocuments.where((doc) => 
        doc.expiryDate != null && doc.expiryDate!.isBefore(now)
      ).toList();
    } catch (e) {
      throw DocumentStorageException('Failed to get expired documents: $e');
    }
  }

  /// Gets documents expiring soon (within 30 days)
  Future<List<DocumentModel>> getDocumentsExpiringSoon() async {
    try {
      final allDocuments = await getAllDocuments();
      final now = DateTime.now();
      return allDocuments.where((doc) {
        if (doc.expiryDate == null) return false;
        final daysUntil = doc.expiryDate!.difference(now).inDays;
        return daysUntil > 0 && daysUntil <= 30;
      }).toList();
    } catch (e) {
      throw DocumentStorageException('Failed to get documents expiring soon: $e');
    }
  }

  /// Searches documents by title or tags
  Future<List<DocumentModel>> searchDocuments(String query) async {
    try {
      final allDocuments = await getAllDocuments();
      final lowerQuery = query.toLowerCase();
      
      return allDocuments.where((doc) {
        final titleMatch = doc.title.toLowerCase().contains(lowerQuery);
        final tagMatch = doc.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        final descMatch = doc.description?.toLowerCase().contains(lowerQuery) ?? false;
        
        return titleMatch || tagMatch || descMatch;
      }).toList();
    } catch (e) {
      throw DocumentStorageException('Failed to search documents: $e');
    }
  }

  /// Gets vault documents (only when vault is unlocked)
  Future<List<DocumentModel>> getVaultDocuments() async {
    try {
      final allDocuments = await getAllDocuments();
      return allDocuments.where((doc) => doc.isVault).toList();
    } catch (e) {
      throw DocumentStorageException('Failed to get vault documents: $e');
    }
  }

  /// Deletes a document
  Future<void> deleteDocument(String id) async {
    try {
      final box = _hiveService.getBox(HiveService.documentsBox);
      await box.delete(id);
    } catch (e) {
      throw DocumentStorageException('Failed to delete document: $e');
    }
  }

  /// Updates a document
  Future<void> updateDocument(DocumentModel document) async {
    try {
      await saveDocument(document);
    } catch (e) {
      throw DocumentStorageException('Failed to update document: $e');
    }
  }

  /// Gets document count
  Future<int> getDocumentCount() async {
    try {
      final box = _hiveService.getBox(HiveService.documentsBox);
      return box.length;
    } catch (e) {
      throw DocumentStorageException('Failed to get document count: $e');
    }
  }
}

class DocumentStorageException implements Exception {
  final String message;
  DocumentStorageException(this.message);
  
  @override
  String toString() => 'DocumentStorageException: $message';
}
