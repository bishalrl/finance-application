import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final DateTime date;
  final String? transactionId;
  final bool isSuccessful;

  const Payment({
    required this.id,
    required this.amount,
    this.currency = 'USD',
    required this.date,
    this.transactionId,
    this.isSuccessful = false,
  });

  @override
  List<Object?> get props => [id, amount, currency, date, transactionId, isSuccessful];
}
