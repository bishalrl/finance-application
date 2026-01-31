import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

/// Transaction list: chronological. Filter by credit/debit, category, time period. Categories editable.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          _FilterChips(),
          Expanded(
            child: BlocBuilder<FinanceBloc, FinanceState>(
              buildWhen: (p, c) => p.transactions != c.transactions || p.filterType != c.filterType || p.filterCategory != c.filterCategory || p.filterYear != c.filterYear || p.filterMonth != c.filterMonth,
              builder: (context, state) {
                final list = state.filteredTransactions;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import from SMS or add manually',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final t = list[index];
                    return _TransactionTile(
                      transaction: t,
                      onTapCategory: () => _showCategoryPicker(context, t),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, Transaction t) {
    const categories = ['Food', 'Travel', 'Shopping', 'Bills', 'Medical', 'Entertainment', 'Income', 'Other'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Category', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...categories.map((cat) => ListTile(
                  title: Text(cat),
                  onTap: () {
                    context.read<FinanceBloc>().add(UpdateTransactionCategory(t.id, cat));
                    Navigator.of(ctx).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      buildWhen: (p, c) => p.filterType != c.filterType || p.filterCategory != c.filterCategory,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.filterType == null,
                onSelected: (_) => context.read<FinanceBloc>().add(const FilterByType(null)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Credit'),
                selected: state.filterType == TransactionType.credit,
                onSelected: (_) => context.read<FinanceBloc>().add(const FilterByType(TransactionType.credit)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Debit'),
                selected: state.filterType == TransactionType.debit,
                onSelected: (_) => context.read<FinanceBloc>().add(const FilterByType(TransactionType.debit)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTapCategory;

  const _TransactionTile({
    required this.transaction,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isCredit ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.2),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}${transaction.category != null ? ' · ${transaction.category}' : ''}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isCredit ? const Color(0xFF10B981) : const Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
            ),
      ),
      onTap: onTapCategory,
    );
  }
}
