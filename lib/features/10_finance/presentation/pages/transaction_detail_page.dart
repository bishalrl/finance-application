import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../theme/finance_theme.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? FinanceTheme.creditColor : FinanceTheme.debitColor;
    final title = transaction.title ?? transaction.merchant ?? transaction.rawRemark ?? transaction.description;
    final remark = transaction.userRemark ?? transaction.rawRemark ?? transaction.systemRemark ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(FinanceTheme.pagePadding),
        children: [
          Container(
            padding: const EdgeInsets.all(FinanceTheme.cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isCredit ? '+' : '-'}$kCurrencySymbol ${transaction.amount.toStringAsFixed(2)}',
                  style: FinanceTheme.amountLarge(context).copyWith(color: color),
                ),
                const SizedBox(height: 10),
                _kv(context, 'Date', DateFormat.yMMMd().add_jm().format(transaction.date)),
                _kv(context, 'Category', transaction.category ?? 'Other'),
                _kv(context, 'Bank/Source', transaction.bankName ?? transaction.sourceKey ?? transaction.sender ?? '—'),
                _kv(context, 'Sender', transaction.sender ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: FinanceTheme.gapSection),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remark'),
            subtitle: Text(remark),
            trailing: const Icon(Icons.edit),
            onTap: () => _editRemark(context),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delete'),
            textColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  void _editRemark(BuildContext context) {
    final controller = TextEditingController(text: transaction.userRemark ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Remark'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What was this for?',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<FinanceBloc>().add(
                    UpdateTransactionRemark(transaction.id, controller.text.trim()),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        context.read<FinanceBloc>().add(DeleteTransaction(transaction.id));
        Navigator.of(context).pop();
      }
    });
  }
}

