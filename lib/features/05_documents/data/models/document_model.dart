import 'package:hive/hive.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_category.dart';



@HiveType(typeId: 0)
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final String fileType;

  @HiveField(4)
  final int fileSizeBytes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final DateTime? expiryDate;

  @HiveField(8)
  final List<String> tags;

  @HiveField(9)
  final String? categoryId;

  @HiveField(10)
  final bool isVault;

  @HiveField(11)
  final bool isHidden;

  @HiveField(12)
  final String? description;

  @HiveField(13)
  final String? encryptedFilePath;

  DocumentModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.fileSizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.tags = const [],
    this.categoryId,
    this.isVault = false,
    this.isHidden = false,
    this.description,
    this.encryptedFilePath,
  });

  /// Converts entity to model
  factory DocumentModel.fromEntity(Document entity) {
    return DocumentModel(
      id: entity.id,
      title: entity.title,
      filePath: entity.filePath,
      fileType: entity.fileType,
      fileSizeBytes: entity.fileSizeBytes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      expiryDate: entity.expiryDate,
      tags: List.from(entity.tags),
      categoryId: entity.category?.id,
      isVault: entity.isVault,
      isHidden: entity.isHidden,
      description: entity.description,
      encryptedFilePath: entity.encryptedFilePath,
    );
  }

  /// Converts model to entity
  Document toEntity() {
    return Document(
      id: id,
      title: title,
      filePath: filePath,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expiryDate: expiryDate,
      tags: List.from(tags),
      category: categoryId != null ? DocumentCategory.getById(categoryId!) : null,
      isVault: isVault,
      isHidden: isHidden,
      description: description,
      encryptedFilePath: encryptedFilePath,
    );
  }

  /// Creates a copy with updated fields
  DocumentModel copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    int? fileSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
    List<String>? tags,
    String? categoryId,
    bool? isVault,
    bool? isHidden,
    String? description,
    String? encryptedFilePath,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      isVault: isVault ?? this.isVault,
      isHidden: isHidden ?? this.isHidden,
      description: description ?? this.description,
      encryptedFilePath: encryptedFilePath ?? this.encryptedFilePath,
    );
  }
}
