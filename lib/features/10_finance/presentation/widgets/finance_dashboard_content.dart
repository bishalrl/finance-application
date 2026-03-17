import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:life_vault/features/10_finance/presentation/widgets/category_breakdown_chart.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../../../../core/services/feature_tour_storage.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import 'sms_permission_dialog.dart';
import '../pages/transactions_page.dart';
import '../pages/finance_timeline_page.dart';
import '../pages/finance_calendar_page.dart';
import '../pages/finance_categories_page.dart';
import '../pages/finance_merchants_page.dart';
import '../pages/finance_summary_page.dart';
import '../pages/finance_flow_detail_page.dart';
import '../pages/filtered_transactions_page.dart';
import '../pages/transaction_detail_page.dart';
import '../pages/insight_detail_page.dart';
import '../pages/finance_page.dart';
import '../../domain/entities/finance_category.dart';
import 'category_icon.dart';
import 'source_breakdown_chart.dart';

/// Reusable finance dashboard: balance cards, import CTA, recent transactions, shortcuts.
class FinanceDashboardContent extends StatelessWidget {
  const FinanceDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinanceBloc, FinanceState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage && c.errorMessage != null,
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.transactions != c.transactions ||
          p.filterType != c.filterType ||
          p.filterCategory != c.filterCategory ||
          p.filterDateFrom != c.filterDateFrom ||
          p.filterDateTo != c.filterDateTo ||
          p.recurringCategoryLabels != c.recurringCategoryLabels,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == FinanceStatus.loading &&
            state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final credit = state.totalCredit;
        final debit = state.totalDebit;
        final recent = state.transactions.take(5).toList();

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FinanceBloc>().add(const LoadTransactions());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Hero: Balance Trend & Source Analysis Carousel ─────
                if (state.balanceTrendMonthly.isNotEmpty) ...[
                  _DashboardCarousel(state: state),
                  const SizedBox(height: FinanceTheme.gapSectionLarge),
                ],

