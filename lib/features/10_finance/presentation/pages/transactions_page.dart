import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import '../widgets/category_icon.dart';
import 'add_transaction_page.dart';

/// Transaction list: chronological. Search, filter by credit/debit, category, date range. Categories editable.
class TransactionsPage extends StatelessWidget {
  final bool embedded;
  const TransactionsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final isTableView = context.select<FinanceBloc, bool>(
      (b) => b.state.transactionsIsTableView,
    );
    final body = Column(
        children: [
          _SearchBar(),
          _FilterChips(),
          _ViewToggle(
            isTableView: isTableView,
            onToggle: (value) => context
                .read<FinanceBloc>()
                .add(SetTransactionsTableView(value)),
          ),
          Expanded(
            child: BlocBuilder<FinanceBloc, FinanceState>(
              buildWhen: (p, c) =>
                  p.status != c.status ||
                  p.filteredTransactions != c.filteredTransactions ||
                  p.transactionsIsTableView != c.transactionsIsTableView ||
                  p.transactionsGroupByColumn != c.transactionsGroupByColumn,
              builder: (context, state) {
                if (state.status == FinanceStatus.loading &&
                    state.filteredTransactions.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final txns = state.filteredTransactions;
                if (txns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: FinanceTheme.gapSection),
                        Text(
                          'No transactions yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: FinanceTheme.gapBetweenCards),
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
                if (isTableView) {
                  return Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: SingleChildScrollView(
                          child: _TableChartsSection(state: state),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _TransactionTable(
                          transactions: txns,
                          enabled: state.status != FinanceStatus.loading,
                          onTapCategory: (t) => _showCategoryPicker(context, t),
                          onEditRemark: (t) => _editRemarkForTransaction(context, t),
                          onDelete: (t) => _confirmDeleteTransaction(context, t),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FinanceTheme.pagePadding,
                    vertical: FinanceTheme.listItemPaddingV,
                  ),
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final t = txns[index];
                    return _TransactionTile(
                      transaction: t,
                      onTapCategory: () => _showCategoryPicker(context, t),
                      onEditRemark: () => _editRemarkForTransaction(context, t),
                    );
                  },
                );
              },
            ),
          ),
        ],
    );

    void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const AddTransactionPage(),
        ),
      ),
    );
  }

    if (embedded) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddTransaction(context),
          child: const Icon(Icons.add),
          tooltip: 'Add transaction',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransaction(context),
        child: const Icon(Icons.add),
        tooltip: 'Add transaction',
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, Transaction t) {
    const categories = kFinanceCategories;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Prevent RenderFlex overflow on small screens.
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                child: Text(
                  'Category',
                  style: FinanceTheme.sectionTitle(ctx),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ...categories.map(
                      (cat) => ListTile(
                        title: Text(cat),
                        onTap: () {
                          context.read<FinanceBloc>().add(
                            UpdateTransactionCategory(t.id, cat),
                          );
                          Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Category updated'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editRemarkForTransaction(BuildContext context, Transaction t) {
    final controller = TextEditingController(text: t.userRemark ?? '');
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FinanceBloc>().add(
                UpdateTransactionRemark(t.id, controller.text.trim()),
              );
              Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remark updated'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, Transaction t) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<FinanceBloc>().add(DeleteTransaction(t.id));
      }
    });
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      buildWhen: (p, c) => p.searchQuery != c.searchQuery,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FinanceTheme.listItemPaddingH,
            vertical: FinanceTheme.gapBetweenCards,
          ),
          child: TextField(
            onChanged: (v) =>
                context.read<FinanceBloc>().add(SetSearchQuery(v.isEmpty ? null : v)),
            decoration: InputDecoration(
              hintText: 'Search by remark, merchant, category, amount',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FinanceTheme.radiusButton),
              ),
              isDense: true,
            ),
          ),
        );
      },
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      buildWhen: (p, c) =>
          p.filterType != c.filterType ||
          p.filterCategory != c.filterCategory ||
          p.filterDateFrom != c.filterDateFrom ||
          p.filterDateTo != c.filterDateTo,
      builder: (context, state) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);

        bool sameDay(DateTime? a, DateTime b) =>
            a != null && a.year == b.year && a.month == b.month && a.day == b.day;

        final selectedAllTime = state.filterDateFrom == null && state.filterDateTo == null;
        final selectedThisWeek =
            sameDay(state.filterDateFrom, weekStart) && sameDay(state.filterDateTo, weekEnd);
        final selectedThisMonth =
            sameDay(state.filterDateFrom, thisMonthStart) && sameDay(state.filterDateTo, thisMonthEnd);
        final selectedLastMonth =
            sameDay(state.filterDateFrom, lastMonthStart) && sameDay(state.filterDateTo, lastMonthEnd);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: FinanceTheme.listItemPaddingH,
            vertical: FinanceTheme.listItemPaddingV,
          ),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.filterType == null,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                onSelected: (_) =>
                    context.read<FinanceBloc>().add(const FilterByType(null)),
              ),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              FilterChip(
                label: const Text('Credit'),
                selected: state.filterType == TransactionType.credit,
                selectedColor: FinanceTheme.creditColor.withOpacity(0.2),
                checkmarkColor: FinanceTheme.creditColor,
                onSelected: (_) => context.read<FinanceBloc>().add(
                  const FilterByType(TransactionType.credit),
                ),
              ),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              FilterChip(
                label: const Text('Debit'),
                selected: state.filterType == TransactionType.debit,
                selectedColor: FinanceTheme.debitColor.withOpacity(0.2),
                checkmarkColor: FinanceTheme.debitColor,
                onSelected: (_) => context.read<FinanceBloc>().add(
                  const FilterByType(TransactionType.debit),
                ),
              ),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              FilterChip(
                label: const Text('Week'),
                selected: selectedThisWeek,
                onSelected: (_) {
                  context.read<FinanceBloc>().add(
                        SetDateRangeFilter(
                          from: weekStart,
                          to: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
                        ),
                      );
                },
              ),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              FilterChip(
                label: const Text('Month'),
                selected: selectedThisMonth,
                onSelected: (_) {
                  context.read<FinanceBloc>().add(
                        SetDateRangeFilter(
                          from: thisMonthStart,
                          to: DateTime(thisMonthEnd.year, thisMonthEnd.month, thisMonthEnd.day, 23, 59, 59),
                        ),
                      );
                },
              ),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              FilterChip(
                label: const Text('Last month'),
                selected: selectedLastMonth,
                onSelected: (_) {
                  context.read<FinanceBloc>().add(
                        SetDateRangeFilter(
                          from: lastMonthStart,
                          to: DateTime(lastMonthEnd.year, lastMonthEnd.month, lastMonthEnd.day, 23, 59, 59),
                        ),
                      );
                },
              ),
              const SizedBox(width: FinanceTheme.gapBetweenCards),
              FilterChip(
                label: const Text('All time'),
                selected: selectedAllTime,
                onSelected: (_) {
                  context.read<FinanceBloc>().add(
                        const SetDateRangeFilter(from: null, to: null),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isTableView;
  final ValueChanged<bool> onToggle;

  const _ViewToggle({
    required this.isTableView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FinanceTheme.listItemPaddingH,
        vertical: FinanceTheme.gapBetweenCards / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              Icons.view_list,
              color: !isTableView
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => onToggle(false),
            tooltip: 'Card View',
          ),
          IconButton(
            icon: Icon(
              Icons.table_chart,
              color: isTableView
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => onToggle(true),
            tooltip: 'Table View',
          ),
        ],
      ),
    );
  }
}

