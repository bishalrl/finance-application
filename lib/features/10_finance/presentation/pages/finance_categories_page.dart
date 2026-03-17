import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import '../widgets/category_icon.dart';
import 'transactions_page.dart';

/// Category-first: list of categories with total spent and count; tap → filtered transaction list.
class FinanceCategoriesPage extends StatelessWidget {
  final bool embedded;
  const FinanceCategoriesPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<FinanceBloc, FinanceState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.transactions != c.transactions ||
            p.recurringCategoryLabels != c.recurringCategoryLabels,
        builder: (context, state) {
          if (state.status == FinanceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final byCategory = state.byCategory;
          if (byCategory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'No spending by category yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  Text(
                    'Import from SMS to see categories',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          final entries = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final totalSpent =
              entries.fold(0.0, (s, e) => s + e.value);
          final countByCat = <String, int>{};
          for (final t in state.filteredTransactions) {
            if (t.type == TransactionType.debit) {
              final cat = t.category ?? 'Other';
              countByCat[cat] = (countByCat[cat] ?? 0) + 1;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            children: [
              _SummaryCard(
                total: totalSpent,
                count: state.filteredTransactions
                    .where((t) => t.type == TransactionType.debit)
                    .length,
              ),
              const SizedBox(height: FinanceTheme.gapSection),
              if (entries.isNotEmpty) ...[
                Text(
                  'Category Distribution',
                  style: FinanceTheme.sectionTitle(context),
                ),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                  decoration: BoxDecoration(
                    color: FinanceTheme.cardBackgroundElevated(context),
                    borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
                    boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
                  ),
                  child: _CategoryPieChart(data: byCategory),
                ),
                const SizedBox(height: FinanceTheme.gapSection),
              ],
              Text(
                'Spending by category',
                style: FinanceTheme.sectionTitle(context),
              ),
              const SizedBox(height: FinanceTheme.gapBetweenCards),
              ...entries.map((e) {
                final count = countByCat[e.key] ?? 0;
                final isRecurring = state.recurringCategoryLabels.contains(e.key);
                final comp = state.monthlyComparison[e.key];
                return _CategoryTile(
                  category: e.key,
                  amount: e.value,
                  count: count,
                  totalSpent: totalSpent,
                  isRecurring: isRecurring,
                  comparison: comp,
                  onToggleRecurring: () {
                    context.read<FinanceBloc>().add(ToggleRecurringCategory(e.key));
                  },
                  onTap: () {
                    context
                        .read<FinanceBloc>()
                        .add(FilterByCategory(e.key));
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<FinanceBloc>(),
                          child: const TransactionsPage(),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('By Category')),
      body: body,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final int count;

  const _SummaryCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: FinanceTheme.debitGradient(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.gradientCardShadow(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total spent',
                style: FinanceTheme.labelCaps(
                    context, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                '$kCurrencySymbol ${total.toStringAsFixed(0)}',
                style: FinanceTheme.amountLarge(context).copyWith(color: Colors.white),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count transactions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final int count;
  final double totalSpent;
  final bool isRecurring;
  final CategoryComparison? comparison;
  final VoidCallback onToggleRecurring;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.amount,
    required this.count,
    required this.totalSpent,
    required this.isRecurring,
    this.comparison,
    required this.onToggleRecurring,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = FinanceTheme.getCategoryColor(category);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: FinanceTheme.gapBetweenCards),
      child: Material(
        color: FinanceTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: categoryColor,
                  width: 4,
                ),
              ),
              borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
            ),
            child: ListTile(
              leading: CategoryIcon.build(
                category: category,
                size: 24,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isRecurring ? Icons.repeat : Icons.repeat_outlined,
                      size: 20,
                      color: isRecurring
                          ? FinanceTheme.creditColor
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: onToggleRecurring,
                    tooltip: isRecurring
                        ? 'Unmark as recurring'
                        : 'Mark as recurring (e.g. Rent, Grocery)',
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count transactions',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Month-over-month comparison
                      if (comparison != null && comparison!.lastMonth > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (comparison!.changePercent > 0
                                    ? FinanceTheme.debitColor
                                    : FinanceTheme.creditColor)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                comparison!.changePercent > 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 10,
                                color: comparison!.changePercent > 0
                                    ? FinanceTheme.debitColor
                                    : FinanceTheme.creditColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${comparison!.changePercent.abs().toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: comparison!.changePercent > 0
                                      ? FinanceTheme.debitColor
                                      : FinanceTheme.creditColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Progress bar showing percentage
                  if (totalSpent > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: amount / totalSpent,
                        minHeight: 6,
                        backgroundColor: categoryColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                      ),
                    ),
                  // Last month comparison text
                  if (comparison != null && comparison!.lastMonth > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Last month: $kCurrencySymbol ${comparison!.lastMonth.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Text(
                '$kCurrencySymbol ${amount.toStringAsFixed(0)}',
                style: FinanceTheme.amountTrailing(context, isCredit: false)
                    .copyWith(color: categoryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;

  const _CategoryPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final total = entries.fold(0.0, (s, e) => s + e.value);

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 60,
        sections: entries.asMap().entries.map((entry) {
          final e = entry.value;
          final categoryColor = FinanceTheme.getCategoryColor(e.key);
          final percentage = (e.value / total * 100);
          
          return PieChartSectionData(
            color: categoryColor,
            value: e.value,
            title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: percentage > 5
                ? null
                : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryIcon.getIcon(e.key),
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
            badgePositionPercentageOffset: 1.3,
          );
        }).toList(),
      ),
    );
  }
}
