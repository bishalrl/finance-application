import 'package:hive/hive.dart';
import '../../domain/entities/document_category.dart';



@HiveType(typeId: 1)
class DocumentCategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? icon;

  @HiveField(3)
  final String? color;

  DocumentCategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  /// Converts entity to model
  factory DocumentCategoryModel.fromEntity(DocumentCategory entity) {
    return DocumentCategoryModel(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
    );
  }

  /// Converts model to entity
  DocumentCategory toEntity() {
    return DocumentCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
    );
  }
}
