import 'package:hive/hive.dart';
import 'package:life_vault/core/database/hive_service.dart';
import '../models/subscription_model.dart';

class SubscriptionLocalDataSource {
  final HiveService _hiveService;

  SubscriptionLocalDataSource(this._hiveService);

  Future<void> saveSubscription(SubscriptionModel subscription) async {
    final box = _hiveService.getBox(HiveService.subscriptionBox);
    await box.put('current', subscription);
  }

  Future<SubscriptionModel?> getCurrentSubscription() async {
    final box = _hiveService.getBox(HiveService.subscriptionBox);
    return box.get('current') as SubscriptionModel?;
  }
}
