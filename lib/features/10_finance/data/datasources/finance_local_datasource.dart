import 'package:life_vault/core/database/hive_service.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';

/// Stores only extracted transaction fields (no raw SMS). On-device only.
class FinanceLocalDataSource {
  final HiveService _hiveService;

  FinanceLocalDataSource(this._hiveService);

  Future<void> saveTransaction(Transaction transaction) async {
    final box = _hiveService.getBox(HiveService.transactionsBox);
    await box.put(transaction.id, TransactionModel.toMap(transaction));
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    for (final t in transactions) {
      await saveTransaction(t);
    }
  }

  Future<List<Transaction>> getAllTransactions() async {
    final box = _hiveService.getBox(HiveService.transactionsBox);
    final list = <Transaction>[];
    for (final value in box.values) {
      if (value is Map) {
        list.add(TransactionModel.fromMap(Map<String, dynamic>.from(value as Map)));
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<Transaction?> getTransactionById(String id) async {
    final box = _hiveService.getBox(HiveService.transactionsBox);
    final value = box.get(id);
    if (value == null || value is! Map) return null;
    return TransactionModel.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await saveTransaction(transaction);
  }

  Future<void> updateCategory(String id, String category) async {
    final t = await getTransactionById(id);
    if (t == null) return;
    await saveTransaction(t.copyWith(category: category, isAutoCategorized: false));
  }

  Future<void> deleteTransaction(String id) async {
    final box = _hiveService.getBox(HiveService.transactionsBox);
    await box.delete(id);
  }

  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final all = await getAllTransactions();
    return all.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
  }

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(start, end);
  }
}
