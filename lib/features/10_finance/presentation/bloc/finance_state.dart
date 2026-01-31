import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/time_period.dart';

enum FinanceStatus { initial, loading, loaded, error }

class FinanceState extends Equatable {
  final FinanceStatus status;
  final List<Transaction> transactions;
  final TransactionType? filterType;
  final String? filterCategory;
  final int? filterYear;
  final int? filterMonth;
  final Map<String, dynamic>? summaryData;
  final TimePeriod summaryPeriod;
  final DateTime summaryDate;
  final String? errorMessage;

  FinanceState({
    this.status = FinanceStatus.initial,
    this.transactions = const [],
    this.filterType,
    this.filterCategory,
    this.filterYear,
    this.filterMonth,
    this.summaryData,
    this.summaryPeriod = TimePeriod.monthly,
    DateTime? summaryDate,
    this.errorMessage,
  }) : summaryDate =
           summaryDate ??
           DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<Transaction> get filteredTransactions {
    var list = List<Transaction>.from(transactions);
    if (filterType != null) {
      list = list.where((t) => t.type == filterType).toList();
    }
    if (filterCategory != null && filterCategory!.isNotEmpty) {
      list = list
          .where((t) => (t.category ?? 'Other') == filterCategory)
          .toList();
    }
    if (filterYear != null && filterMonth != null) {
      list = list
          .where(
            (t) => t.date.year == filterYear && t.date.month == filterMonth,
          )
          .toList();
    }
    return list;
  }

  double get totalCredit => filteredTransactions
      .where((t) => t.type == TransactionType.credit)
      .fold(0.0, (s, t) => s + t.amount);
  double get totalDebit => filteredTransactions
      .where((t) => t.type == TransactionType.debit)
      .fold(0.0, (s, t) => s + t.amount);

  FinanceState copyWith({
    FinanceStatus? status,
    List<Transaction>? transactions,
    TransactionType? filterType,
    String? filterCategory,
    int? filterYear,
    int? filterMonth,
    Map<String, dynamic>? summaryData,
    TimePeriod? summaryPeriod,
    DateTime? summaryDate,
    String? errorMessage,
  }) {
    return FinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filterType: filterType ?? this.filterType,
      filterCategory: filterCategory ?? this.filterCategory,
      filterYear: filterYear ?? this.filterYear,
      filterMonth: filterMonth ?? this.filterMonth,
      summaryData: summaryData ?? this.summaryData,
      summaryPeriod: summaryPeriod ?? this.summaryPeriod,
      summaryDate: summaryDate ?? this.summaryDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    filterType,
    filterCategory,
    filterYear,
    filterMonth,
    summaryData,
    summaryPeriod,
    summaryDate,
    errorMessage,
  ];
}
