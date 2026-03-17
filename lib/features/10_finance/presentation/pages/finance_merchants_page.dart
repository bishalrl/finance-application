import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import '../widgets/category_icon.dart';

/// Merchant / payee view: total per merchant, tap → list of that merchant's transactions.
class FinanceMerchantsPage extends StatelessWidget {
  final bool showSenders;
  final bool embedded;

  const FinanceMerchantsPage({super.key, this.showSenders = false, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<FinanceBloc, FinanceState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            (showSenders ? p.bySender != c.bySender : p.byMerchant != c.byMerchant),
        builder: (context, state) {
          if (state.status == FinanceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final merchants = showSenders ? state.bySender : state.byMerchant;
          if (merchants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'No merchants yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  Text(
                    showSenders
                        ? 'Import from SMS to see sources'
                        : 'Import from SMS to see spending by merchant',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final top10 = merchants.take(10).toList();
          return ListView(
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            children: [
              // Insight text
              if (merchants.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                  margin: const EdgeInsets.only(
                    bottom: FinanceTheme.gapSection,
                  ),
                  decoration: BoxDecoration(
                    gradient: FinanceTheme.categoryGradient(
                      FinanceTheme.chartPalette[merchants.first.name.hashCode
                              .abs() %
                          FinanceTheme.chartPalette.length],
                      context,
                    ),
                    borderRadius: BorderRadius.circular(
                      FinanceTheme.radiusCard,
                    ),
                    boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Top ${showSenders ? 'Source' : 'Merchant'}: ${merchants.first.name} — $kCurrencySymbol ${merchants.first.total.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Horizontal bar chart
              if (top10.isNotEmpty) ...[
                Text(
                  'Top Merchants',
                  style: FinanceTheme.sectionTitle(context),
                ),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                _MerchantBarChart(merchants: top10),
                const SizedBox(height: FinanceTheme.gapSectionLarge),
              ],

              // Merchant list
              Text('All Merchants', style: FinanceTheme.sectionTitle(context)),
              const SizedBox(height: FinanceTheme.gapBetweenCards),
              ...merchants.map(
                (m) => _MerchantTile(
                  name: m.name,
                  total: m.total,
                  count: m.count,
                  onTap: () => _openMerchantTransactions(context, m),
                ),
              ),
            ],
          );
        },
      
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(showSenders ? 'By Source (Sender)' : 'By Merchant')),
      body: body,
    );
  }

  void _openMerchantTransactions(BuildContext context, MerchantSummary m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: _MerchantTransactionsPage(
            merchantName: m.name,
            transactions: m.transactions,
          ),
        ),
      ),
    );
  }
}

class _MerchantTile extends StatelessWidget {
  final String name;
  final double total;
  final int count;
  final VoidCallback onTap;

  const _MerchantTile({
    required this.name,
    required this.total,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use merchant name hash to get consistent color
    final colorIndex = name.hashCode.abs() % FinanceTheme.chartPalette.length;
    final merchantColor = FinanceTheme.chartPalette[colorIndex];

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
              border: Border(left: BorderSide(color: merchantColor, width: 4)),
              borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: FinanceTheme.categoryGradient(
                    merchantColor,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(
                    FinanceTheme.radiusIconBox,
                  ),
                  boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: merchantColor,
                ),
              ),
              subtitle: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: merchantColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count transactions',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: merchantColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: Text(
                '$kCurrencySymbol ${total.toStringAsFixed(0)}',
                style: FinanceTheme.amountTrailing(
                  context,
                  isCredit: false,
                ).copyWith(color: merchantColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Merchant Horizontal Bar Chart ──────────────────────────────────────────
class _MerchantBarChart extends StatelessWidget {
  final List<MerchantSummary> merchants;

  const _MerchantBarChart({required this.merchants});

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) return const SizedBox.shrink();

    final maxVal = merchants.first.total;

    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
      ),
      child: SizedBox(
        height: merchants.length * 36.0 + 16,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.15,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                  final m = merchants[groupIdx];
                  return BarTooltipItem(
                    '${m.name}: $kCurrencySymbol ${m.total.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= merchants.length)
                      return const SizedBox.shrink();
                    final name = merchants[idx].name;
                    return SizedBox(
                      width: 76,
                      child: Text(
                        name.length > 10 ? '${name.substring(0, 10)}...' : name,
                        style: FinanceTheme.chartAxisLabel(context),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: const AxisTitles(
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
            barGroups: merchants.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              final colorIdx =
                  m.name.hashCode.abs() % FinanceTheme.chartPalette.length;
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: m.total,
                    color: FinanceTheme.chartPalette[colorIdx],
                    width: 16,
                    borderRadius: BorderRadius.circular(FinanceTheme.radiusBar),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Simple list of transactions for one merchant (no bloc filter; we pass list).
class _MerchantTransactionsPage extends StatelessWidget {
  final String merchantName;
  final List<Transaction> transactions;

  const _MerchantTransactionsPage({
    required this.merchantName,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(merchantName)),
      body: ListView.builder(
        padding: const EdgeInsets.all(FinanceTheme.pagePadding),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final t = transactions[index];
          final isCredit = t.type == TransactionType.credit;
          final displayTitle = t.title ?? t.rawRemark ?? t.merchant ?? t.description;
          final categoryColor = FinanceTheme.getCategoryColor(t.category);
          final hasUserRemark = t.userRemark != null && t.userRemark!.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: FinanceTheme.gapBetweenCards,
            ),
            child: Material(
              color: FinanceTheme.cardBackground(context),
              borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: categoryColor, width: 4),
                  ),
                  borderRadius: BorderRadius.circular(
                    FinanceTheme.radiusListTile,
                  ),
                ),
                child: ListTile(
                  leading: CategoryIcon.build(category: t.category, size: 22),
                  title: Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User remark
                      if (hasUserRemark)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 11, color: categoryColor),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  t.userRemark!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Category + date row
                      Row(
                        children: [
                          if (t.category != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.category!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: categoryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${t.date.day}/${t.date.month}/${t.date.year}',
                              style: FinanceTheme.caption(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${isCredit ? '+' : '-'}$kCurrencySymbol ${t.amount.toStringAsFixed(0)}',
                    style: FinanceTheme.amountTrailing(
                      context,
                      isCredit: isCredit,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
