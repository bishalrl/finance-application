import 'package:dartz/dartz.dart';
import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';
import '../../../../core/errors/failures.dart';

class GetAllTransactions {
  final FinanceRepository repository;

  GetAllTransactions(this.repository);

  Future<Either<Failure, List<Transaction>>> call() async {
    return await repository.getAllTransactions();
  }
}
