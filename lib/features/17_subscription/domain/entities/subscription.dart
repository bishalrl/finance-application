import 'package:equatable/equatable.dart';

enum SubscriptionTier { free, pro, sync, maintenance }

class Subscription extends Equatable {
  final String id;
  final SubscriptionTier tier;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isTrial;
  final DateTime? trialEndDate;

  const Subscription({
    required this.id,
    this.tier = SubscriptionTier.free,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.isTrial = false,
    this.trialEndDate,
  });

  bool get isPro => tier == SubscriptionTier.pro || tier == SubscriptionTier.sync;
  bool get isSync => tier == SubscriptionTier.sync;
  bool get isMaintenance => tier == SubscriptionTier.maintenance;
  bool get isFree => tier == SubscriptionTier.free;

  bool get hasExpired {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [id, tier, startDate, endDate, isActive, isTrial, trialEndDate];
}
