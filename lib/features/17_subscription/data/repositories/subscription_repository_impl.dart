import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_datasource.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDataSource _localDataSource;

  SubscriptionRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Subscription>> getSubscriptionStatus() async {
    try {
      final subscription = await _localDataSource.getCurrentSubscription();
      if (subscription == null) {
        return Right(const Subscription(id: 'default', tier: SubscriptionTier.free));
      }
      return Right(subscription.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get subscription: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> purchasePro({bool isYearly = false}) async {
    try {
      // In real implementation, this would integrate with in_app_purchase
      final now = DateTime.now();
      final endDate = isYearly 
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);
      
      final subscription = Subscription(
        id: 'pro_${now.millisecondsSinceEpoch}',
        tier: SubscriptionTier.pro,
        startDate: now,
        endDate: endDate,
        isActive: true,
      );
      
      final model = SubscriptionModel.fromEntity(subscription);
      await _localDataSource.saveSubscription(model);
      return Right(subscription);
    } catch (e) {
      return Left(SubscriptionFailure('Failed to purchase Pro: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> purchaseSync() async {
    try {
      final current = await getSubscriptionStatus();
      return current.fold(
        (failure) => Left(failure),
        (sub) async {
          final updated = Subscription(
            id: sub.id,
            tier: SubscriptionTier.sync,
            startDate: sub.startDate ?? DateTime.now(),
            endDate: sub.endDate,
            isActive: true,
          );
          final model = SubscriptionModel.fromEntity(updated);
          await _localDataSource.saveSubscription(model);
          return Right(updated);
        },
      );
    } catch (e) {
      return Left(SubscriptionFailure('Failed to purchase Sync: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> purchaseMaintenance() async {
    try {
      final current = await getSubscriptionStatus();
      return current.fold(
        (failure) => Left(failure),
        (sub) async {
          final now = DateTime.now();
          final updated = Subscription(
            id: sub.id,
            tier: sub.tier,
            startDate: sub.startDate,
            endDate: sub.endDate,
            isActive: sub.isActive,
            isTrial: sub.isTrial,
            trialEndDate: DateTime(now.year + 1, now.month, now.day),
          );
          final model = SubscriptionModel.fromEntity(updated);
          await _localDataSource.saveSubscription(model);
          return Right(updated);
        },
      );
    } catch (e) {
      return Left(SubscriptionFailure('Failed to purchase Maintenance: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> restorePurchases() async {
    // In real implementation, verify with app store
    return await getSubscriptionStatus();
  }

  @override
  Future<Either<Failure, bool>> canUseFeature(String feature) async {
    try {
      final subscription = await getSubscriptionStatus();
      return subscription.fold(
        (failure) => Right(false),
        (sub) {
          switch (feature) {
            case 'unlimitedDocuments':
            case 'vault':
            case 'financeTracking':
            case 'advancedReminders':
            case 'noAds':
              return Right(sub.isPro);
            case 'sync':
              return Right(sub.isSync);
            default:
              return Right(false);
          }
        },
      );
    } catch (e) {
      return Right(false);
    }
  }
}
