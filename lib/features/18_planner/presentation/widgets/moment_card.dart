import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_moment.dart';

/// Soft card for a planner moment. No checkboxes, neutral colors.
class MomentCard extends StatelessWidget {
  final PlannerMoment moment;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onSnooze;

  const MomentCard({
    super.key,
    required this.moment,
    this.onTap,
    this.onAcknowledge,
    this.onSnooze,
  });

  static String _typeSubtext(MomentType type) {
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
    final isPast = moment.status == MomentStatus.past || moment.isPast;
    final opacity = isPast ? 0.7 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moment.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _typeSubtext(moment.type) +
                                (moment.amount != null && moment.type == MomentType.bill
                                    ? ' · ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(moment.amount)}'
                                    : ''),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (moment.note != null && moment.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              moment.note!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(moment.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final momentDay = DateTime(date.year, date.month, date.day);
    if (momentDay == today) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.MMMd().format(date);
  }
}
