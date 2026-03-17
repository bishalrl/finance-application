import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../bloc/home_event.dart';
import '../../../10_finance/presentation/widgets/finance_dashboard_content.dart';
import '../../../10_finance/presentation/pages/finance_page.dart';
import '../../../10_finance/presentation/pages/transactions_page.dart';
import '../../../10_finance/presentation/pages/finance_calendar_page.dart';
import '../../../10_finance/presentation/pages/finance_data_manager_page.dart';
import '../../../10_finance/presentation/bloc/finance_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _ChartTab(),
      const _FiltersTab(),
      const _CalendarTab(),
      const _SheetTab(),
    ];

    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) =>
          previous.selectedIndex != current.selectedIndex,
      builder: (context, state) {
        return Scaffold(
          body: pages[state.selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.selectedIndex,
            onDestinationSelected: (index) {
              context.read<HomeBloc>().add(ChangeTab(index));
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Chart',
              ),
              NavigationDestination(
                icon: Icon(Icons.filter_list_rounded),
                selectedIcon: Icon(Icons.filter_list_rounded),
                label: 'Filters',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_rounded),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.table_chart_rounded),
                selectedIcon: Icon(Icons.table_chart_rounded),
                label: 'Sheet',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartTab extends StatelessWidget {
  const _ChartTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<FinanceBloc>(),
                    child: const FinancePage(),
                  ),
                ),
              );
            },
            tooltip: 'All views',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const FinanceDashboardContent(),
    );
  }
}

class _FiltersTab extends StatelessWidget {
  const _FiltersTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: BlocProvider.value(
        value: context.read<FinanceBloc>(),
        child: const TransactionsPage(embedded: true),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: BlocProvider.value(
        value: context.read<FinanceBloc>(),
        child: const FinanceCalendarPage(embedded: true),
      ),
    );
  }
}

class _SheetTab extends StatelessWidget {
  const _SheetTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: BlocProvider.value(
        value: context.read<FinanceBloc>(),
        child: const FinanceDataManagerPage(embedded: true),
      ),
    );
  }
}
