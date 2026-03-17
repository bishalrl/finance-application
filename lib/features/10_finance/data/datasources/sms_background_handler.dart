import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../../domain/usecases/parse_sms_transactions.dart';

/// Top-level background message handler for telephony.
/// MUST be annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  debugPrint('Finance: Background SMS received from ${message.address}');

  try {
    // Re-initialize DI in this isolate if needed
    if (!di.sl.isRegistered<ParseSmsTransactions>()) {
      await di.init();
    }

    final parseSms = di.sl<ParseSmsTransactions>();
    final result = await parseSms();

    result.fold(
      (failure) =>
          debugPrint('Finance: Background sync failed: ${failure.message}'),
      (list) => debugPrint(
        'Finance: Background sync successful. ${list.length} total transactions.',
      ),
    );
  } catch (e) {
    debugPrint('Finance: Error in background isolate: $e');
  }
}
