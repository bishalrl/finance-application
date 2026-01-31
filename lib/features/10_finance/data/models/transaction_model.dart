import '../../domain/entities/transaction.dart';

/// Converts Transaction to/from Map for Hive (only extracted fields, no raw SMS).
class TransactionModel {
  static Map<String, dynamic> toMap(Transaction t) {
    return {
      'id': t.id,
      'amount': t.amount,
      'type': t.type == TransactionType.credit ? 0 : 1,
      'description': t.description,
      'category': t.category,
      'date': t.date.millisecondsSinceEpoch,
      'merchant': t.merchant,
      'isAutoCategorized': t.isAutoCategorized,
      'reference': t.reference,
    };
  }

  static int _intFromDynamic(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return 0;
  }

  static Transaction fromMap(Map<dynamic, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: _intFromDynamic(map['type']) == 0 ? TransactionType.credit : TransactionType.debit,
      description: map['description'] as String,
      category: map['category'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(_intFromDynamic(map['date'])),
      merchant: map['merchant'] as String?,
      isAutoCategorized: map['isAutoCategorized'] as bool? ?? false,
      reference: map['reference'] as String?,
    );
  }
}
