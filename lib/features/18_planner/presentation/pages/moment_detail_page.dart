import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_moment.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';

/// Detail view for a moment. Tap to reflect; add note after the fact. No guilt language.
class MomentDetailPage extends StatelessWidget {
  final PlannerMoment moment;

  const MomentDetailPage({super.key, required this.moment});

  static String _typeLabel(MomentType type) {
    switch (type) {
      case MomentType.event:
        return 'Event';
      case MomentType.bill:
        return 'Bill';
      case MomentType.milestone:
        return 'Milestone';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = moment.isPast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              context.read<PlannerBloc>().add(AcknowledgeMomentEvent(moment.id));
              Navigator.of(context).pop();
            },
            tooltip: 'Acknowledge',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove moment?'),
                  content: const Text('This will remove the moment. You can add a new one anytime.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<PlannerBloc>().add(DeleteMomentEvent(moment.id));
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Remove',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              moment.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _typeLabel(moment.type) +
                  (moment.amount != null && moment.type == MomentType.bill
                      ? ' · ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(moment.amount)}'
                      : ''),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().add_jm().format(moment.date),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (moment.dateEnd != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 26),
                  Text(
                    'to ${DateFormat.yMMMd().add_jm().format(moment.dateEnd!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (moment.reminderAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.notifications, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Reminder: ${DateFormat.yMMMd().add_jm().format(moment.reminderAt!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (moment.note != null && moment.note!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Note',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                moment.note!,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (isPast) ...[
              const SizedBox(height: 24),
              Text(
                'This moment has passed. You can reflect or add a note anytime.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
