import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/time_period.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends FinanceEvent {
  const LoadTransactions();
}

class ParseSmsTransactionsEvent extends FinanceEvent {
  const ParseSmsTransactionsEvent();
}

class FilterByType extends FinanceEvent {
  final TransactionType? type; // null = all

  const FilterByType(this.type);

  @override
  List<Object?> get props => [type];
}

class FilterByCategory extends FinanceEvent {
  final String? category; // null = all

  const FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterByPeriod extends FinanceEvent {
  final int? year;
  final int? month; // null = all time

  const FilterByPeriod({this.year, this.month});

  @override
  List<Object?> get props => [year, month];
}

class UpdateTransactionCategory extends FinanceEvent {
  final String transactionId;
  final String category;

  const UpdateTransactionCategory(this.transactionId, this.category);

  @override
  List<Object?> get props => [transactionId, category];
}

class LoadSummary extends FinanceEvent {
  final TimePeriod period;
  final DateTime date;

  const LoadSummary(this.period, this.date);

  @override
  List<Object?> get props => [period, date];
}
