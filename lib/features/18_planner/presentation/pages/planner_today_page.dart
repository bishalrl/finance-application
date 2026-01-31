import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_moment.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';
import '../bloc/planner_state.dart';
import '../widgets/moment_card.dart';
import 'add_moment_page.dart';
import 'moment_detail_page.dart';
import 'planner_calendar_page.dart';

/// Default Planner screen: "Today" view. Calm typography, today's moments as soft cards.
class PlannerTodayPage extends StatelessWidget {
  const PlannerTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            title: const Text('Planner'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _openCalendar(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _openAddMoment(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Today's moments",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
          ),
          BlocConsumer<PlannerBloc, PlannerState>(
            listenWhen: (prev, curr) =>
                prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
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
              if (state.status == PlannerStatus.loading && state.todayMoments.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.status == PlannerStatus.error && state.todayMoments.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.errorMessage ?? 'Something went wrong',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                context.read<PlannerBloc>().add(const LoadTodayMoments()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (state.todayMoments.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No moments today',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add an event, bill, or milestone',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _openAddMoment(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add moment'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final moment = state.todayMoments[index];
                    return Dismissible(
                      key: ValueKey(moment.id),
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      secondaryBackground: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.snooze,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          context.read<PlannerBloc>().add(AcknowledgeMomentEvent(moment.id));
                          return true;
                        }
                        if (direction == DismissDirection.endToStart) {
                          final snoozeAt = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (snoozeAt != null) {
                            final dt = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              snoozeAt.hour,
                              snoozeAt.minute,
                            );
                            context.read<PlannerBloc>().add(SnoozeMomentEvent(moment.id, dt));
                            return true;
                          }
                          return false;
                        }
                        return false;
                      },
                      child: MomentCard(
                        moment: moment,
                        onTap: () => _openDetail(context, moment),
                        onAcknowledge: () =>
                            context.read<PlannerBloc>().add(AcknowledgeMomentEvent(moment.id)),
                        onSnooze: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (t != null && context.mounted) {
                            final dt = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              t.hour,
                              t.minute,
                            );
                            context.read<PlannerBloc>().add(SnoozeMomentEvent(moment.id, dt));
                          }
                        },
                      ),
                    );
                  },
                  childCount: state.todayMoments.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMoment(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddMoment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PlannerBloc>(),
          child: const AddMomentPage(),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, PlannerMoment moment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PlannerBloc>(),
          child: MomentDetailPage(moment: moment),
        ),
      ),
    );
  }

  void _openCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PlannerBloc>(),
          child: const PlannerCalendarPage(),
        ),
      ),
    );
  }
}
