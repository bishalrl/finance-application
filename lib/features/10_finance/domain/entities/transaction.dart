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
  final String? rawMessage;
  final String? remark; // Deprecated: use rawRemark or systemRemark
  final String? rawRemark;
  final String? systemRemark;
  final String? sender; // SMS Sender ID (e.g. NabilBank, eSewa)

  // ─── New fields for structured data extraction ────────────────────────────
  final String? sourceKey; // Normalized sender (uppercase, no symbols)
  final String? bankName; // Resolved bank name (e.g. "NIC Asia Bank")
  final String? title; // "BankName TransactionType" (e.g. "NIC Asia Debit")
  final String? userRemark; // User-editable remark (starts empty)

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
    this.rawMessage,
    this.remark,
    this.rawRemark,
    this.systemRemark,
    this.sender,
    this.sourceKey,
    this.bankName,
    this.title,
    this.userRemark,
  });

  /// User-facing display remark: userRemark first, then rawRemark, systemRemark, old remark
  String? get displayRemark => userRemark ?? rawRemark ?? systemRemark ?? remark;

  /// Display title: title if set, else rawRemark/merchant/description
  String get displayTitle =>
      title ??
      rawRemark ??
      merchant ??
      description;

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
    String? rawMessage,
    String? remark,
    String? rawRemark,
    String? systemRemark,
    String? sender,
    String? sourceKey,
    String? bankName,
    String? title,
    String? userRemark,
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
      rawMessage: rawMessage ?? this.rawMessage,
      remark: remark ?? this.remark,
      rawRemark: rawRemark ?? this.rawRemark,
      systemRemark: systemRemark ?? this.systemRemark,
      sender: sender ?? this.sender,
      sourceKey: sourceKey ?? this.sourceKey,
      bankName: bankName ?? this.bankName,
      title: title ?? this.title,
      userRemark: userRemark ?? this.userRemark,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    type,
    description,
    category,
    date,
    merchant,
    isAutoCategorized,
    reference,
    rawMessage,
    remark,
    rawRemark,
    systemRemark,
    sender,
    sourceKey,
    bankName,
    title,
    userRemark,
  ];
}
