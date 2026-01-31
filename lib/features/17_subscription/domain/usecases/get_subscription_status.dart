import 'package:dartz/dartz.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';
import '../../../../core/errors/failures.dart';

class GetSubscriptionStatus {
  final SubscriptionRepository repository;
  GetSubscriptionStatus(this.repository);

  Future<Either<Failure, Subscription>> call() async {
    return await repository.getSubscriptionStatus();
  }
}
