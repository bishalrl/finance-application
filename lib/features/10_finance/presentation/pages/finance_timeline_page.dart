import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import '../widgets/category_icon.dart';

import 'package:fl_chart/fl_chart.dart';

/// Timeline / activity feed: transactions grouped by "Today", "Yesterday", "This week", "December 2025".
class FinanceTimelinePage extends StatelessWidget {
  final bool embedded;
  const FinanceTimelinePage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<FinanceBloc, FinanceState>(
        // ... rest of builder
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.filteredTransactions != c.filteredTransactions ||
            p.transactionsGroupedByDate != c.transactionsGroupedByDate,
        builder: (context, state) {
          if (state.status == FinanceStatus.loading &&
              state.transactionsGroupedByDate.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = state.transactionsGroupedByDate;
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  Text(
                    'Import from SMS or add transactions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: FinanceTheme.listItemPaddingV,
              horizontal: FinanceTheme.pagePadding,
            ),
            itemCount: groups.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header Chart
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: FinanceTheme.gapSectionLarge,
                  ),
                  child: _DailyBarChart(
                    dailyData: state.dailySpendingIntensity,
                  ),
                );
              }
              final group = groups[index - 1];
              // Calculate group income/expense for the separator card
              double groupCredit = 0, groupDebit = 0;
              for (final t in group.transactions) {
                if (t.type == TransactionType.credit) {
                  groupCredit += t.amount;
                } else {
                  groupDebit += t.amount;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: FinanceTheme.gapBetweenCards,
                      top: index == 0 ? 0 : FinanceTheme.gapSection,
                    ),
                    child: Text(
                      group.label,
                      style: FinanceTheme.sectionTitle(context),
                    ),
                  ),
                  // Monthly summary separator card
                  if (group.transactions.length > 1)
                    _MonthSummaryCard(
                      credit: groupCredit,
                      debit: groupDebit,
                      count: group.transactions.length,
                    ),
                  ...group.transactions.map(
                    (t) => _ActivityTile(transaction: t),
                  ),
                ],
              );
            },
          );
        },
      
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: body,
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Transaction transaction;

  const _ActivityTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final displayTitle = transaction.title ??
        transaction.rawRemark ??
        transaction.merchant ??
        transaction.description;
    final categoryColor = FinanceTheme.getCategoryColor(transaction.category);
    final timeStr = DateFormat('HH:mm').format(transaction.date);
    final hasUserRemark = transaction.userRemark != null && transaction.userRemark!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: FinanceTheme.gapBetweenCards),
      child: Material(
        color: FinanceTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: categoryColor, width: 4)),
            borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FinanceTheme.listItemPaddingH,
            vertical: FinanceTheme.listItemPaddingV,
          ),
          child: Row(
            children: [
              CategoryIcon.build(category: transaction.category, size: 22),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Bank name label
                    if (transaction.bankName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          transaction.bankName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    // User remark
                    if (hasUserRemark)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 12, color: categoryColor),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                transaction.userRemark!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(timeStr, style: FinanceTheme.caption(context)),
                        if (transaction.category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.category!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : '-'}$kCurrencySymbol ${transaction.amount.toStringAsFixed(0)}',
                style: FinanceTheme.amountTrailing(context, isCredit: isCredit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Monthly Summary Separator Card ─────────────────────────────────────────
class _MonthSummaryCard extends StatelessWidget {
  final double credit;
  final double debit;
  final int count;

  const _MonthSummaryCard({
    required this.credit,
    required this.debit,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final total = credit + debit;
    final creditPct = total > 0 ? credit / total : 0.0;
    final debitPct = total > 0 ? debit / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: FinanceTheme.gapBetweenCards),
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: FinanceTheme.creditColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$kCurrencySymbol ${credit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: FinanceTheme.creditColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '$count txns',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 14,
                    color: FinanceTheme.debitColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$kCurrencySymbol ${debit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: FinanceTheme.debitColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini income/expense bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (creditPct > 0)
                  Flexible(
                    flex: (creditPct * 100).round().clamp(1, 100),
                    child: Container(
                      height: 6,
                      color: FinanceTheme.creditColor,
                    ),
                  ),
                if (debitPct > 0)
                  Flexible(
                    flex: (debitPct * 100).round().clamp(1, 100),
                    child: Container(height: 6, color: FinanceTheme.debitColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final Map<DateTime, double> dailyData;

  const _DailyBarChart({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) return const SizedBox.shrink();

    // Get last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    double maxVal = 0;
    for (final d in days) {
      final val = dailyData[DateTime(d.year, d.month, d.day)] ?? 0.0;
      if (val > maxVal) maxVal = val;
    }

    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      margin: const EdgeInsets.symmetric(horizontal: FinanceTheme.pagePadding),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 Days Spending',
                style: FinanceTheme.sectionTitle(context),
              ),
              Icon(Icons.bar_chart_rounded, color: FinanceTheme.debitColor),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal == 0 ? 100 : maxVal * 1.1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIdx, rod, rodIdx) {
                      final day = days[groupIdx];
                      final val =
                          dailyData[DateTime(day.year, day.month, day.day)] ??
                          0.0;
                      return BarTooltipItem(
                        '${DateFormat('MMM d').format(day)}\n$kCurrencySymbol ${val.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= 7) return const SizedBox.shrink();
                        final d = days[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(d)[0],
                            style: FinanceTheme.caption(context),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: days.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final d = entry.value;
                  final val =
                      dailyData[DateTime(d.year, d.month, d.day)] ?? 0.0;
                  final isToday = d.day == now.day && d.month == now.month;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: isToday
                            ? FinanceTheme.debitColor
                            : FinanceTheme.debitColor.withOpacity(0.5),
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal == 0 ? 100 : maxVal * 1.1,
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
