import 'package:dartz/dartz.dart';
import '../entities/subscription.dart';
import '../../../../core/errors/failures.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, Subscription>> getSubscriptionStatus();
  Future<Either<Failure, Subscription>> purchasePro({bool isYearly = false});
  Future<Either<Failure, Subscription>> purchaseSync();
  Future<Either<Failure, Subscription>> purchaseMaintenance();
  Future<Either<Failure, Subscription>> restorePurchases();
  Future<Either<Failure, bool>> canUseFeature(String feature);
}
