import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

class Transaction extends Equatable {
  final String id;
  final double amount;
  final TransactionType type;
  final String description;
  final String? category;
  final DateTime date;
  final String? merchant;
  final bool isAutoCategorized;
  final String? reference;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.category,
    required this.date,
    this.merchant,
    this.isAutoCategorized = false,
    this.reference,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? description,
    String? category,
    DateTime? date,
    String? merchant,
    bool? isAutoCategorized,
    String? reference,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      isAutoCategorized: isAutoCategorized ?? this.isAutoCategorized,
      reference: reference ?? this.reference,
    );
  }

  @override
  List<Object?> get props => [id, amount, type, description, category, date, merchant, isAutoCategorized, reference];
}