enum _GroupByColumn { date, title, category, remark }

class _TableChartsSection extends StatefulWidget {
  final FinanceState state;

  const _TableChartsSection({required this.state});

  @override
  State<_TableChartsSection> createState() => _TableChartsSectionState();
}

class _TableChartsSectionState extends State<_TableChartsSection> {
  List<MerchantSummary> _getSummaries() {
    final groupBy = context.select<FinanceBloc, FinanceGroupByColumn>(
      (b) => b.state.transactionsGroupByColumn,
    );
    switch (groupBy) {
      case FinanceGroupByColumn.date:
        return widget.state.byDate;
      case FinanceGroupByColumn.title:
        return widget.state.byTitle;
      case FinanceGroupByColumn.category:
        final map = widget.state.byCategory;
        return map.entries
            .map((e) => MerchantSummary(
                  name: e.key,
                  total: e.value,
                  count: 0,
                  transactions: [],
                ))
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));
      case FinanceGroupByColumn.remark:
        return widget.state.byRemark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaries = _getSummaries();
    final top = summaries.take(10).toList();
    final total = top.fold(0.0, (s, e) => s + e.total);
    if (top.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group by',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Date', _GroupByColumn.date),
                const SizedBox(width: 6),
                _chip('Title', _GroupByColumn.title),
                const SizedBox(width: 6),
                _chip('Category', _GroupByColumn.category),
                const SizedBox(width: 6),
                _chip('Remark', _GroupByColumn.remark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 20,
                    sections: top.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final pct = total > 0 ? (s.total / total) : 0.0;
                      return PieChartSectionData(
                        value: s.total,
                        title: pct >= 0.08 ? '${(pct * 100).round()}%' : '',
                        color: FinanceTheme.chartPalette[i % FinanceTheme.chartPalette.length],
                        radius: 24,
                        titleStyle: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxTotal = top.map((s) => s.total).reduce((a, b) => a > b ? a : b);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: top.asMap().entries.map((e) {
                          final i = e.key;
                          final s = e.value;
                          final width = maxTotal > 0 ? (s.total / maxTotal).clamp(0.0, 1.0) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FinanceTheme.chartPalette[i % FinanceTheme.chartPalette.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    s.name,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: LayoutBuilder(
                                    builder: (context, c) {
                                      return SizedBox(
                                        width: c.maxWidth * width,
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: FinanceTheme.chartPalette[i % FinanceTheme.chartPalette.length].withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    NumberFormat.compact().format(s.total),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _GroupByColumn value) {
    final groupBy = context.select<FinanceBloc, FinanceGroupByColumn>(
      (b) => b.state.transactionsGroupByColumn,
    );
    final mapped = switch (value) {
      _GroupByColumn.date => FinanceGroupByColumn.date,
      _GroupByColumn.title => FinanceGroupByColumn.title,
      _GroupByColumn.category => FinanceGroupByColumn.category,
      _GroupByColumn.remark => FinanceGroupByColumn.remark,
    };
    final selected = groupBy == mapped;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          context.read<FinanceBloc>().add(SetTransactionsGroupByColumn(mapped)),
    );
  }
}

class _TransactionTable extends StatelessWidget {
  final List<Transaction> transactions;
  final bool enabled;
  final void Function(Transaction t) onTapCategory;
  final void Function(Transaction t) onEditRemark;
  final void Function(Transaction t) onDelete;

  const _TransactionTable({
    required this.transactions,
    required this.enabled,
    required this.onTapCategory,
    required this.onEditRemark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Bank/Source', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
              label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Sender', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: transactions.map((t) {
            final isCredit = t.type == TransactionType.credit;
            final dateStr = '${t.date.day}/${t.date.month}/${t.date.year}';
            final bankSource = t.bankName ?? t.sourceKey ?? t.sender ?? '-';
            final title = t.title ?? t.displayTitle;
            final typeLabel = isCredit ? 'Credit' : 'Debit';
            final amountStr = '${isCredit ? '+' : '-'}$kCurrencySymbol ${t.amount.toStringAsFixed(2)}';
            final category = t.category ?? '-';
            final remark = t.userRemark ?? t.rawRemark ?? t.systemRemark ?? '-';
            final sender = t.sender ?? t.sourceKey ?? '-';

            return DataRow(
              cells: [
                DataCell(Text(dateStr, style: FinanceTheme.caption(context))),
                DataCell(
                  Text(
                    bankSource,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: title,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCredit ? FinanceTheme.creditColor : FinanceTheme.debitColor)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: isCredit ? FinanceTheme.creditColor : FinanceTheme.debitColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    amountStr,
                    style: FinanceTheme.amountTrailing(context, isCredit: isCredit),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: enabled ? 'Tap to edit category' : category,
                    child: t.category != null
                        ? InkWell(
                            onTap: enabled ? () => onTapCategory(t) : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FinanceTheme.getCategoryColor(t.category)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: FinanceTheme.getCategoryColor(t.category),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (enabled) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit, size: 12, color: FinanceTheme.getCategoryColor(t.category)),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: enabled ? () => onTapCategory(t) : null,
                            child: Text(category, style: FinanceTheme.caption(context)),
                          ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: enabled ? 'Tap to edit remark' : remark,
                    child: Text(
                      remark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  showEditIcon: true,
                  onTap: enabled ? () => onEditRemark(t) : null,
                ),
                DataCell(
                  Text(
                    sender,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: enabled ? () => onDelete(t) : null,
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTapCategory;
  final VoidCallback? onEditRemark;

  const _TransactionTile({
    required this.transaction,
    required this.onTapCategory,
    this.onEditRemark,
  });

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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FinanceBloc>().add(
                UpdateTransactionRemark(transaction.id, controller.text.trim()),
              );
              Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remark updated'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final displayTitle = transaction.title ??
        transaction.rawRemark ??
        transaction.merchant ??
        transaction.description;
    final categoryColor = FinanceTheme.getCategoryColor(transaction.category);
    final hasUserRemark = transaction.userRemark != null && transaction.userRemark!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: FinanceTheme.gapBetweenCards),
      child: Dismissible(
        key: ValueKey(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
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
          ) ?? false;
        },
        onDismissed: (_) {
          context.read<FinanceBloc>().add(DeleteTransaction(transaction.id));
        },
        child: Material(
          color: FinanceTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: categoryColor, width: 4),
              ),
              borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: FinanceTheme.listItemPaddingH,
              vertical: FinanceTheme.listItemPaddingV,
            ),
            child: Row(
              children: [
                CategoryIcon.build(category: transaction.category, size: 24),
                const SizedBox(width: FinanceTheme.gapBetweenCards),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title: "NIC Asia Debit" or fallback
                        Text(
                          displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Source key + date row
                        Row(
                          children: [
                            if (transaction.sourceKey != null) ...[
                              Text(
                                transaction.sourceKey!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('|', style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                              style: FinanceTheme.caption(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Remark row (tap to edit)
                        GestureDetector(
                          onTap: onEditRemark ?? () => _editRemark(context),
                          child: Row(
                            children: [
                              Icon(
                                hasUserRemark ? Icons.edit_note_rounded : Icons.add_comment_outlined,
                                size: 14,
                                color: hasUserRemark ? categoryColor : Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hasUserRemark ? transaction.userRemark! : 'Tap to add remark',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: hasUserRemark
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.outline,
                                    fontStyle: hasUserRemark ? FontStyle.normal : FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Category badge (tap to change)
                        if (transaction.category != null)
                          InkWell(
                            onTap: onTapCategory,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                transaction.category!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: onTapCategory,
                            borderRadius: BorderRadius.circular(6),
                            child: Text(
                              'Tap to set category',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${isCredit ? '+' : '-'}$kCurrencySymbol ${transaction.amount.toStringAsFixed(2)}',
                  style: FinanceTheme.amountTrailing(context, isCredit: isCredit),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  tooltip: 'Edit category or remark',
                  onSelected: (value) {
                    if (value == 'category') onTapCategory();
                    if (value == 'remark' && (onEditRemark != null)) onEditRemark!();
                    if (value == 'remark' && onEditRemark == null) _editRemark(context);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'category', child: Text('Edit category')),
                    const PopupMenuItem(value: 'remark', child: Text('Edit remark')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
