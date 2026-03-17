import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';

class FinanceFlowDetailPage extends StatefulWidget {
  final TransactionType type;
  final FinanceFlowPeriodUi initialPeriod;

  const FinanceFlowDetailPage({
    super.key,
    required this.type,
    this.initialPeriod = FinanceFlowPeriodUi.thisMonth,
  });

  @override
  State<FinanceFlowDetailPage> createState() => _FinanceFlowDetailPageState();
}

class _FinanceFlowDetailPageState extends State<FinanceFlowDetailPage> {
  late final FinanceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<FinanceBloc>();
    _bloc.add(SetFlowDetailPeriod(widget.initialPeriod));
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  @override
  void dispose() {
    // Restore to unfiltered state for the shared FinanceBloc.
    _bloc.add(const FilterByType(null));
    _bloc.add(const SetDateRangeFilter(from: null, to: null));
    super.dispose();
  }

  void _applyFilters() {
    _bloc.add(FilterByType(widget.type));
    final range = _dateRangeFor(_bloc.state.flowDetailPeriod);
    _bloc.add(SetDateRangeFilter(from: range?.$1, to: range?.$2));
  }

  (DateTime, DateTime)? _dateRangeFor(FinanceFlowPeriodUi p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (p) {
      case FinanceFlowPeriodUi.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return (weekStart, DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59));
      case FinanceFlowPeriodUi.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);
      case FinanceFlowPeriodUi.allTime:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == TransactionType.credit ? 'Received' : 'Spent';
    final color =
        widget.type == TransactionType.credit ? FinanceTheme.creditColor : FinanceTheme.debitColor;

    return Scaffold(
      appBar: AppBar(title: Text('$title details')),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.filteredTransactions != c.filteredTransactions ||
            p.filterType != c.filterType ||
            p.filterDateFrom != c.filterDateFrom ||
            p.filterDateTo != c.filterDateTo,
        builder: (context, state) {
          if (state.status == FinanceStatus.loading && state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final txns = state.filteredTransactions;
          final total = txns.fold(0.0, (s, t) => s + t.amount);
          final range = _dateRangeFor(state.flowDetailPeriod);
          final rangeLabel = switch (state.flowDetailPeriod) {
            FinanceFlowPeriodUi.thisWeek => 'This week',
            FinanceFlowPeriodUi.thisMonth => 'This month',
            FinanceFlowPeriodUi.allTime => 'All time',
          };

          return ListView(
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rangeLabel,
                      style: FinanceTheme.sectionTitle(context),
                    ),
                  ),
                  SegmentedButton<FinanceFlowPeriodUi>(
                    segments: const [
                      ButtonSegment(
                        value: FinanceFlowPeriodUi.thisWeek,
                        label: Text('Week'),
                      ),
                      ButtonSegment(
                        value: FinanceFlowPeriodUi.thisMonth,
                        label: Text('Month'),
                      ),
                      ButtonSegment(
                        value: FinanceFlowPeriodUi.allTime,
                        label: Text('All'),
                      ),
                    ],
                    selected: {state.flowDetailPeriod},
                    onSelectionChanged: (s) {
                      context
                          .read<FinanceBloc>()
                          .add(SetFlowDetailPeriod(s.first));
                      _applyFilters();
                    },
                  ),
                ],
              ),
              const SizedBox(height: FinanceTheme.gapSection),
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
                      'Total',
                      style: FinanceTheme.labelCaps(context, color: color.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$kCurrencySymbol ${total.toStringAsFixed(0)}',
                      style: FinanceTheme.amountLarge(context).copyWith(color: color),
                    ),
                    if (range != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${DateFormat.yMMMd().format(range.$1)} → ${DateFormat.yMMMd().format(range.$2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '${txns.length} transactions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FinanceTheme.gapSection),
              if (txns.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No transactions in this period.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                ...txns.map((t) {
                  final isCredit = t.type == TransactionType.credit;
                  final title = t.title ?? t.merchant ?? t.rawRemark ?? t.description;
                  final subtitle = [
                    DateFormat.yMMMd().format(t.date),
                    (t.category ?? 'Other'),
                    (t.sender ?? t.bankName ?? t.sourceKey ?? 'SMS'),
                  ].join(' • ');

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: (isCredit ? FinanceTheme.creditColor : FinanceTheme.debitColor)
                          .withOpacity(0.12),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isCredit ? FinanceTheme.creditColor : FinanceTheme.debitColor,
                      ),
                    ),
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
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
}

