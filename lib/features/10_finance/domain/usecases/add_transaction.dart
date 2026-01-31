import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';
import '../../../../core/errors/failures.dart';

class AddTransaction {
  final FinanceRepository repository;

  AddTransaction(this.repository);

  Future<Either<Failure, Transaction>> call({
    required double amount,
    required TransactionType type,
    required String description,
    String? category,
    required DateTime date,
    String? merchant,
  }) async {
    final t = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      description: description,
      category: category,
      date: date,
      merchant: merchant,
      isAutoCategorized: false,
    );
    return await repository.addTransaction(t);
  }
}
