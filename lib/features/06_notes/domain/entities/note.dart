import 'package:equatable/equatable.dart';

/// Note entity with markdown support
class Note extends Equatable {
  final String id;
  final String title;
  final String content; // Markdown content
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final List<String> tags;
  final bool isVault;
  final bool isStarred;
  final bool isPinned;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.tags = const [],
    this.isVault = false,
    this.isStarred = false,
    this.isPinned = false,
  });

  /// Gets preview text (first 100 characters)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  /// Gets word count
  int get wordCount {
    return content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// Creates a copy with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderId,
    List<String>? tags,
    bool? isVault,
    bool? isStarred,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      isVault: isVault ?? this.isVault,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        createdAt,
        updatedAt,
        folderId,
        tags,
        isVault,
        isStarred,
        isPinned,
      ];
}
