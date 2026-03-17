import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_vault/core/config/dependency_injection.dart' as di;
import 'package:life_vault/features/10_finance/data/datasources/sms_parser_datasource.dart';
import 'package:life_vault/features/10_finance/presentation/theme/finance_theme.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../widgets/finance_dashboard_content.dart';
import 'transactions_page.dart';
import 'finance_summary_page.dart';
import 'finance_timeline_page.dart';
import 'finance_calendar_page.dart';
import 'finance_categories_page.dart';
import 'finance_merchants_page.dart';
import 'finance_analytics_dashboard_page.dart';
import 'finance_data_manager_page.dart';

/// Finance hub — horizontally scrollable tab buttons at top,
/// content area below. Clean single-page UX.
class FinancePage extends StatefulWidget {
  const FinancePage({super.key, this.initialTabIndex});

  /// When set, opens this tab on first frame (e.g. 6 = Calendar).
  final int? initialTabIndex;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = <_TabItem>[
    _TabItem(icon: Icons.table_chart_rounded, label: 'Sheet'),
    _TabItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _TabItem(icon: Icons.analytics_rounded, label: 'Analytics'),
    _TabItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    _TabItem(icon: Icons.pie_chart_rounded, label: 'Summary'),
    _TabItem(icon: Icons.timeline_rounded, label: 'Activity'),
    _TabItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
    _TabItem(icon: Icons.category_rounded, label: 'Categories'),
    _TabItem(icon: Icons.store_rounded, label: 'Merchants'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      final next = _tabController.index;
      if (next != context.read<FinanceBloc>().state.financeTabIndex) {
        context.read<FinanceBloc>().add(SetFinanceTabIndex(next));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = widget.initialTabIndex;
      if (idx != null && idx >= 0 && idx < _tabs.length) {
        _tabController.animateTo(idx);
        context.read<FinanceBloc>().add(SetFinanceTabIndex(idx));
      }
      // Defer non-critical SMS tracking so first frame paints quickly.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        di.sl<SmsParserDataSource>().initializeBackgroundTracking();
      });
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
      appBar: AppBar(
        title: const Text('Finance'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildTabBar(context),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _wrapWithBloc(context, const FinanceDataManagerPage(embedded: true)),
          const FinanceDashboardContent(),
          _wrapWithBloc(context, const FinanceAnalyticsDashboardPage()),
          _wrapWithBloc(context, const TransactionsPage(embedded: true)),
          _wrapWithBloc(context, const FinanceSummaryPage(embedded: true)),
          _wrapWithBloc(context, const FinanceTimelinePage(embedded: true)),
          _wrapWithBloc(context, const FinanceCalendarPage(embedded: true)),
          _wrapWithBloc(context, const FinanceCategoriesPage(embedded: true)),
          _wrapWithBloc(context, const FinanceMerchantsPage(embedded: true)),
        ],
      ),
    );
  }

  Widget _wrapWithBloc(BuildContext context, Widget child) {
    return BlocProvider.value(value: context.read<FinanceBloc>(), child: child);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(bottom: 8),
      child: BlocBuilder<FinanceBloc, FinanceState>(
        buildWhen: (p, c) => p.financeTabIndex != c.financeTabIndex,
        builder: (context, state) {
          // Keep controller in sync with bloc state without setState.
          if (_tabController.index != state.financeTabIndex) {
            _tabController.animateTo(state.financeTabIndex);
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: FinanceTheme.pagePadding,
            ),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isSelected = state.financeTabIndex == index;
              return _TabChip(
                icon: tab.icon,
                label: tab.label,
                isSelected: isSelected,
                onTap: () {
                  _tabController.animateTo(index);
                  context.read<FinanceBloc>().add(SetFinanceTabIndex(index));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: isSelected ? primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
