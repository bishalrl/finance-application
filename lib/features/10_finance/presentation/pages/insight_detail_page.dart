import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/entities/finance_category.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import 'filtered_transactions_page.dart';

class InsightDetailPage extends StatelessWidget {
  final InsightData insight;

  const InsightDetailPage({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insight')),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          final (title, subtitle, txns) = _buildInsight(state);
          return ListView(
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            children: [
              Container(
                padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                decoration: BoxDecoration(
                  gradient: FinanceTheme.insightCardGradient(insight.color),
                  borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
                  boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(insight.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FinanceTheme.gapSection),
              if (insight.categoryFilter != null || insight.merchantFilter != null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<FinanceBloc>(),
                          child: FilteredTransactionsPage(
                            title: insight.title,
                            category: insight.categoryFilter,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('View matching transactions'),
                ),
              const SizedBox(height: FinanceTheme.gapSection),
              Text(
                'Transactions',
                style: FinanceTheme.sectionTitle(context),
              ),
              const SizedBox(height: FinanceTheme.gapBetweenCards),
              if (txns.isEmpty)
                Text(
                  'No matching transactions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                ...txns.take(50).map((t) {
                  final isCredit = t.type == TransactionType.credit;
                  final title =
                      t.title ?? t.merchant ?? t.rawRemark ?? t.description;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(t.date)} • ${(t.category ?? 'Other')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${isCredit ? '+' : '-'}$kCurrencySymbol ${t.amount.toStringAsFixed(0)}',
                      style: FinanceTheme.amountTrailing(context, isCredit: isCredit),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  (String, String, List<Transaction>) _buildInsight(FinanceState state) {
    switch (insight.kind) {
      case InsightKind.moneyMirror:
        final cat = insight.categoryFilter;
        final txns = cat == null
            ? const <Transaction>[]
            : state.transactions
                .where((t) => (t.category ?? 'Other') == cat)
                .toList();
        return (
          insight.title,
          insight.description,
          txns
        );
      case InsightKind.noSpendDays:
        final now = DateTime.now();
        final txns = state.transactions
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
        return (insight.title, insight.description, txns);
      case InsightKind.attentionNeeded:
        return (insight.title, insight.description, state.unlabeledTransactions);
      case InsightKind.spendingPattern:
        final merchant = insight.merchantFilter;
        final txns = merchant == null
            ? const <Transaction>[]
            : state.transactions
                .where((t) => (t.merchant ?? t.sender ?? t.rawRemark) == merchant)
                .toList();
        return (insight.title, insight.description, txns);
      case InsightKind.forecast:
        final now = DateTime.now();
        final txns = state.transactions
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
        return (insight.title, insight.description, txns);
      case InsightKind.categoryShortcut:
        final cat = insight.categoryFilter;
        final txns = cat == null
            ? const <Transaction>[]
            : state.transactions
                .where((t) => (t.category ?? 'Other') == cat)
                .toList();
        return (insight.title, insight.description, txns);
    }
  }
}

