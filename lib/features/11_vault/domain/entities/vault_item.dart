import 'package:equatable/equatable.dart';

enum VaultItemType { document, note, other }

class VaultItem extends Equatable {
  final String id;
  final VaultItemType type;
  final String originalId; // ID of original item
  final String title;
  final bool isHidden;
  final DateTime createdAt;

  const VaultItem({
    required this.id,
    required this.type,
    required this.originalId,
    required this.title,
    this.isHidden = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, originalId, title, isHidden, createdAt];
}
