import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/time_period.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';

/// Monthly summary: total spent, total received, category-wise breakdown. Calm, no panic language.
class FinanceSummaryPage extends StatefulWidget {
  final bool embedded;
  const FinanceSummaryPage({super.key, this.embedded = false});

  @override
  State<FinanceSummaryPage> createState() => _FinanceSummaryPageState();
}

class _FinanceSummaryPageState extends State<FinanceSummaryPage> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final period = context.select<FinanceBloc, TimePeriod>(
      (b) => b.state.summaryUiPeriod,
    );
    final focusedDate = context.select<FinanceBloc, DateTime>(
      (b) => b.state.summaryUiFocusedDate,
    );

    final dateNavBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(context, period, focusedDate, -1),
          ),
          Text(
            _getDateLabel(period, focusedDate),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateDate(context, period, focusedDate, 1),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () => _shareSummary(context),
          ),
        ],
      ),
    );

    final body = Column(
      children: [
        dateNavBar,
        Expanded(
          child: BlocConsumer<FinanceBloc, FinanceState>(
        listenWhen: (p, c) =>
            p.errorMessage != c.errorMessage && c.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (!_initialLoadDone && state.status != FinanceStatus.loading) {
            _initialLoadDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                context.read<FinanceBloc>().add(
                  LoadSummary(period, focusedDate),
                );
            });
          }
          final summary = state.summaryData;
          final isMatchingPeriod =
              state.summaryPeriod == period &&
              _isSamePeriod(state.summaryDate, focusedDate, period);

          if (summary == null ||
              !isMatchingPeriod ||
              state.status == FinanceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final totalCredit =
              (summary['totalCredit'] as num?)?.toDouble() ?? 0.0;
          final totalDebit = (summary['totalDebit'] as num?)?.toDouble() ?? 0.0;
          final byCategory =
              summary['byCategory'] as Map<String, dynamic>? ?? {};
          final graphData = summary['graphData'] as Map<int, dynamic>? ?? {};
          final entries = byCategory.entries.toList()
            ..sort((a, b) => (b.value as num).compareTo(a.value as num));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPeriodSelector(period, focusedDate),
                const SizedBox(height: FinanceTheme.gapSection),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Received',
                        amount: totalCredit,
                        isCredit: true,
                      ),
                    ),
                    const SizedBox(width: FinanceTheme.gapBetweenCards),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Spent',
                        amount: totalDebit,
                        isCredit: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FinanceTheme.gapSectionLarge),
                if (totalDebit > 0) ...[
                  Text(
                    'Trends & Distribution',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  _buildCharts(graphData, byCategory),
                  const SizedBox(height: FinanceTheme.gapSectionLarge),
                ],
                Text(
                  'By Category',
                  style: FinanceTheme.sectionTitle(context),
                ),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(FinanceTheme.gapSectionLarge),
                    child: Text(
                      'No spending in this period',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...entries.map(
                    (e) {
                      final catColor = FinanceTheme.getCategoryColor(e.key);
                      // Get comparison data for trend arrow
                      final comp = state.monthlyComparison[e.key];
                      final changePct = comp?.changePercent ?? 0;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: FinanceTheme.gapBetweenCards),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FinanceTheme.listItemPaddingH,
                            vertical: FinanceTheme.listItemPaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
                            border: Border.all(
                              color: catColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: FinanceTheme.categoryGradient(catColor, context),
                                  borderRadius: BorderRadius.circular(FinanceTheme.radiusIconBox),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: FinanceTheme.gapBetweenCards),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.key,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: catColor,
                                      ),
                                    ),
                                    // Trend arrow
                                    if (comp != null && comp.lastMonth > 0)
                                      Row(
                                        children: [
                                          Icon(
                                            changePct > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                            size: 12,
                                            color: changePct > 0 ? FinanceTheme.debitColor : FinanceTheme.creditColor,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${changePct.abs().toStringAsFixed(0)}% vs last',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: changePct > 0 ? FinanceTheme.debitColor : FinanceTheme.creditColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '$kCurrencySymbol ${(e.value as num).toStringAsFixed(0)}',
                                style: FinanceTheme.amountTrailing(context, isCredit: false)
                                    .copyWith(color: catColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Summary & Insights')),
      body: body,
    );
  }

  Widget _buildPeriodSelector(TimePeriod period, DateTime focusedDate) {
    return SegmentedButton<TimePeriod>(
      segments: const [
        ButtonSegment(value: TimePeriod.daily, label: Text('Day')),
        ButtonSegment(value: TimePeriod.weekly, label: Text('Week')),
        ButtonSegment(value: TimePeriod.monthly, label: Text('Month')),
        ButtonSegment(value: TimePeriod.yearly, label: Text('Year')),
      ],
      selected: {period},
      onSelectionChanged: (Set<TimePeriod> newSelection) {
        final next = newSelection.first;
        context.read<FinanceBloc>().add(SetSummaryUiPeriod(next));
        context.read<FinanceBloc>().add(LoadSummary(next, focusedDate));
      },
    );
  }

  Widget _buildCharts(
    Map<int, dynamic> graphData,
    Map<String, dynamic> byCategory,
  ) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      buildWhen: (p, c) => p.transactions != c.transactions,
      builder: (context, state) {
        return Column(
          children: [
            // Stacked Bar: Income vs Expense
            Text(
              'Income vs Expense',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: FinanceTheme.gapBetweenCards),
            SizedBox(
              height: 220,
              child: _StackedBarChart(data: state.monthlyCreditDebitByMonth),
            ),
            const SizedBox(height: FinanceTheme.gapSectionLarge),

            // Cumulative Savings Line
            Text(
              'Cumulative Savings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: FinanceTheme.gapBetweenCards),
            SizedBox(
              height: 200,
              child: _SavingsLineChart(data: state.balanceTrendMonthly),
            ),
            const SizedBox(height: FinanceTheme.gapSectionLarge),

            // Heatmap Calendar
            Text(
              'Spending Intensity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: FinanceTheme.gapBetweenCards),
            _SpendingHeatmapCalendar(
              intensityMap: state.dailySpendingIntensity,
              month: state.summaryUiFocusedDate,
            ),
            const SizedBox(height: FinanceTheme.gapSectionLarge),

            // Category Distribution Pie
            SizedBox(height: 200, child: _PieChartWidget(data: byCategory)),
          ],
        );
      },
    );
  }

  String _getDateLabel(TimePeriod period, DateTime focusedDate) {
    switch (period) {
      case TimePeriod.daily:
        return DateFormat('MMM d, y').format(focusedDate);
      case TimePeriod.weekly:
        final start = focusedDate.subtract(
          Duration(days: focusedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
      case TimePeriod.monthly:
        return DateFormat('MMM y').format(focusedDate);
      case TimePeriod.yearly:
        return DateFormat('y').format(focusedDate);
    }
  }

  void _navigateDate(
    BuildContext context,
    TimePeriod period,
    DateTime focusedDate,
    int delta,
  ) {
    final next = switch (period) {
      TimePeriod.daily => focusedDate.add(Duration(days: delta)),
      TimePeriod.weekly => focusedDate.add(Duration(days: delta * 7)),
      TimePeriod.monthly => DateTime(focusedDate.year, focusedDate.month + delta),
      TimePeriod.yearly => DateTime(focusedDate.year + delta),
    };
    context.read<FinanceBloc>().add(SetSummaryUiFocusedDate(next));
    context.read<FinanceBloc>().add(LoadSummary(period, next));
  }

  Widget _SummaryCard({
    required String label,
    required double amount,
    required bool isCredit,
  }) {
    final gradient = isCredit
        ? FinanceTheme.creditGradient(context)
        : FinanceTheme.debitGradient(context);
    final color = isCredit ? FinanceTheme.creditColor : FinanceTheme.debitColor;
    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.gradientCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FinanceTheme.labelCaps(context, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            '$kCurrencySymbol ${amount.toStringAsFixed(0)}',
            style: FinanceTheme.amountLarge(context).copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSummary(BuildContext context) async {
    final state = context.read<FinanceBloc>().state;
    final summary = state.summaryData;
    if (summary == null) return;
    final totalCredit = (summary['totalCredit'] as num?)?.toDouble() ?? 0.0;
    final totalDebit = (summary['totalDebit'] as num?)?.toDouble() ?? 0.0;
    final byCategory = summary['byCategory'] as Map<String, dynamic>? ?? {};
    final periodLabel = _getDateLabel(state.summaryUiPeriod, state.summaryUiFocusedDate);
    final buf = StringBuffer();
    buf.writeln('Finance summary – $periodLabel');
    buf.writeln('');
    buf.writeln('Received: $kCurrencySymbol ${totalCredit.toStringAsFixed(0)}');
    buf.writeln('Spent: $kCurrencySymbol ${totalDebit.toStringAsFixed(0)}');
    buf.writeln('Net: $kCurrencySymbol ${(totalCredit - totalDebit).toStringAsFixed(0)}');
    buf.writeln('');
    buf.writeln('By category:');
    final entries = byCategory.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    for (final e in entries.take(15)) {
      buf.writeln('  ${e.key}: $kCurrencySymbol ${(e.value as num).toStringAsFixed(0)}');
    }
    await Share.share(buf.toString(), subject: 'Finance summary – $periodLabel');
  }

  bool _isSamePeriod(DateTime d1, DateTime d2, TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
      case TimePeriod.weekly:
        final s1 = d1.subtract(Duration(days: d1.weekday - 1));
        final s2 = d2.subtract(Duration(days: d2.weekday - 1));
        return s1.year == s2.year && s1.month == s2.month && s1.day == s2.day;
      case TimePeriod.monthly:
        return d1.year == d2.year && d1.month == d2.month;
      case TimePeriod.yearly:
        return d1.year == d2.year;
    }
  }
}

// ─── Stacked Bar Chart: Income vs Expense per month ─────────────────────────
class _StackedBarChart extends StatelessWidget {
  final Map<String, CreditDebitPair> data;

  const _StackedBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    if (entries.isEmpty) return const Center(child: Text('No data'));

    double maxY = 0;
    for (final e in entries) {
      final sum = e.value.credit + e.value.debit;
      if (sum > maxY) maxY = sum;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final e = entries[groupIdx];
              return BarTooltipItem(
                '${e.key}\nIn: ${e.value.credit.toStringAsFixed(0)}\nOut: ${e.value.debit.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                // Show only every other label if > 6
                if (entries.length > 6 && idx % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    entries[idx].key.split(' ').first, // "Jan"
                    style: FinanceTheme.chartAxisLabel(context),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: e.value.credit + e.value.debit,
                width: entries.length > 8 ? 12 : 18,
                borderRadius: BorderRadius.circular(FinanceTheme.radiusBar),
                rodStackItems: [
                  BarChartRodStackItem(0, e.value.debit, FinanceTheme.debitColor),
                  BarChartRodStackItem(e.value.debit, e.value.debit + e.value.credit, FinanceTheme.creditColor),
                ],
                color: Colors.transparent,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Cumulative Savings Line Chart ──────────────────────────────────────────
class _SavingsLineChart extends StatelessWidget {
  final List<MonthlyBalance> data;

  const _SavingsLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].cumulativeBalance));
    }

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padY = (maxY - minY) > 0 ? (maxY - minY) * 0.1 : 100;

    const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];

    return LineChart(
      LineChartData(
        minY: minY - padY,
        maxY: maxY + padY,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: data.length > 6 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    months[data[idx].month.month - 1],
                    style: FinanceTheme.chartAxisLabel(context),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: FinanceTheme.creditColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FinanceTheme.creditColor.withOpacity(0.3),
                  FinanceTheme.creditColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spending Heatmap Calendar ──────────────────────────────────────────────
class _SpendingHeatmapCalendar extends StatelessWidget {
  final Map<DateTime, double> intensityMap;
  final DateTime month;

  const _SpendingHeatmapCalendar({
    required this.intensityMap,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = last.day;
    final weekdayStart = first.weekday;
    final leadingEmpty = weekdayStart - 1;
    final rows = ((leadingEmpty + daysInMonth) / 7).ceil();

    // Find max spending for intensity normalization
    double maxSpend = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final val = intensityMap[day] ?? 0;
      if (val > maxSpend) maxSpend = val;
    }

    const weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekLabels.map((l) => SizedBox(
              width: 32,
              child: Text(l, style: FinanceTheme.chartAxisLabel(context), textAlign: TextAlign.center),
            )).toList(),
          ),
          const SizedBox(height: 6),
          ...List.generate(rows, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  if (cellIndex < leadingEmpty || (cellIndex - leadingEmpty + 1) > daysInMonth) {
                    return const SizedBox(width: 32, height: 32);
                  }
                  final dayNum = cellIndex - leadingEmpty + 1;
                  final day = DateTime(month.year, month.month, dayNum);
                  final spend = intensityMap[day] ?? 0;
                  final intensity = maxSpend > 0 ? (spend / maxSpend).clamp(0.0, 1.0) : 0.0;

                  return Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: spend > 0
                          ? FinanceTheme.heatmapColor(intensity)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$dayNum',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: spend > 0 ? FontWeight.bold : FontWeight.normal,
                        color: intensity > 0.6 ? Colors.white : null,
                        fontSize: 10,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          // Legend
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Less', style: FinanceTheme.chartAxisLabel(context)),
              const SizedBox(width: 4),
              ...FinanceTheme.heatmapScale.map((c) => Container(
                width: 14, height: 14, margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
              )),
              const SizedBox(width: 4),
              Text('More', style: FinanceTheme.chartAxisLabel(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final Map<int, dynamic> data;
  final TimePeriod period;

  const _BarChartWidget({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    if (sortedKeys.isEmpty)
      return const Center(child: Text('No data for trend'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            data.values.fold(0.0, (m, v) => (v as num) > m ? v.toDouble() : m) *
            1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (period == TimePeriod.yearly) {
                  return Text(
                    DateFormat('MMM').format(DateTime(2024, value.toInt())),
                    style: FinanceTheme.chartAxisLabel(context),
                  );
                }
                return Text(
                  value.toInt().toString(),
                  style: FinanceTheme.chartAxisLabel(context),
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
        barGroups: sortedKeys.map((key) {
          final colorIndex = key % FinanceTheme.chartPalette.length;
          return BarChartGroupData(
            x: key,
            barRods: [
              BarChartRodData(
                toY: (data[key] as num).toDouble(),
                color: FinanceTheme.chartPalette[colorIndex],
                width: 20,
                borderRadius: BorderRadius.circular(FinanceTheme.radiusBar),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    FinanceTheme.chartPalette[colorIndex],
                    FinanceTheme.chartPalette[colorIndex].withOpacity(0.7),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PieChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    if (entries.isEmpty) return const Center(child: Text('No data'));

    final total = entries.fold(0.0, (s, e) => s + (e.value as num).toDouble());
    if (total <= 0) return const Center(child: Text('No data'));

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 50,
        sections: entries.asMap().entries.map((entry) {
          final e = entry.value;
          final categoryColor = FinanceTheme.getCategoryColor(e.key);
          final val = (e.value as num).toDouble();
          final pct = (val / total * 100);
          return PieChartSectionData(
            color: categoryColor,
            value: val,
            title: pct > 8 ? '${pct.toStringAsFixed(0)}%' : '',
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: pct <= 8
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      e.key.isNotEmpty ? e.key[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.3,
          );
        }).toList(),
      ),
    );
  }
}
