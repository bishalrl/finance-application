import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/time_period.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import 'package:intl/intl.dart';

/// Monthly summary: total spent, total received, category-wise breakdown. Calm, no panic language.
class FinanceSummaryPage extends StatefulWidget {
  const FinanceSummaryPage({super.key});

  @override
  State<FinanceSummaryPage> createState() => _FinanceSummaryPageState();
}

class _FinanceSummaryPageState extends State<FinanceSummaryPage> {
  late TimePeriod _period;
  late DateTime _focusedDate;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _period = TimePeriod.monthly;
    _focusedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(-1),
          ),
          Center(
            child: Text(
              _getDateLabel(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateDate(1),
          ),
        ],
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
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
                  LoadSummary(_period, _focusedDate),
                );
            });
          }
          final summary = state.summaryData;
          final isMatchingPeriod =
              state.summaryPeriod == _period &&
              _isSamePeriod(state.summaryDate, _focusedDate, _period);

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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Received',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: const Color(0xFF10B981)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalCredit.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spent',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: const Color(0xFF6366F1)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalDebit.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (totalDebit > 0) ...[
                  Text(
                    'Trends & Distribution',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildCharts(graphData, byCategory),
                  const SizedBox(height: 24),
                ],
                Text(
                  'By Category',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No spending in this period',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...entries.map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(e.key),
                        trailing: Text(
                          '₹${(e.value as num).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<TimePeriod>(
      segments: const [
        ButtonSegment(value: TimePeriod.daily, label: Text('Day')),
        ButtonSegment(value: TimePeriod.weekly, label: Text('Week')),
        ButtonSegment(value: TimePeriod.monthly, label: Text('Month')),
        ButtonSegment(value: TimePeriod.yearly, label: Text('Year')),
      ],
      selected: {_period},
      onSelectionChanged: (Set<TimePeriod> newSelection) {
        setState(() {
          _period = newSelection.first;
        });
        context.read<FinanceBloc>().add(LoadSummary(_period, _focusedDate));
      },
    );
  }

  Widget _buildCharts(
    Map<int, dynamic> graphData,
    Map<String, dynamic> byCategory,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: _BarChartWidget(data: graphData, period: _period),
        ),
        const SizedBox(height: 32),
        SizedBox(height: 200, child: _PieChartWidget(data: byCategory)),
      ],
    );
  }

  String _getDateLabel() {
    switch (_period) {
      case TimePeriod.daily:
        return DateFormat('MMM d, y').format(_focusedDate);
      case TimePeriod.weekly:
        final start = _focusedDate.subtract(
          Duration(days: _focusedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
      case TimePeriod.monthly:
        return DateFormat('MMM y').format(_focusedDate);
      case TimePeriod.yearly:
        return DateFormat('y').format(_focusedDate);
    }
  }

  void _navigateDate(int delta) {
    setState(() {
      switch (_period) {
        case TimePeriod.daily:
          _focusedDate = _focusedDate.add(Duration(days: delta));
          break;
        case TimePeriod.weekly:
          _focusedDate = _focusedDate.add(Duration(days: delta * 7));
          break;
        case TimePeriod.monthly:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month + delta,
          );
          break;
        case TimePeriod.yearly:
          _focusedDate = DateTime(_focusedDate.year + delta);
          break;
      }
    });
    context.read<FinanceBloc>().add(LoadSummary(_period, _focusedDate));
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
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
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
          return BarChartGroupData(
            x: key,
            barRods: [
              BarChartRodData(
                toY: (data[key] as num).toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
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
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];

    int colorIdx = 0;
    final entries = data.entries.toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: entries.map((e) {
          final color = colors[colorIdx % colors.length];
          colorIdx++;
          return PieChartSectionData(
            color: color,
            value: (e.value as num).toDouble(),
            title: e.key,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}
