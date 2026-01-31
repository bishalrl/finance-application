import 'package:flutter/material.dart';

/// SMS permission requested once, with explanation. Parsing is on-device only; no raw SMS stored.
class SmsPermissionDialog extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const SmsPermissionDialog({
    super.key,
    this.onGranted,
    this.onDenied,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SmsPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import from SMS'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Life Vault can read transactional SMS from your bank, wallet, or UPI app to show you where your money goes — roughly.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 16),
            Text('What we do:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('• Parse only messages that look like debit/credit alerts'),
            Text('• Extract amount, type, merchant, and date'),
            Text('• Store only these fields on your device (no raw SMS kept)'),
            Text('• No cloud, no bank login, no account linking'),
            SizedBox(height: 12),
            Text('What we ignore:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('• OTPs, marketing, personal texts'),
            SizedBox(height: 16),
            Text(
              'Permission is used only for this. You can revoke it anytime in system settings.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onDenied?.call();
          },
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onGranted?.call();
          },
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
