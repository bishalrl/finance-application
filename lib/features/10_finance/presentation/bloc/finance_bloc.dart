import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_all_transactions.dart';
import '../../domain/usecases/parse_sms_transactions.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/categorize_transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/repositories/finance_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final GetAllTransactions getAllTransactions;
  final ParseSmsTransactions parseSmsTransactions;
  final GetMonthlySummary getMonthlySummary;
  final CategorizeTransaction categorizeTransaction;
  final AddTransaction addTransaction;
  final FinanceRepository _repository;

  FinanceBloc({
    required this.getAllTransactions,
    required this.parseSmsTransactions,
    required this.getMonthlySummary,
    required this.categorizeTransaction,
    required this.addTransaction,
    required FinanceRepository repository,
  }) : _repository = repository,
       super(FinanceState()) {
    // UI-only state updates
    on<SetFinanceTabIndex>(_onSetFinanceTabIndex);
    on<SetAnalyticsTabIndex>(_onSetAnalyticsTabIndex);
    on<ClearAnalyticsTabBusy>(_onClearAnalyticsTabBusy);
    on<SetAnalyticsDetailsExpanded>(_onSetAnalyticsDetailsExpanded);
    on<SetTransactionsTableView>(_onSetTransactionsTableView);
    on<SetTransactionsGroupByColumn>(_onSetTransactionsGroupByColumn);
    on<SetCalendarSelectedMonth>(_onSetCalendarSelectedMonth);
    on<SetSummaryUiPeriod>(_onSetSummaryUiPeriod);
    on<SetSummaryUiFocusedDate>(_onSetSummaryUiFocusedDate);
    on<SetDashboardCarouselPage>(_onSetDashboardCarouselPage);
    on<SetSourceBreakdownTouchedIndex>(_onSetSourceBreakdownTouchedIndex);
    on<SetCategoryBreakdownTouchedIndex>(_onSetCategoryBreakdownTouchedIndex);
    on<SetFlowDetailPeriod>(_onSetFlowDetailPeriod);
    on<SetAddTxnType>(_onSetAddTxnType);
    on<SetAddTxnDate>(_onSetAddTxnDate);
    on<SetAddTxnCategory>(_onSetAddTxnCategory);
    on<SetAddTxnSubmitted>(_onSetAddTxnSubmitted);

    on<LoadTransactions>(_onLoadTransactions);
    on<ParseSmsTransactionsEvent>(_onParseSms);
    on<LoadSummary>(_onLoadSummary);
    on<FilterByType>(_onFilterByType);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByPeriod>(_onFilterByPeriod);
    on<UpdateTransactionCategory>(_onUpdateCategory);
    on<SetSearchQuery>(_onSetSearchQuery);
    on<SetDateRangeFilter>(_onSetDateRangeFilter);
    on<ToggleRecurringCategory>(_onToggleRecurringCategory);
    on<UpdateTransactionRemark>(_onUpdateRemark);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<ReAnalyzeTransactions>(_onReAnalyzeTransactions);
    on<AddTransactionRequested>(_onAddTransactionRequested);
  }

  void _onSetFinanceTabIndex(
    SetFinanceTabIndex event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(financeTabIndex: event.index));
  }

  void _onSetAnalyticsTabIndex(
    SetAnalyticsTabIndex event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(analyticsTabIndex: event.index, analyticsTabBusy: true));
    Future.delayed(const Duration(milliseconds: 220), () {
      add(const ClearAnalyticsTabBusy());
    });
  }

  void _onClearAnalyticsTabBusy(
    ClearAnalyticsTabBusy event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(analyticsTabBusy: false));
  }

  void _onSetAnalyticsDetailsExpanded(
    SetAnalyticsDetailsExpanded event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(analyticsDetailsExpanded: event.expanded));
  }

  void _onSetTransactionsTableView(
    SetTransactionsTableView event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(transactionsIsTableView: event.isTableView));
  }

  void _onSetTransactionsGroupByColumn(
    SetTransactionsGroupByColumn event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(transactionsGroupByColumn: event.groupBy));
  }

  void _onSetCalendarSelectedMonth(
    SetCalendarSelectedMonth event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(calendarSelectedMonth: event.month));
  }

  void _onSetSummaryUiPeriod(
    SetSummaryUiPeriod event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(summaryUiPeriod: event.period));
  }

  void _onSetSummaryUiFocusedDate(
    SetSummaryUiFocusedDate event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(summaryUiFocusedDate: event.date));
  }

  void _onSetDashboardCarouselPage(
    SetDashboardCarouselPage event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(dashboardCarouselPage: event.page));
  }

  void _onSetSourceBreakdownTouchedIndex(
    SetSourceBreakdownTouchedIndex event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(sourceBreakdownTouchedIndex: event.index));
  }

  void _onSetCategoryBreakdownTouchedIndex(
    SetCategoryBreakdownTouchedIndex event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(categoryBreakdownTouchedIndex: event.index));
  }

  void _onSetFlowDetailPeriod(
    SetFlowDetailPeriod event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(flowDetailPeriod: event.period));
  }

  void _onSetAddTxnType(SetAddTxnType event, Emitter<FinanceState> emit) {
    emit(state.copyWith(addTxnType: event.type));
  }

  void _onSetAddTxnDate(SetAddTxnDate event, Emitter<FinanceState> emit) {
    emit(state.copyWith(addTxnDate: event.date));
  }

  void _onSetAddTxnCategory(SetAddTxnCategory event, Emitter<FinanceState> emit) {
    emit(state.copyWith(addTxnCategory: event.category));
  }

  void _onSetAddTxnSubmitted(
    SetAddTxnSubmitted event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(addTxnSubmitted: event.submitted));
  }

  Future<void> _onReAnalyzeTransactions(
    ReAnalyzeTransactions event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    // Implementation: Re-trigger SMS parsing use case
    add(ParseSmsTransactionsEvent());
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading, errorMessage: null));
    final result = await getAllTransactions();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FinanceStatus.error,
          errorMessage: failure.message,
          transactions: [],
        ),
      ),
      (list) => emit(
        state.copyWith(
          status: FinanceStatus.loaded,
          transactions: list,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onParseSms(
    ParseSmsTransactionsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading, errorMessage: null));
    final result = await parseSmsTransactions();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FinanceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (list) => emit(
        state.copyWith(
          status: FinanceStatus.loaded,
          transactions: list,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onFilterByType(FilterByType event, Emitter<FinanceState> emit) {
    emit(state.copyWith(filterType: event.type));
  }

  void _onFilterByCategory(FilterByCategory event, Emitter<FinanceState> emit) {
    emit(state.copyWith(filterCategory: event.category));
  }

  void _onFilterByPeriod(FilterByPeriod event, Emitter<FinanceState> emit) {
    emit(state.copyWith(filterYear: event.year, filterMonth: event.month));
  }

  Future<void> _onUpdateCategory(
    UpdateTransactionCategory event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await categorizeTransaction(
      event.transactionId,
      event.category,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) {
        final list = state.transactions
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        emit(state.copyWith(transactions: list, errorMessage: null));
      },
    );
  }

  Future<void> _onLoadSummary(
    LoadSummary event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await getMonthlySummary.repository.getSummary(
      event.period,
      event.date,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (summary) => emit(
        state.copyWith(
          summaryData: summary,
          summaryPeriod: event.period,
          summaryDate: event.date,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onSetSearchQuery(SetSearchQuery event, Emitter<FinanceState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onSetDateRangeFilter(
    SetDateRangeFilter event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(filterDateFrom: event.from, filterDateTo: event.to));
  }

  void _onToggleRecurringCategory(
    ToggleRecurringCategory event,
    Emitter<FinanceState> emit,
  ) {
    final next = Set<String>.from(state.recurringCategoryLabels);
    if (next.contains(event.category)) {
      next.remove(event.category);
    } else {
      next.add(event.category);
    }
    emit(state.copyWith(recurringCategoryLabels: next));
  }

  Future<void> _onUpdateRemark(
    UpdateTransactionRemark event,
    Emitter<FinanceState> emit,
  ) async {
    final txnIndex = state.transactions.indexWhere(
      (t) => t.id == event.transactionId,
    );
    if (txnIndex < 0) {
      emit(
        state.copyWith(
          errorMessage: 'Transaction not found. Please refresh and try again.',
        ),
      );
      return;
    }

    final txn = state.transactions[txnIndex];
    final updated = txn.copyWith(userRemark: event.remark);
    final result = await _repository.updateTransaction(updated);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        final list = state.transactions
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        emit(state.copyWith(transactions: list, errorMessage: null));
      },
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await _repository.deleteTransaction(event.transactionId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        final list = state.transactions
            .where((t) => t.id != event.transactionId)
            .toList();
        emit(state.copyWith(transactions: list, errorMessage: null));
      },
    );
  }

  Future<void> _onAddTransactionRequested(
    AddTransactionRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading, errorMessage: null));
    final result = await addTransaction(
      amount: event.amount,
      type: event.type,
      description: event.description,
      category: event.category,
      date: event.date,
      merchant: event.merchant,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FinanceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (transaction) {
        final list = [transaction, ...state.transactions];
        emit(state.copyWith(
          status: FinanceStatus.loaded,
          transactions: list,
          errorMessage: null,
        ));
      },
    );
  }
}