                // ─── Income vs Expense + Savings Ring ───────────────────
                _BalanceCards(
                  credit: credit,
                  debit: debit,
                  onTapReceived: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<FinanceBloc>(),
                          child: const FinanceFlowDetailPage(
                            type: TransactionType.credit,
                            initialPeriod: FinanceFlowPeriodUi.thisMonth,
                          ),
                        ),
                      ),
                    );
                  },
                  onTapSpent: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<FinanceBloc>(),
                          child: const FinanceFlowDetailPage(
                            type: TransactionType.debit,
                            initialPeriod: FinanceFlowPeriodUi.thisMonth,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                Row(
                  children: [
                    Expanded(flex: 2, child: _NetFlowCard(net: state.netFlow)),
                    const SizedBox(width: FinanceTheme.gapBetweenCards),
                    Expanded(child: _SavingsRateRing(rate: state.savingsRate)),
                  ],
                ),
                const SizedBox(height: FinanceTheme.gapSection),
                _QuickStatsRow(
                  state: state,
                  onTapToday: () {
                    final now = DateTime.now();
                    final from = DateTime(now.year, now.month, now.day);
                    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<FinanceBloc>(),
                          child: FilteredTransactionsPage(
                            title: 'Today',
                            from: from,
                            to: to,
                          ),
                        ),
                      ),
                    );
                  },
                  onTapThisWeek: () {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final weekStart = today.subtract(Duration(days: today.weekday - 1));
                    final weekEnd = weekStart.add(const Duration(days: 6));
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<FinanceBloc>(),
                          child: FilteredTransactionsPage(
                            title: 'This week',
                            from: weekStart,
                            to: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
                          ),
                        ),
                      ),
                    );
                  },
                  onTapBiggest: state.biggestCategory == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => BlocProvider.value(
                                value: context.read<FinanceBloc>(),
                                child: FilteredTransactionsPage(
                                  title: state.biggestCategory!,
                                  category: state.biggestCategory!,
                                ),
                              ),
                            ),
                          );
                        },
                  onTapLast: state.lastTransaction == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => BlocProvider.value(
                                value: context.read<FinanceBloc>(),
                                child: TransactionDetailPage(
                                  transaction: state.lastTransaction!,
                                ),
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: FinanceTheme.gapSection),

                // ─── Quick Insights Carousel ────────────────────────────
                if (state.quickInsights.isNotEmpty) ...[
                  _SectionTitle(title: 'Insights'),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  _InsightsCarousel(insights: state.quickInsights),
                  const SizedBox(height: FinanceTheme.gapSectionLarge),
                ],

                // ─── By Remark (top spending reasons) ────────────────────
                if (state.byRemark.isNotEmpty) ...[
                  _SectionTitle(title: 'By Remark'),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  _RemarkBreakdownCard(remarks: state.byRemark.take(8).toList()),
                  const SizedBox(height: FinanceTheme.gapSectionLarge),
                ],

                // ─── Import SMS ─────────────────────────────────────────
                _ImportSmsButton(),
                const SizedBox(height: FinanceTheme.gapSection),

                // ─── More views: Calendar, Summary, Transactions, etc. ───
                _SectionTitle(title: 'More views'),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MoreViewChip(
                        icon: Icons.calendar_month_rounded,
                        label: 'Calendar',
                        onTap: () => _openFinanceTab(context, 6),
                      ),
                      const SizedBox(width: 8),
                      _MoreViewChip(
                        icon: Icons.timeline_rounded,
                        label: 'Activity',
                        onTap: () => _openFinanceTab(context, 5),
                      ),
                      const SizedBox(width: 8),
                      _MoreViewChip(
                        icon: Icons.pie_chart_rounded,
                        label: 'Summary',
                        onTap: () => _openFinanceTab(context, 4),
                      ),
                      const SizedBox(width: 8),
                      _MoreViewChip(
                        icon: Icons.receipt_long_rounded,
                        label: 'Transactions',
                        onTap: () => _openFinanceTab(context, 3),
                      ),
                      const SizedBox(width: 8),
                      _MoreViewChip(
                        icon: Icons.category_rounded,
                        label: 'Categories',
                        onTap: () => _openFinanceTab(context, 7),
                      ),
                      const SizedBox(width: 8),
                      _MoreViewChip(
                        icon: Icons.store_rounded,
                        label: 'Merchants',
                        onTap: () => _openFinanceTab(context, 8),
                      ),
                      const SizedBox(width: 8),
                      _MoreViewChip(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'All views',
                        onTap: () => _openFinanceTab(context, null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FinanceTheme.gapSectionLarge),

                // ─── Recent Transactions ────────────────────────────────
                _SectionTitle(title: 'Recent transactions'),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                if (recent.isEmpty)
                  _EmptyTransactionsHint()
                else
                  ...recent.map((t) => _TransactionCard(transaction: t)),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  _SeeAllButton(
                    count: state.transactions.length,
                    onTap: () => _openTransactions(context),
                  ),
                ],
                const SizedBox(height: FinanceTheme.gapSectionLarge),

                // ─── Spending by Category Donut + Legend ─────────────────
                _SectionTitle(title: 'Top categories'),
                const SizedBox(height: FinanceTheme.gapBetweenCards),
                if (state.byCategory.isNotEmpty) ...[
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                    decoration: BoxDecoration(
                      color: FinanceTheme.cardBackgroundElevated(context),
                      borderRadius: BorderRadius.circular(
                        FinanceTheme.radiusCard,
                      ),
                      boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
                    ),
                    child: _DashboardPieChart(
                      data: state.byCategory,
                      onTapCategory: (cat) {
                        context.read<FinanceBloc>().add(FilterByCategory(cat));
                        _openCategories(context);
                      },
                    ),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  _PieChartLegend(data: state.byCategory),
                  const SizedBox(height: FinanceTheme.gapSection),
                ],
                _TopCategoriesSection(state: state),
                const SizedBox(height: FinanceTheme.gapSectionLarge),
                _RecurringSection(state: state),
                const SizedBox(height: FinanceTheme.gapSection),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFinanceTab(BuildContext context, int? tabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: FinancePage(initialTabIndex: tabIndex),
        ),
      ),
    );
  }

  void _openTransactions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const TransactionsPage(),
        ),
      ),
    );
  }

  void _openSummary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const FinanceSummaryPage(),
        ),
      ),
    );
  }

  void _openTimeline(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const FinanceTimelinePage(),
        ),
      ),
    );
  }

  void _openCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const FinanceCalendarPage(),
        ),
      ),
    );
  }

  void _openCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const FinanceCategoriesPage(),
        ),
      ),
    );
  }

  void _openMerchants(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const FinanceMerchantsPage(),
        ),
      ),
    );
  }
}

