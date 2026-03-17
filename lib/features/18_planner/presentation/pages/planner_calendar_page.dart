import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';
import '../bloc/planner_state.dart';
import '../widgets/moment_card.dart';
import 'moment_detail_page.dart';

/// Calendar view: select a date to see that day's moments. Minimal, no heatmaps.
class PlannerCalendarPage extends StatefulWidget {
  const PlannerCalendarPage({super.key});

  @override
  State<PlannerCalendarPage> createState() => _PlannerCalendarPageState();
}

class _PlannerCalendarPageState extends State<PlannerCalendarPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      context.read<PlannerBloc>().add(LoadMomentsForDay(today));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<PlannerBloc, PlannerState>(
        buildWhen: (prev, curr) =>
            prev.selectedDay != curr.selectedDay ||
            prev.selectedDayMoments != curr.selectedDayMoments ||
            prev.status != curr.status,
        builder: (context, state) {
          final selected = state.selectedDay ?? DateTime.now();
          return Column(
            children: [
              _buildMonthStrip(selected),
              Expanded(
                child: () {
                  if (state.status == PlannerStatus.loading && state.selectedDayMoments.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.selectedDayMoments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No moments on ${DateFormat.MMMd().format(selected)}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.selectedDayMoments.length,
                    itemBuilder: (context, index) {
                      final moment = state.selectedDayMoments[index];
                      return MomentCard(
                        moment: moment,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: context.read<PlannerBloc>(),
                              child: MomentDetailPage(moment: moment),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthStrip(DateTime selected) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month + 2, 0);
    final days = <DateTime>[];
    for (var d = start;
        d.isBefore(end) || d.isAtSameMomentAs(end);
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              DateFormat('MMMM yyyy').format(selected),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final d = days[index];
                final isSelected = d.year == selected.year &&
                    d.month == selected.month &&
                    d.day == selected.day;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        context.read<PlannerBloc>().add(LoadMomentsForDay(d));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 44,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(d),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${d.day}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
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
        ],
      ),
    );
  }
}
