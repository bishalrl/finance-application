import 'package:equatable/equatable.dart';

enum SearchResultType { document, note, idea, reminder, transaction }

class SearchResult extends Equatable {
  final String id;
  final SearchResultType type;
  final String title;
  final String? preview;
  final double relevanceScore;
  final DateTime? date;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.preview,
    this.relevanceScore = 0.0,
    this.date,
  });

  @override
  List<Object?> get props => [id, type, title, preview, relevanceScore, date];
}
