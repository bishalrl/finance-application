import 'package:dartz/dartz.dart';
import '../repositories/subscription_repository.dart';
import '../../../../core/errors/failures.dart';

enum Feature {
  unlimitedDocuments,
  vault,
  financeTracking,
  sync,
  advancedReminders,
  noAds,
}

class CheckFeaturesAccess {
  final SubscriptionRepository repository;
  CheckFeaturesAccess(this.repository);

  Future<Either<Failure, bool>> call(Feature feature) async {
    return await repository.canUseFeature(feature.name);
  }
}
