import 'package:dartz/dartz.dart';
import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';
import '../../../../core/errors/failures.dart';

/// User can reassign category manually (categories are editable).
class CategorizeTransaction {
  final FinanceRepository repository;

  CategorizeTransaction(this.repository);

  Future<Either<Failure, Transaction>> call(String transactionId, String category) async {
    return await repository.updateCategory(transactionId, category);
  }
}
