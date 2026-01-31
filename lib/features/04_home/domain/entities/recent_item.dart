import 'package:equatable/equatable.dart';

enum RecentItemType { document, note, idea }

class RecentItem extends Equatable {
  final RecentItemType type;
  final String id;
  final String title;
  final String? subtitle;
  final DateTime updatedAt;

  const RecentItem({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [type, id, title, subtitle, updatedAt];
}
