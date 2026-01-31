import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_all_transactions.dart';
import '../../domain/usecases/parse_sms_transactions.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/categorize_transaction.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final GetAllTransactions getAllTransactions;
  final ParseSmsTransactions parseSmsTransactions;
  final GetMonthlySummary getMonthlySummary;
  final CategorizeTransaction categorizeTransaction;

  FinanceBloc({
    required this.getAllTransactions,
    required this.parseSmsTransactions,
    required this.getMonthlySummary,
    required this.categorizeTransaction,
  }) : super(FinanceState()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<ParseSmsTransactionsEvent>(_onParseSms);
    on<LoadSummary>(_onLoadSummary);
    on<FilterByType>(_onFilterByType);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByPeriod>(_onFilterByPeriod);
    on<UpdateTransactionCategory>(_onUpdateCategory);
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
}
