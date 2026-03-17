import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../data/services/finance_report_pdf_service.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';
import '../widgets/category_icon.dart';
import '../../domain/entities/transaction.dart';
import 'unlabeled_transactions_page.dart';
import 'insight_detail_page.dart';

class FinanceAnalyticsDashboardPage extends StatefulWidget {
  const FinanceAnalyticsDashboardPage({super.key});

  @override
  State<FinanceAnalyticsDashboardPage> createState() =>
      _FinanceAnalyticsDashboardPageState();
}

class _FinanceAnalyticsDashboardPageState
    extends State<FinanceAnalyticsDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Chart', 'Pie', 'Table', 'Monthly', 'Columns', 'Report'];
  final List<IconData> _tabIcons = [
    Icons.show_chart_rounded,
    Icons.pie_chart_rounded,
    Icons.table_rows_rounded,
    Icons.bar_chart_rounded,
    Icons.analytics_rounded,
    Icons.summarize_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 2,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<FinanceBloc>().add(SetAnalyticsTabIndex(_tabController.index));
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<FinanceBloc, FinanceState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.transactions != c.transactions ||
            p.analyticsTabBusy != c.analyticsTabBusy,
        builder: (context, state) {
          if (state.status == FinanceStatus.loading &&
              state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  context.read<FinanceBloc>().add(const LoadTransactions());
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildAppBar(state),
                    _buildInsightCarousel(state),
                    _buildTabSelector(),
                    _buildMainVisualization(state),
                    _buildDetailedInfoSection(state),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
              if (state.analyticsTabBusy)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(FinanceState state) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Analytics',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      centerTitle: false,
      actions: [
        if (state.unlabeledTransactionsCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => BlocProvider.value(
                      value: context.read<FinanceBloc>(),
                      child: const UnlabeledTransactionsPage(),
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                '${state.unlabeledTransactionsCount} Unlabeled',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: BlocBuilder<FinanceBloc, FinanceState>(
          buildWhen: (p, c) =>
              p.analyticsTabIndex != c.analyticsTabIndex ||
              p.analyticsTabBusy != c.analyticsTabBusy,
          builder: (context, state) {
            if (_tabController.index != state.analyticsTabIndex) {
              _tabController.animateTo(state.analyticsTabIndex);
            }
            return Container(
              height: 54,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final isActive = state.analyticsTabIndex == index;
                  return SizedBox(
                    width: 92,
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(index);
                        context.read<FinanceBloc>().add(SetAnalyticsTabIndex(index));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.95),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.80),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tabIcons[index],
                              size: 18,
                              color: isActive
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tabs[index],
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainVisualization(FinanceState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: Container(
          height: 340,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildChartContent(state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartContent(FinanceState state) {
    switch (state.analyticsTabIndex) {
      case 0:
        return _LineChartView(state: state);
      case 1:
        return _DonutChartView(state: state);
      case 2:
        return _TableChartView(state: state);
      case 3:
        return _ComparisonChartView(state: state);
      case 4:
        return _ColumnAnalyticsView(state: state);
      case 5:
        return _ReportView(state: state);
      default:
        return _LineChartView(state: state);
    }
  }

  Widget _buildInsightCarousel(FinanceState state) {
    final insights = state.quickInsights;
    if (insights.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(top: 10),
        child: PageView.builder(
          itemCount: insights.length,
          controller: PageController(viewportFraction: 0.9),
          itemBuilder: (context, index) {
            final insight = insights[index];
            return InkWell(
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
              borderRadius: BorderRadius.circular(24),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: FinanceTheme.insightCardGradient(insight.color),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: insight.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            insight.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            insight.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(insight.icon, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailedInfoSection(FinanceState state) {
    final transactions = state.filteredTransactions
        .take(10)
        .toList(); // Show top 10 recent

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.smartGroups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12, top: 20),
                child: Text(
                  'Spending Patterns',
                  style: FinanceTheme.sectionTitle(
                    context,
                  ).copyWith(color: const Color(0xFF1E293B)),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.smartGroups.length,
                  itemBuilder: (context, index) {
                    final group = state.smartGroups[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group.count} times',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Rs. ${group.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Recent Activity',
                style: FinanceTheme.sectionTitle(
                  context,
                ).copyWith(color: const Color(0xFF1E293B)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      onExpansionChanged: (expanded) {
                        context
                            .read<FinanceBloc>()
                            .add(SetAnalyticsDetailsExpanded(expanded));
                        HapticFeedback.selectionClick();
                      },
                      title: Text(
                        state.analyticsDetailsExpanded
                            ? 'Recent Activity'
                            : 'Show Transactions',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      trailing: AnimatedRotation(
                        turns: state.analyticsDetailsExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF475569).withOpacity(0.5),
                        ),
                      ),
                      children: [
                        if (transactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No recent transactions'),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) => Divider(
                              color: const Color(0xFFF1F5F9),
                              height: 1,
                              thickness: 1,
                            ),
                            itemBuilder: (context, index) {
                              final t = transactions[index];
                              return _TransactionListItem(transaction: t);
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartView extends StatelessWidget {
  final FinanceState state;
  const _LineChartView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.transactions.isEmpty) return const _EmptyState();

    final trend = state.balanceTrendMonthly;
    if (trend.isEmpty) return const _EmptyState();

    final spots = <FlSpot>[];
    for (int i = 0; i < trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), trend[i].cumulativeBalance));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (spots.isNotEmpty)
                ? _calculateInterval(spots)
                : 1000,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length)
                    return const SizedBox();
                  final date = trend[index].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF1E3A8A),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF1E3A8A),
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.15),
                    const Color(0xFF1E3A8A).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(List<FlSpot> spots) {
    final values = spots.map((e) => e.y).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = max - min;
    if (range == 0) return 1000;
    return range / 4;
  }
}

class _DonutChartView extends StatelessWidget {
  final FinanceState state;
  const _DonutChartView({required this.state});

  @override
  Widget build(BuildContext context) {
    final data = state.byCategory;
    if (data.isEmpty) return const _EmptyState();

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = data.values.fold(0.0, (s, v) => s + v);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: sortedEntries.take(5).map((e) {
                  final color = FinanceTheme.getCategoryColor(e.key);
                  final percentage = (e.value / total * 100).toStringAsFixed(0);
                  return PieChartSectionData(
                    color: color,
                    value: e.value,
                    title: '$percentage%',
                    radius: 20,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedEntries.take(5).map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: FinanceTheme.getCategoryColor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        NumberFormat.compact().format(e.value),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableChartView extends StatelessWidget {
  final FinanceState state;
  const _TableChartView({required this.state});

  @override
  Widget build(BuildContext context) {
    final transactions = state.filteredTransactions.take(15).toList();
    if (transactions.isEmpty) return const _EmptyState();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('DESCRIPTION', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('DATE', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'AMOUNT',
                    style: _tableHeaderStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          t.merchant ?? t.category ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('MMM dd').format(t.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${t.type == TransactionType.debit ? "-" : "+"}Rs.${t.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.type == TransactionType.debit
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF10B981),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF94A3B8),
    letterSpacing: 0.5,
  );
}

class _ComparisonChartView extends StatelessWidget {
  final FinanceState state;
  const _ComparisonChartView({required this.state});

  @override
  Widget build(BuildContext context) {
    final comparison = state.monthlyComparison;
    if (comparison.isEmpty) return const _EmptyState();

    // Take top 5 categories by this month's spending
    final sortedList = comparison.values.toList()
      ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
    final displayList = sortedList.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMax(displayList) * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= displayList.length)
                    return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      displayList[index].category.substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(displayList.length, (index) {
            final item = displayList[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.lastMonth,
                  color: const Color(0xFFE2E8F0),
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                BarChartRodData(
                  toY: item.thisMonth,
                  color: const Color(0xFF1E3A8A),
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _calculateMax(List<CategoryComparison> list) {
    double max = 0;
    for (var item in list) {
      if (item.thisMonth > max) max = item.thisMonth;
      if (item.lastMonth > max) max = item.lastMonth;
    }
    return max;
  }
}

/// Per-column data visualization: Type, Category, Bank, Remark.
class _ColumnAnalyticsView extends StatelessWidget {
  final FinanceState state;
  const _ColumnAnalyticsView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.filteredTransactions.isEmpty) return const _EmptyState();

    final creditTotal = state.filteredTransactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (s, t) => s + t.amount);
    final debitTotal = state.filteredTransactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (s, t) => s + t.amount);
    final typeTotal = creditTotal + debitTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColumnSection(
            title: 'By Type',
            child: typeTotal > 0
                ? Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 0,
                            sections: [
                              PieChartSectionData(
                                color: FinanceTheme.creditColor,
                                value: creditTotal,
                                radius: 32,
                                title: creditTotal > 0
                                    ? '${(creditTotal / typeTotal * 100).round()}%'
                                    : '',
                                titleStyle: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: FinanceTheme.debitColor,
                                value: debitTotal,
                                radius: 32,
                                title: debitTotal > 0
                                    ? '${(debitTotal / typeTotal * 100).round()}%'
                                    : '',
                                titleStyle: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypeLegendRow(
                            'Credit',
                            creditTotal,
                            FinanceTheme.creditColor,
                          ),
                          _TypeLegendRow(
                            'Debit',
                            debitTotal,
                            FinanceTheme.debitColor,
                          ),
                        ],
                      ),
                    ],
                  )
                : const Text('No data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          const SizedBox(height: 16),
          _ColumnSection(
            title: 'By Category',
            child: state.byCategory.isEmpty
                ? const Text('No data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                : _MiniCategoryLegend(byCategory: state.byCategory),
          ),
          const SizedBox(height: 16),
          _ColumnSection(
            title: 'By Bank / Source',
            child: state.byBankName.isEmpty
                ? const Text('No data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                : _MiniBarList(summaries: state.byBankName.take(5).toList()),
          ),
          const SizedBox(height: 16),
          _ColumnSection(
            title: 'By Title',
            child: state.byTitle.isEmpty
                ? const Text('No data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                : _MiniBarList(summaries: state.byTitle.take(5).toList()),
          ),
          const SizedBox(height: 16),
          _ColumnSection(
            title: 'By Remark',
            child: state.byRemark.isEmpty
                ? const Text('No data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                : _MiniBarList(summaries: state.byRemark.take(5).toList()),
          ),
        ],
      ),
    );
  }
}

class _ColumnSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ColumnSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TypeLegendRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TypeLegendRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ${NumberFormat.compact().format(value)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _MiniCategoryLegend extends StatelessWidget {
  final Map<String, double> byCategory;

  const _MiniCategoryLegend({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: entries.take(5).map((e) {
        final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: FinanceTheme.getCategoryColor(e.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniBarList extends StatelessWidget {
  final List<MerchantSummary> summaries;

  const _MiniBarList({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final maxTotal = summaries.isEmpty
        ? 1.0
        : summaries.map((s) => s.total).reduce((a, b) => a > b ? a : b);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: summaries.map((s) {
        final width = maxTotal > 0 ? (s.total / maxTotal) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  s.name,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: width.clamp(0.0, 1.0),
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                NumberFormat.compact().format(s.total),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class FractionallySizedBox extends StatelessWidget {
  final double widthFactor;
  final Widget child;

  const FractionallySizedBox({
    Key? key,
    required this.widthFactor,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth * widthFactor,
          child: child,
        );
      },
    );
  }
}

class _ReportView extends StatelessWidget {
  final FinanceState state;
  const _ReportView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.transactions.isEmpty) return const _EmptyState();

    final weekly = _weeklyDebitLast8Weeks(state.transactions);
    final months = state.balanceTrendMonthly;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export PDF reports',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _generateReport(context, state, weekly: true),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: const Text('Weekly report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _generateReport(context, state, weekly: false),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: const Text('Month-end report'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Week-wise spending',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weekly.isEmpty
                    ? 1
                    : weekly.map((e) => e.$2).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= weekly.length) return const SizedBox.shrink();
                        final start = weekly[i].$1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMMd').format(start),
                            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(weekly.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weekly[i].$2,
                        color: FinanceTheme.debitColor.withOpacity(0.85),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Month-wise credit vs debit',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (months.isEmpty)
            const _EmptyState()
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          NumberFormat.compact().format(value),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= months.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('MMM').format(months[i].month),
                              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(months.length, (i) {
                    final m = months[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: m.debit,
                          color: FinanceTheme.debitColor.withOpacity(0.65),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: m.credit,
                          color: FinanceTheme.creditColor.withOpacity(0.85),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<(DateTime, double)> _weeklyDebitLast8Weeks(List<Transaction> txns) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

    final result = <(DateTime, double)>[];
    for (int w = 7; w >= 0; w--) {
      final start = thisWeekStart.subtract(Duration(days: 7 * w));
      final end = start.add(const Duration(days: 6));
      double sum = 0;
      for (final t in txns) {
        if (t.type != TransactionType.debit) continue;
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        if (d.isBefore(start) || d.isAfter(end)) continue;
        sum += t.amount;
      }
      result.add((start, sum));
    }
    return result;
  }
}

Future<void> _generateReport(
  BuildContext context,
  FinanceState state, {
  required bool weekly,
}) async {
  final now = DateTime.now();
  late DateTime rangeStart;
  late DateTime rangeEnd;
  late String title;
  if (weekly) {
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    rangeStart = weekStart;
    rangeEnd = weekStart.add(const Duration(days: 6));
    title = 'Artha – Weekly report';
  } else {
    rangeStart = DateTime(now.year, now.month, 1);
    rangeEnd = DateTime(now.year, now.month + 1, 0);
    title = 'Artha – Month-end report';
  }
  try {
    final bytes = await FinanceReportPdfService.buildReport(
      transactions: state.transactions,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      reportTitle: title,
    );
    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  const _TransactionListItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          CategoryIcon.build(category: transaction.category, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchant ?? transaction.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? "+" : "-"}Rs. ${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isCredit
                  ? const Color(0xFF10B981)
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Insufficient data for visualization',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
    );
  }
}
