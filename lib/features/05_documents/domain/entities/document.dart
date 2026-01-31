import 'package:equatable/equatable.dart';
import 'package:life_vault/features/05_documents/domain/entities/document_category.dart';

/// Document entity representing a stored document
class Document extends Equatable {
  final String id;
  final String title;
  final String filePath;
  final String fileType;
  final int fileSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiryDate;
  final List<String> tags;
  final DocumentCategory? category;
  final bool isVault;
  final bool isHidden;
  final String? description;
  final String? encryptedFilePath; // Path to encrypted file

  const Document({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.fileSizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.tags = const [],
    this.category,
    this.isVault = false,
    this.isHidden = false,
    this.description,
    this.encryptedFilePath,
  });

  /// Checks if document is expired
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// Checks if document expires soon (within 30 days)
  bool get expiresSoon => expiryDate != null && 
      !isExpired &&
      expiryDate!.difference(DateTime.now()).inDays <= 30;

  /// Gets days until expiry (negative if expired)
  int get daysUntilExpiry {
    if (expiryDate == null) return 999999; // No expiry
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Gets expiry status color
  /// Returns: 'red' if expired, 'orange' if expires soon, 'green' if fine
  String get expiryStatus {
    if (isExpired) return 'red';
    if (expiresSoon) return 'orange';
    return 'green';
  }

  /// Creates a copy with updated fields
  Document copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    int? fileSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
    List<String>? tags,
    DocumentCategory? category,
    bool? isVault,
    bool? isHidden,
    String? description,
    String? encryptedFilePath,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isVault: isVault ?? this.isVault,
      isHidden: isHidden ?? this.isHidden,
      description: description ?? this.description,
      encryptedFilePath: encryptedFilePath ?? this.encryptedFilePath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        filePath,
        fileType,
        fileSizeBytes,
        createdAt,
        updatedAt,
        expiryDate,
        tags,
        category,
        isVault,
        isHidden,
        description,
        encryptedFilePath,
      ];
}