class _NetFlowCard extends StatelessWidget {
  final double net;

  const _NetFlowCard({required this.net});

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    final color = isPositive
        ? FinanceTheme.creditColor
        : FinanceTheme.debitColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FinanceTheme.cardPadding,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Net flow',
            style: FinanceTheme.labelCaps(
              context,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$kCurrencySymbol ${net.toStringAsFixed(0)}',
            style: FinanceTheme.amountLarge(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RemarkBreakdownCard extends StatelessWidget {
  final List<MerchantSummary> remarks;
  const _RemarkBreakdownCard({required this.remarks});

  @override
  Widget build(BuildContext context) {
    final maxTotal = remarks.isEmpty
        ? 1.0
        : remarks.map((r) => r.total).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: remarks.map((r) {
          final widthFactor = (r.total / maxTotal).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: widthFactor,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$kCurrencySymbol ${r.total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final FinanceState state;
  final VoidCallback? onTapToday;
  final VoidCallback? onTapThisWeek;
  final VoidCallback? onTapBiggest;
  final VoidCallback? onTapLast;

  const _QuickStatsRow({
    required this.state,
    this.onTapToday,
    this.onTapThisWeek,
    this.onTapBiggest,
    this.onTapLast,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickStatChip(
            label: 'Today',
            value: '$kCurrencySymbol ${state.spentToday.toStringAsFixed(0)}',
            color: FinanceTheme.debitColor,
            onTap: onTapToday,
          ),
          const SizedBox(width: FinanceTheme.gapBetweenCards),
          _QuickStatChip(
            label: 'This week',
            value: '$kCurrencySymbol ${state.spentThisWeek.toStringAsFixed(0)}',
            color: const Color(0xFF6366F1),
            onTap: onTapThisWeek,
          ),
          const SizedBox(width: FinanceTheme.gapBetweenCards),
          _QuickStatChip(
            label: 'Biggest',
            value: state.biggestCategory ?? '—',
            color: state.biggestCategory != null
                ? FinanceTheme.getCategoryColor(state.biggestCategory)
                : const Color(0xFF6B7280),
            onTap: onTapBiggest,
          ),
          if (state.lastTransaction != null) ...[
            const SizedBox(width: FinanceTheme.gapBetweenCards),
            _QuickStatChip(
              label: 'Last',
              value:
                  '${state.lastTransaction!.type == TransactionType.credit ? '+' : '-'}$kCurrencySymbol ${state.lastTransaction!.amount.toStringAsFixed(0)}',
              color: state.lastTransaction!.type == TransactionType.credit
                  ? FinanceTheme.creditColor
                  : FinanceTheme.debitColor,
              onTap: onTapLast,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const _QuickStatChip({
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? FinanceTheme.debitColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FinanceTheme.listItemPaddingH,
            vertical: FinanceTheme.listItemPaddingV,
          ),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
            border: Border.all(color: chipColor.withOpacity(0.15), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: chipColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringSection extends StatelessWidget {
  final FinanceState state;

  const _RecurringSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final labels = state.recurringCategoryLabels.toList()..sort();
    if (labels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(FinanceTheme.cardPadding),
        decoration: BoxDecoration(
          color: FinanceTheme.cardBackgroundElevated(context),
          borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        ),
        child: Row(
          children: [
            Icon(
              Icons.repeat,
              color: Theme.of(context).colorScheme.outline,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mark categories as recurring (e.g. Rent, Grocery) in Categories',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Recurring'),
        const SizedBox(height: FinanceTheme.gapBetweenCards),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.map((cat) {
            final catColor = FinanceTheme.getCategoryColor(cat);
            return Chip(
              avatar: Icon(Icons.repeat, size: 16, color: catColor),
              label: Text(cat),
              backgroundColor: catColor.withOpacity(0.15),
              labelStyle: TextStyle(
                color: catColor,
                fontWeight: FontWeight.w600,
              ),
              onDeleted: () =>
                  context.read<FinanceBloc>().add(ToggleRecurringCategory(cat)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TopCategoriesSection extends StatelessWidget {
  final FinanceState state;

  const _TopCategoriesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final entries = state.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: FinanceTheme.cardBackgroundElevated(context),
          borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        ),
        child: Center(
          child: Text(
            'No spending data yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    const topN = 5;
    final top = entries.take(topN).toList();
    final rest = entries.skip(topN);
    final restTotal = rest.fold(0.0, (s, e) => s + e.value);

    return Column(
      children: [
        ...top.map((e) {
          final catColor = FinanceTheme.getCategoryColor(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FinanceTheme.listItemPaddingH,
                vertical: FinanceTheme.listItemPaddingV,
              ),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  FinanceTheme.radiusListTile,
                ),
                border: Border.all(color: catColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  CategoryIcon.build(category: e.key, size: 20),
                  const SizedBox(width: FinanceTheme.gapBetweenCards),
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$kCurrencySymbol ${e.value.toStringAsFixed(0)}',
                      style: FinanceTheme.amountTrailing(
                        context,
                        isCredit: false,
                      ).copyWith(color: catColor),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (rest.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Other (${rest.length})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$kCurrencySymbol ${restTotal.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DashboardCarousel extends StatefulWidget {
  final FinanceState state;

  const _DashboardCarousel({required this.state});

  @override
  State<_DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<_DashboardCarousel> {
  final PageController _controller = PageController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      final current = context.read<FinanceBloc>().state.dashboardCarouselPage;
      if (page != current) {
        context.read<FinanceBloc>().add(SetDashboardCarouselPage(page));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = context.select<FinanceBloc, int>(
      (b) => b.state.dashboardCarouselPage,
    );
    // Determine which slides to show
    final hasSourceData = widget.state.bySender.isNotEmpty;
    final hasCategoryData = widget.state.byCategory.isNotEmpty;

    int pageCount = 1; // Always show Balance Trend
    if (hasSourceData) pageCount++;
    if (hasCategoryData) pageCount++;

    final hasMultipleSlides = pageCount > 1;

    return Column(
      children: [
        // Slide counter and hint
        if (hasMultipleSlides) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentPage + 1} of $pageCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.swipe_left_alt,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe to see more',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            SizedBox(
              height: 320, // Adjusted height to fit chart + title
              child: PageView(
                onPageChanged: (page) => context
                    .read<FinanceBloc>()
                    .add(SetDashboardCarouselPage(page)),
                controller: _controller,
                children: [
              // Slide 1: Balance Trend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Balance trend'),
                    const SizedBox(height: FinanceTheme.gapBetweenCards),
                    Expanded(
                      child: _BalanceTrendChart(
                        data: widget.state.balanceTrendMonthly,
                      ),
                    ),
                  ],
                ),
              ),
              // Slide 2: Spending by Source
              if (hasSourceData)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'Spending by source'),
                      const SizedBox(height: FinanceTheme.gapBetweenCards),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<FinanceBloc>(),
                                  child: const FinanceMerchantsPage(
                                    showSenders: true,
                                  ),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(
                            FinanceTheme.radiusCard,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(
                              FinanceTheme.cardPadding,
                            ),
                            decoration: BoxDecoration(
                              color: FinanceTheme.cardBackgroundElevated(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(
                                FinanceTheme.radiusCard,
                              ),
                              boxShadow: FinanceTheme.cardShadow(
                                context,
                                elevation: 2,
                              ),
                            ),
                            child: SourceBreakdownChart(
                              data: widget.state.bySender,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Slide 3: Spending by Category
              if (hasCategoryData)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'Spending by category'),
                      const SizedBox(height: FinanceTheme.gapBetweenCards),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<FinanceBloc>(),
                                  child: const FinanceCategoriesPage(),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(
                            FinanceTheme.radiusCard,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(
                              FinanceTheme.cardPadding,
                            ),
                            decoration: BoxDecoration(
                              color: FinanceTheme.cardBackgroundElevated(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(
                                FinanceTheme.radiusCard,
                              ),
                              boxShadow: FinanceTheme.cardShadow(
                                context,
                                elevation: 2,
                              ),
                            ),
                            child: CategoryBreakdownChart(
                              data: widget.state.byCategory,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
            // Navigation arrows
            if (hasMultipleSlides) ...[
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (currentPage > 0) {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: currentPage > 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (currentPage < pageCount - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: currentPage < pageCount - 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasMultipleSlides) ...[
          const SizedBox(height: 12),
          Center(
            child: SmoothPageIndicator(
              controller: _controller,
              count: pageCount,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Theme.of(context).primaryColor,
                dotColor: Theme.of(context).disabledColor.withOpacity(0.3),
                expansionFactor: 3,
                spacing: 6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BalanceCards extends StatelessWidget {
  final double credit;
  final double debit;
  final VoidCallback? onTapReceived;
  final VoidCallback? onTapSpent;

  const _BalanceCards({
    required this.credit,
    required this.debit,
    this.onTapReceived,
    this.onTapSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTapReceived,
            borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
            child: _BalanceCard(
              label: 'Received',
              amount: credit,
              color: FinanceTheme.creditColor,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
        ),
        const SizedBox(width: FinanceTheme.gapBetweenCards),
        Expanded(
          child: InkWell(
            onTap: onTapSpent,
            borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
            child: _BalanceCard(
              label: 'Spent',
              amount: debit,
              color: FinanceTheme.debitColor,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: FinanceTheme.labelCaps(
                  context,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$kCurrencySymbol ${amount.toStringAsFixed(0)}',
            style: FinanceTheme.amountLarge(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ImportSmsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        final ok = await SmsPermissionDialog.show(context);
        if (ok == true && context.mounted) {
          context.read<FinanceBloc>().add(const ParseSmsTransactionsEvent());
          final storage = di.sl<FeatureTourStorage>();
          if (!await storage.hasSeenFinanceImportTutorial()) {
            await storage.setFinanceImportTutorialSeen();
            if (!context.mounted) return;
            // Show one-time tutorial explaining import -> visuals -> See all -> edit remarks.
            // ignore: use_build_context_synchronously
            await showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (ctx) {
                final theme = Theme.of(ctx);
                return Padding(
                  padding: EdgeInsets.only(
                    left: FinanceTheme.pagePadding,
                    right: FinanceTheme.pagePadding,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens after import?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Dashboard updates: Artha reads your bank SMS and updates the cards and charts above so you can see spending by date, title, category and remark.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2. Tap "See all": Under Recent transactions, use the See all button to open the full table of transactions.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '3. Edit category & remark: In the table, tap a transaction to edit its category and remark so your analytics stay clean.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Got it'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }
      },
      icon: const Icon(Icons.sms_outlined, size: 22),
      label: const Text('Import from SMS'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinanceTheme.radiusButton),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: FinanceTheme.sectionTitle(context));
  }
}

class _MoreViewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreViewChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: FinanceTheme.listItemPaddingH,
      ),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
      ),
      child: Center(
        child: Text(
          'Import bank SMS to see transactions here',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final displayTitle = transaction.title ??
        transaction.rawRemark ??
        transaction.merchant ??
        transaction.description;
    final categoryColor = FinanceTheme.getCategoryColor(transaction.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: FinanceTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<FinanceBloc>(),
                  child: const TransactionsPage(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (transaction.bankName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            transaction.bankName!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (transaction.category != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _SeeAllButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.list_alt, size: 20),
      label: Text('See all ($count)'),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final VoidCallback onTransactions;
  final VoidCallback onSummary;
  final VoidCallback onTimeline;
  final VoidCallback onCalendar;
  final VoidCallback onCategories;
  final VoidCallback onMerchants;

  const _ShortcutGrid({
    required this.onTransactions,
    required this.onSummary,
    required this.onTimeline,
    required this.onCalendar,
    required this.onCategories,
    required this.onMerchants,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.receipt_long_rounded,
                label: 'Transactions',
                onTap: onTransactions,
                gradientColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: FinanceTheme.gapBetweenCards),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.pie_chart_rounded,
                label: 'Summary',
                onTap: onSummary,
                gradientColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: FinanceTheme.gapBetweenCards),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.timeline_rounded,
                label: 'Activity',
                onTap: onTimeline,
                gradientColor: const Color(0xFF06B6D4),
              ),
            ),
            const SizedBox(width: FinanceTheme.gapBetweenCards),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                onTap: onCalendar,
                gradientColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: FinanceTheme.gapBetweenCards),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.category_rounded,
                label: 'Categories',
                onTap: onCategories,
                gradientColor: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: FinanceTheme.gapBetweenCards),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.store_rounded,
                label: 'Merchants',
                onTap: onMerchants,
                gradientColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? gradientColor;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradientColor,
  });

  static final Map<String, Color> _shortcutColors = {
    'Transactions': const Color(0xFF6366F1),
    'Summary': const Color(0xFF8B5CF6),
    'Activity': const Color(0xFF06B6D4),
    'Calendar': const Color(0xFFF59E0B),
    'Categories': const Color(0xFFEC4899),
    'Merchants': const Color(0xFF10B981),
  };

  @override
  Widget build(BuildContext context) {
    final color =
        gradientColor ??
        _shortcutColors[label] ??
        Theme.of(context).colorScheme.primary;
    final gradient = FinanceTheme.categoryGradient(color, context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: FinanceTheme.cardPadding,
            horizontal: FinanceTheme.listItemPaddingH,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(FinanceTheme.radiusListTile),
            boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPieChart extends StatelessWidget {
  final Map<String, double> data;
  final ValueChanged<String>? onTapCategory;

  const _DashboardPieChart({required this.data, this.onTapCategory});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final total = entries.fold(0.0, (s, e) => s + e.value);
    final top5 = entries.take(5).toList();
    final rest = entries.skip(5);
    final restTotal = rest.fold(0.0, (s, e) => s + e.value);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event.isInterestedForInteractions &&
                response != null &&
                response.touchedSection != null &&
                onTapCategory != null) {
              final idx = response.touchedSection!.touchedSectionIndex;
              if (idx >= 0 && idx < top5.length) {
                onTapCategory!(top5[idx].key);
              }
            }
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: [
          ...top5.asMap().entries.map((entry) {
            final e = entry.value;
            final categoryColor = FinanceTheme.getCategoryColor(e.key);
            final percentage = (e.value / total * 100);

            return PieChartSectionData(
              color: categoryColor,
              value: e.value,
              title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
              radius: 70,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
          if (rest.isNotEmpty)
            PieChartSectionData(
              color: const Color(0xFF6B7280),
              value: restTotal,
              title: rest.length > 1
                  ? '${((restTotal / total) * 100).toStringAsFixed(0)}%'
                  : '',
              radius: 70,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pie Chart Legend ────────────────────────────────────────────────────────
class _PieChartLegend extends StatelessWidget {
  final Map<String, double> data;

  const _PieChartLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);
    final top5 = entries.take(5).toList();
    final rest = entries.skip(5);
    final restTotal = rest.fold(0.0, (s, e) => s + e.value);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        ...top5.map((e) {
          final pct = total > 0 ? (e.value / total * 100) : 0;
          return _LegendItem(
            color: FinanceTheme.getCategoryColor(e.key),
            label: '${e.key} (${pct.toStringAsFixed(0)}%)',
          );
        }),
        if (rest.isNotEmpty)
          _LegendItem(
            color: const Color(0xFF6B7280),
            label: 'Other (${(restTotal / total * 100).toStringAsFixed(0)}%)',
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── Balance Trend Line Chart ───────────────────────────────────────────────
class _BalanceTrendChart extends StatelessWidget {
  final List<MonthlyBalance> data;

  const _BalanceTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    double minY = double.infinity, maxY = double.negativeInfinity;
    int peakIdx = 0, lowIdx = 0;

    for (int i = 0; i < data.length; i++) {
      final y = data[i].cumulativeBalance;
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) {
        maxY = y;
        peakIdx = i;
      }
      if (y < minY) {
        minY = y;
        lowIdx = i;
      }
    }

    // Ensure some padding
    final range = maxY - minY;
    final padY = range > 0 ? range * 0.15 : 100;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
      ),
      child: LineChart(
        LineChartData(
          minY: minY - padY,
          maxY: maxY + padY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 100,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: data.length > 6 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      months[data[idx].month.month - 1],
                      style: FinanceTheme.chartAxisLabel(context),
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
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Rs. ${spot.y.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: FinanceTheme.trendLineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  // Highlight peak and low
                  if (index == peakIdx || index == lowIdx) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: index == peakIdx
                          ? FinanceTheme.creditColor
                          : FinanceTheme.debitColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 2.5,
                    color: FinanceTheme.trendLineColor,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FinanceTheme.trendFillStart,
                    FinanceTheme.trendFillEnd,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Savings Rate Ring ──────────────────────────────────────────────────────
class _SavingsRateRing extends StatelessWidget {
  final double rate;

  const _SavingsRateRing({required this.rate});

  @override
  Widget build(BuildContext context) {
    final clampedRate = rate.clamp(0.0, 100.0);
    final fillColor = clampedRate > 20
        ? FinanceTheme.savingsRingFill
        : (clampedRate > 0
              ? FinanceTheme.debitColor
              : FinanceTheme.savingsRingBackground);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackgroundElevated(context),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
        boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 25,
                sections: [
                  PieChartSectionData(
                    value: clampedRate,
                    color: fillColor,
                    radius: 8,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 100 - clampedRate,
                    color: FinanceTheme.savingsRingBackground.withOpacity(0.3),
                    radius: 6,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clampedRate.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fillColor,
                ),
              ),
              Text(
                'Saved',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Insights Carousel ────────────────────────────────────────────────
class _InsightsCarousel extends StatefulWidget {
  final List<InsightData> insights;

  const _InsightsCarousel({required this.insights});

  @override
  State<_InsightsCarousel> createState() => _InsightsCarouselState();
}

class _InsightsCarouselState extends State<_InsightsCarousel> {
  late final PageController _pageController;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      final current = context.read<FinanceBloc>().state.dashboardCarouselPage;
      if (page != current) {
        context.read<FinanceBloc>().add(SetDashboardCarouselPage(page));
      }
    });
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.insights.isEmpty) return;
      final next =
          ((_pageController.page?.round() ?? 0) + 1) % widget.insights.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleInsights = widget.insights.length > 1;
    final currentPage = context.select<FinanceBloc, int>(
      (b) => b.state.dashboardCarouselPage,
    );
    
    return Column(
      children: [
        // Slide counter
        if (hasMultipleInsights)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${currentPage + 1} of ${widget.insights.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        if (hasMultipleInsights) const SizedBox(height: 8),
        Stack(
          children: [
            SizedBox(
              height: 110,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.insights.length,
                itemBuilder: (context, index) {
              final insight = widget.insights[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(FinanceTheme.radiusCard),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<FinanceBloc>(),
                            child: InsightDetailPage(insight: insight),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
                      decoration: BoxDecoration(
                        gradient: FinanceTheme.insightCardGradient(insight.color),
                        borderRadius: BorderRadius.circular(
                          FinanceTheme.radiusCard,
                        ),
                        boxShadow: FinanceTheme.cardShadow(context, elevation: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              insight.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  insight.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  insight.description,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
            // Navigation arrows for insights
            if (hasMultipleInsights) ...[
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (currentPage > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: currentPage > 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (currentPage < widget.insights.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: currentPage < widget.insights.length - 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _pageController,
          count: widget.insights.length,
          effect: WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            spacing: 6,
            activeDotColor: Theme.of(context).colorScheme.primary,
            dotColor: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
