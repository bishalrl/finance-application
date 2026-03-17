import '../../domain/entities/transaction.dart';

/// Converts Transaction to/from Map for Hive (only extracted fields, no raw SMS).
class TransactionModel {
  static String? _normalizeTitle({
    required String? title,
    required String? bankName,
    required String? sourceKey,
  }) {
    final t = title?.trim();
    if (t == null || t.isEmpty) return t;

    // If old format: "<bank> Credit/Debit", strip suffix.
    final lower = t.toLowerCase();
    if (lower.endsWith(' credit') || lower.endsWith(' debit')) {
      return t.replaceAll(RegExp(r'\s+(Credit|Debit)$', caseSensitive: false), '').trim();
    }

    // If title is missing but bank/source exists, prefer bank/source label.
    final label = (bankName != null && bankName.trim().isNotEmpty && bankName != 'Unknown')
        ? bankName.trim()
        : (sourceKey?.trim().isNotEmpty ?? false)
            ? sourceKey!.trim()
            : null;
    return label ?? t;
  }

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
      'rawMessage': t.rawMessage,
      'remark': t.remark,
      'rawRemark': t.rawRemark,
      'systemRemark': t.systemRemark,
      'sender': t.sender,
      'sourceKey': t.sourceKey,
      'bankName': t.bankName,
      'title': t.title,
      'userRemark': t.userRemark,
    };
  }

  static int _intFromDynamic(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return 0;
  }

  static Transaction fromMap(Map<dynamic, dynamic> map) {
    // Migration: if old remark exists but new fields don't, migrate
    final oldRemark = map['remark'] as String?;
    final rawRemark = map['rawRemark'] as String?;
    final systemRemark = map['systemRemark'] as String?;

    String? migratedRawRemark = rawRemark;
    String? migratedSystemRemark = systemRemark;

    if (oldRemark != null && rawRemark == null && systemRemark == null) {
      migratedRawRemark = oldRemark;
      migratedSystemRemark = _migrateSystemRemark(oldRemark);
    }

    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: _intFromDynamic(map['type']) == 0
          ? TransactionType.credit
          : TransactionType.debit,
      description: map['description'] as String,
      category: map['category'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(_intFromDynamic(map['date'])),
      merchant: map['merchant'] as String?,
      isAutoCategorized: map['isAutoCategorized'] as bool? ?? false,
      reference: map['reference'] as String?,
      rawMessage: map['rawMessage'] as String?,
      remark: oldRemark,
      rawRemark: migratedRawRemark,
      systemRemark: migratedSystemRemark,
      sender: map['sender'] as String?,
      sourceKey: map['sourceKey'] as String?,
      bankName: map['bankName'] as String?,
      title: _normalizeTitle(
        title: map['title'] as String?,
        bankName: map['bankName'] as String?,
        sourceKey: map['sourceKey'] as String?,
      ),
      userRemark: map['userRemark'] as String?, // null for existing data = empty
    );
  }

  /// Migrates old remark to system remark (simple rule-based)
  static String? _migrateSystemRemark(String oldRemark) {
    final remarkLower = oldRemark.toLowerCase();
    if (remarkLower.contains('atm')) return 'Cash withdrawal';
    if (remarkLower.contains('recharge') || remarkLower.contains('topup')) {
      return 'Mobile recharge';
    }
    if (remarkLower.contains('transfer') || remarkLower.contains('trf')) {
      return 'Money transfer';
    }
    if (remarkLower.contains('upi') || remarkLower.contains('vpa')) {
      return 'UPI payment';
    }
    if (remarkLower.contains('bill')) return 'Bill payment';
    return 'Expense';
  }
}
