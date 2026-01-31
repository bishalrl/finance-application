import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/document.dart';
import '../entities/document_category.dart';
import '../repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';

/// Use case for adding a document
/// 
/// Business Logic:
/// 1. Validates file size based on subscription (50MB free, 200MB pro)
/// 2. Validates file type
/// 3. Encrypts file with user's master key
/// 4. Stores metadata in encrypted Hive box
/// 5. Creates reminder if expiry date is set
class AddDocument {
  final DocumentRepository repository;
  final CheckFeaturesAccess? checkFeaturesAccess; // Optional for subscription check

  AddDocument(this.repository, [this.checkFeaturesAccess]);

  /// Executes the use case
  /// 
  /// [title] - Document title
  /// [fileBytes] - File bytes to store
  /// [fileType] - File type/extension
  /// [category] - Document category
  /// [expiryDate] - Optional expiry date
  /// [tags] - Optional tags
  /// [isVault] - Whether to move to vault
  /// [description] - Optional description
  Future<Either<Failure, Document>> call({
    required String title,
    required List<int> fileBytes,
    required String fileType,
    String? categoryId,
    DateTime? expiryDate,
    List<String> tags = const [],
    bool isVault = false,
    String? description,
  }) async {
    try {
      // Validate file size
      final fileSizeMB = fileBytes.length / (1024 * 1024);
      
      // Check subscription for file size limits
      // Free: 50MB, Pro: 200MB
      final maxSizeMB = await _getMaxFileSizeMB();
      if (fileSizeMB > maxSizeMB) {
        return Left(ValidationFailure(
          'File size exceeds limit. Maximum: ${maxSizeMB}MB. Current: ${fileSizeMB.toStringAsFixed(2)}MB',
        ));
      }

      // Validate file type
      if (!_isValidFileType(fileType)) {
        return Left(ValidationFailure('Invalid file type: $fileType'));
      }

      // Create document entity
      final now = DateTime.now();
      final document = Document(
        id: const Uuid().v4(),
        title: title,
        filePath: '$title.$fileType', // Original file name
        fileType: fileType,
        fileSizeBytes: fileBytes.length,
        createdAt: now,
        updatedAt: now,
        expiryDate: expiryDate,
        tags: tags,
        category: categoryId != null 
            ? DocumentCategory.getById(categoryId) 
            : null,
        isVault: isVault,
        description: description,
      );

      // Add document (encrypts and stores)
      final result = await repository.addDocument(document, fileBytes);
      return result;
    } catch (e) {
      return Left(GeneralFailure('Failed to add document: $e'));
    }
  }

  /// Gets maximum file size in MB based on subscription
  Future<double> _getMaxFileSizeMB() async {
    // Default to free tier limit
    if (checkFeaturesAccess == null) {
      return 50.0; // Free tier: 50MB
    }

    // Check if user has pro features
    final hasPro = await checkFeaturesAccess!.call(Feature.unlimitedDocuments);
    return hasPro.fold(
      (failure) => 50.0, // Default to free on error
      (hasAccess) => hasAccess ? 200.0 : 50.0, // Pro: 200MB, Free: 50MB
    );
  }

  /// Validates file type
  bool _isValidFileType(String fileType) {
    const allowedTypes = [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'txt',
      'csv',
    ];
    return allowedTypes.contains(fileType.toLowerCase());
  }
}

/// Feature enum for subscription checks
enum Feature {
  unlimitedDocuments,
  vault,
  financeTracking,
  sync,
  advancedReminders,
  noAds,
}

/// Use case for checking feature access (from subscription module)
/// This is a placeholder - will be implemented in subscription module
abstract class CheckFeaturesAccess {
  Future<Either<Failure, bool>> call(Feature feature);
}
