import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import 'finance_state.dart';
import '../../domain/entities/time_period.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

// ─── UI-only events (no data duplication) ───────────────────────────────────

class SetFinanceTabIndex extends FinanceEvent {
  final int index;
  const SetFinanceTabIndex(this.index);

  @override
  List<Object?> get props => [index];
}

class SetAnalyticsTabIndex extends FinanceEvent {
  final int index;
  const SetAnalyticsTabIndex(this.index);

  @override
  List<Object?> get props => [index];
}

class ClearAnalyticsTabBusy extends FinanceEvent {
  const ClearAnalyticsTabBusy();
}

class SetAnalyticsDetailsExpanded extends FinanceEvent {
  final bool expanded;
  const SetAnalyticsDetailsExpanded(this.expanded);

  @override
  List<Object?> get props => [expanded];
}

class SetTransactionsTableView extends FinanceEvent {
  final bool isTableView;
  const SetTransactionsTableView(this.isTableView);

  @override
  List<Object?> get props => [isTableView];
}

class SetTransactionsGroupByColumn extends FinanceEvent {
  final FinanceGroupByColumn groupBy;
  const SetTransactionsGroupByColumn(this.groupBy);

  @override
  List<Object?> get props => [groupBy];
}

class SetCalendarSelectedMonth extends FinanceEvent {
  final DateTime month;
  const SetCalendarSelectedMonth(this.month);

  @override
  List<Object?> get props => [month];
}

class SetSummaryUiPeriod extends FinanceEvent {
  final TimePeriod period;
  const SetSummaryUiPeriod(this.period);

  @override
  List<Object?> get props => [period];
}

class SetSummaryUiFocusedDate extends FinanceEvent {
  final DateTime date;
  const SetSummaryUiFocusedDate(this.date);

  @override
  List<Object?> get props => [date];
}

class SetDashboardCarouselPage extends FinanceEvent {
  final int page;
  const SetDashboardCarouselPage(this.page);

  @override
  List<Object?> get props => [page];
}

class SetSourceBreakdownTouchedIndex extends FinanceEvent {
  final int index;
  const SetSourceBreakdownTouchedIndex(this.index);

  @override
  List<Object?> get props => [index];
}

class SetCategoryBreakdownTouchedIndex extends FinanceEvent {
  final int index;
  const SetCategoryBreakdownTouchedIndex(this.index);

  @override
  List<Object?> get props => [index];
}

class SetFlowDetailPeriod extends FinanceEvent {
  final FinanceFlowPeriodUi period;
  const SetFlowDetailPeriod(this.period);

  @override
  List<Object?> get props => [period];
}

class SetAddTxnType extends FinanceEvent {
  final AddTransactionTypeUi type;
  const SetAddTxnType(this.type);

  @override
  List<Object?> get props => [type];
}

class SetAddTxnDate extends FinanceEvent {
  final DateTime date;
  const SetAddTxnDate(this.date);

  @override
  List<Object?> get props => [date];
}

class SetAddTxnCategory extends FinanceEvent {
  final String? category;
  const SetAddTxnCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SetAddTxnSubmitted extends FinanceEvent {
  final bool submitted;
  const SetAddTxnSubmitted(this.submitted);

  @override
  List<Object?> get props => [submitted];
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

class SetSearchQuery extends FinanceEvent {
  final String? query;

  const SetSearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}

class SetDateRangeFilter extends FinanceEvent {
  final DateTime? from;
  final DateTime? to;

  const SetDateRangeFilter({this.from, this.to});

  @override
  List<Object?> get props => [from, to];
}

class ToggleRecurringCategory extends FinanceEvent {
  final String category;

  const ToggleRecurringCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateTransactionRemark extends FinanceEvent {
  final String transactionId;
  final String remark;

  const UpdateTransactionRemark(this.transactionId, this.remark);

  @override
  List<Object?> get props => [transactionId, remark];
}

class DeleteTransaction extends FinanceEvent {
  final String transactionId;

  const DeleteTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class ReAnalyzeTransactions extends FinanceEvent {
  const ReAnalyzeTransactions();
}

class AddTransactionRequested extends FinanceEvent {
  final double amount;
  final TransactionType type;
  final String description;
  final String? category;
  final DateTime date;
  final String? merchant;

  const AddTransactionRequested({
    required this.amount,
    required this.type,
    required this.description,
    this.category,
    required this.date,
    this.merchant,
  });

  @override
  List<Object?> get props => [amount, type, description, category, date, merchant];
}
