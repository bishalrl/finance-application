import 'package:hive/hive.dart';
import '../../domain/entities/subscription.dart';


@HiveType(typeId: 7)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final SubscriptionTier tier;
  @HiveField(2)
  final DateTime? startDate;
  @HiveField(3)
  final DateTime? endDate;
  @HiveField(4)
  final bool isActive;
  @HiveField(5)
  final bool isTrial;
  @HiveField(6)
  final DateTime? trialEndDate;

  SubscriptionModel({
    required this.id,
    this.tier = SubscriptionTier.free,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.isTrial = false,
    this.trialEndDate,
  });

  factory SubscriptionModel.fromEntity(Subscription entity) {
    return SubscriptionModel(
      id: entity.id,
      tier: entity.tier,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      isTrial: entity.isTrial,
      trialEndDate: entity.trialEndDate,
    );
  }

  Subscription toEntity() {
    return Subscription(
      id: id,
      tier: tier,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      isTrial: isTrial,
      trialEndDate: trialEndDate,
    );
  }
}
