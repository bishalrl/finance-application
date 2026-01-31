import 'package:equatable/equatable.dart';

/// Document category entity
class DocumentCategory extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String? color;

  const DocumentCategory({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  /// Predefined categories
  static const List<DocumentCategory> predefined = [
    DocumentCategory(id: 'personal', name: 'Personal', icon: 'person', color: '#2196F3'),
    DocumentCategory(id: 'financial', name: 'Financial', icon: 'account_balance', color: '#4CAF50'),
    DocumentCategory(id: 'medical', name: 'Medical', icon: 'local_hospital', color: '#F44336'),
    DocumentCategory(id: 'work', name: 'Work', icon: 'work', color: '#FF9800'),
    DocumentCategory(id: 'misc', name: 'Misc', icon: 'folder', color: '#9E9E9E'),
  ];

  /// Get category by ID
  static DocumentCategory? getById(String id) {
    try {
      return predefined.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, name, icon, color];
}
