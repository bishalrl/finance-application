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

/// Calendar view: days with transactions marked; tap day → bottom sheet with that day's list.
class FinanceCalendarPage extends StatelessWidget {
  final bool embedded;
  const FinanceCalendarPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final selectedMonth = context.select<FinanceBloc, DateTime>(
      (b) => b.state.calendarSelectedMonth,
    );
    final monthNav = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final next = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
              context.read<FinanceBloc>().add(SetCalendarSelectedMonth(next));
            },
          ),
          Text(
            DateFormat('MMMM y').format(selectedMonth),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final next = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
              context.read<FinanceBloc>().add(SetCalendarSelectedMonth(next));
            },
          ),
        ],
      ),
    );

    final body = Column(
      children: [
        monthNav,
        Expanded(
          child: BlocBuilder<FinanceBloc, FinanceState>(
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.transactionsByDay != c.transactionsByDay ||
                p.calendarSelectedMonth != c.calendarSelectedMonth,
            builder: (context, state) {
              final byDay = state.transactionsByDay;
              final daysWithTx = byDay.keys.toSet();
              final intensity = state.dailySpendingIntensity;
              final isLoading = state.status == FinanceStatus.loading;

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(FinanceTheme.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CalendarGrid(
                          month: selectedMonth,
                          daysWithTransactions: daysWithTx,
                          intensityMap: intensity,
                          onDayTap: (day) =>
                              _showDayBottomSheet(context, day, state),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    const Positioned.fill(
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: body,
    );
  }

  void _showEditRemarkDialog(BuildContext context, Transaction t) {
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
                  const SnackBar(
                    content: Text('Remark updated'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDayBottomSheet(
    BuildContext context,
    DateTime day,
    FinanceState state,
  ) {
    final list = state.transactionsByDay[day] ?? [];
    final dayStr = DateFormat('EEEE, MMM d').format(day);

    // Calculate daily totals
    double dayCredit = 0, dayDebit = 0;
    for (final t in list) {
      if (t.type == TransactionType.credit) {
        dayCredit += t.amount;
      } else {
        dayDebit += t.amount;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FinanceTheme.cardPadding),
              child: Text(dayStr, style: FinanceTheme.sectionTitle(ctx)),
            ),
            // Daily total card
            if (list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FinanceTheme.pagePadding,
                ),
                child: Container(
                  padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                  margin: const EdgeInsets.only(
                    bottom: FinanceTheme.gapBetweenCards,
                  ),
                  decoration: BoxDecoration(
                    color: FinanceTheme.cardBackgroundElevated(ctx),
                    borderRadius: BorderRadius.circular(
                      FinanceTheme.radiusCard,
                    ),
                    boxShadow: FinanceTheme.cardShadow(ctx, elevation: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Income',
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$kCurrencySymbol ${dayCredit.toStringAsFixed(0)}',
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              color: FinanceTheme.creditColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Theme.of(ctx).dividerColor,
                      ),
                      Column(
                        children: [
                          Text(
                            'Expense',
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$kCurrencySymbol ${dayDebit.toStringAsFixed(0)}',
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              color: FinanceTheme.debitColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Theme.of(ctx).dividerColor,
                      ),
                      Column(
                        children: [
                          Text(
                            'Net',
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$kCurrencySymbol ${(dayCredit - dayDebit).toStringAsFixed(0)}',
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              color: (dayCredit - dayDebit) >= 0
                                  ? FinanceTheme.creditColor
                                  : FinanceTheme.debitColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Flexible(
              child: list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(FinanceTheme.gapSection),
                      child: Text(
                        'No transactions on this day',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FinanceTheme.pagePadding,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final t = list[i];
                        return _DayTransactionTile(
                          transaction: t,
                          onEditRemark: () => _showEditRemarkDialog(ctx, t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Set<DateTime> daysWithTransactions;
  final Map<DateTime, double> intensityMap;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.daysWithTransactions,
    required this.intensityMap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = last.day;
    final weekdayStart = first.weekday; // 1 = Monday
    final leadingEmpty = weekdayStart - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Material(
      color: FinanceTheme.cardBackgroundElevated(context),
      borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(FinanceTheme.cardPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekLabels
                  .map(
                    (l) => SizedBox(
                      width: 36,
                      child: Text(
                        l,
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            ...List.generate(rows, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    if (cellIndex < leadingEmpty) {
                      return const SizedBox(width: 40, height: 40);
                    }
                    final dayNum = cellIndex - leadingEmpty + 1;
                    if (dayNum > daysInMonth) {
                      return const SizedBox(width: 40, height: 40);
                    }
                    final day = DateTime(month.year, month.month, dayNum);
                    final hasTx = daysWithTransactions.any(
                      (d) =>
                          d.year == day.year &&
                          d.month == day.month &&
                          d.day == day.day,
                    );

                    // Find max spend in this month for normalization
                    double maxSpend = 0;
                    for (int dd = 1; dd <= daysInMonth; dd++) {
                      final d = DateTime(month.year, month.month, dd);
                      final v = intensityMap[d] ?? 0;
                      if (v > maxSpend) maxSpend = v;
                    }
                    final spend = intensityMap[day] ?? 0;
                    final intensity = maxSpend > 0
                        ? (spend / maxSpend).clamp(0.0, 1.0)
                        : 0.0;

                    return _DayCell(
                      day: dayNum,
                      hasTransactions: hasTx,
                      spendingIntensity: intensity,
                      isToday:
                          day.year == DateTime.now().year &&
                          day.month == DateTime.now().month &&
                          day.day == DateTime.now().day,
                      onTap: () => onDayTap(day),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasTransactions;
  final double spendingIntensity; // 0.0 - 1.0
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.hasTransactions,
    this.spendingIntensity = 0.0,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use heatmap color based on spending intensity
    final heatColor = hasTransactions && spendingIntensity > 0
        ? FinanceTheme.heatmapColor(spendingIntensity)
        : null;

    // "No Spend Day" logic
    final isNoSpend = !hasTransactions;
    final noSpendColor = Colors.green.withOpacity(0.1);

    final useWhiteText = spendingIntensity > 0.5 && hasTransactions;
    final dayColor = useWhiteText
        ? Colors.white
        : (isNoSpend
            ? Colors.green[800]
            : Theme.of(context).colorScheme.onSurface);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: heatColor ?? (isNoSpend ? noSpendColor : null),
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: FinanceTheme.debitColor, width: 2)
              : null,
          boxShadow: hasTransactions
              ? FinanceTheme.cardShadow(context, elevation: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: hasTransactions || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: dayColor,
              ),
            ),
            if (hasTransactions)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: useWhiteText ? Colors.white : FinanceTheme.debitColor,
                  shape: BoxShape.circle,
                ),
              )
            else if (isNoSpend)
              const Icon(Icons.star_rounded, size: 8, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _DayTransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onEditRemark;

  const _DayTransactionTile({
    required this.transaction,
    this.onEditRemark,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final displayTitle =
        transaction.title ??
        transaction.rawRemark ??
        transaction.merchant ??
        transaction.description;
    final categoryColor = FinanceTheme.getCategoryColor(transaction.category);
    final hasUserRemark =
        transaction.userRemark != null && transaction.userRemark!.isNotEmpty;

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
          child: ListTile(
            leading: CategoryIcon.build(
              category: transaction.category,
              size: 22,
            ),
            title: Text(
              displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: onEditRemark != null ? () => onEditRemark!() : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEditRemark != null)
                  IconButton(
                    icon: Icon(
                      hasUserRemark ? Icons.edit_note_rounded : Icons.add_comment_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: onEditRemark,
                    tooltip: 'Edit remark',
                  ),
                Text(
                  '${isCredit ? '+' : '-'}$kCurrencySymbol ${transaction.amount.toStringAsFixed(0)}',
                  style: FinanceTheme.amountTrailing(context, isCredit: isCredit),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank name
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
                        Icon(
                          Icons.edit_note_rounded,
                          size: 11,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            transaction.userRemark!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Category badge
                if (transaction.category != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
