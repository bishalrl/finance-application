import 'package:dartz/dartz.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';
import '../../../../core/errors/failures.dart';

class PurchasePro {
  final SubscriptionRepository repository;
  PurchasePro(this.repository);

  Future<Either<Failure, Subscription>> call({bool isYearly = false}) async {
    return await repository.purchasePro(isYearly: isYearly);
  }
}
