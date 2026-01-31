import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';
import 'add_reminder_page.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders', style: TextStyle(fontSize: screenWidth * 0.05)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: screenWidth * 0.06),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<ReminderBloc>(),
                  child: const AddReminderPage(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ReminderListStatus.loading && state.reminders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ReminderListStatus.error && state.reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.errorMessage ?? 'Failed to load', textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () => context.read<ReminderBloc>().add(const LoadReminders()),
                      child: Text('Retry', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: screenWidth * 0.15, color: Theme.of(context).colorScheme.outline),
                  SizedBox(height: screenHeight * 0.02),
                  Text('No reminders yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: screenWidth * 0.05)),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Set your first reminder',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: screenWidth * 0.04,
                        ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<ReminderBloc>(),
                          child: const AddReminderPage(),
                        ),
                      ),
                    ),
                    icon: Icon(Icons.add, size: screenWidth * 0.05),
                    label: Text('Add Reminder', style: TextStyle(fontSize: screenWidth * 0.04)),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReminderBloc>().add(const LoadReminders());
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.04),
              itemCount: state.reminders.length,
              itemBuilder: (context, index) {
                final reminder = state.reminders[index];
                return _ReminderCard(
                  reminder: reminder,
                  onComplete: () => context.read<ReminderBloc>().add(MarkReminderCompleteEvent(reminder.id)),
                  onDelete: () => _confirmDelete(context, reminder),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<ReminderBloc, ReminderState>(
        buildWhen: (p, c) => c.reminders.isNotEmpty,
        builder: (context, state) {
          if (state.reminders.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<ReminderBloc>(),
                  child: const AddReminderPage(),
                ),
              ),
            ),
            child: Icon(Icons.add, size: screenWidth * 0.06),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Reminder reminder) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete reminder?', style: TextStyle(fontSize: screenWidth * 0.05)),
        content: Text('"${reminder.title}" will be deleted.', style: TextStyle(fontSize: screenWidth * 0.04)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04))),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('Delete', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ReminderBloc>().add(DeleteReminderEvent(reminder.id));
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
          radius: screenWidth * 0.06,
          child: Icon(
            reminder.isCompleted ? Icons.check_circle : Icons.notifications_outlined,
            color: const Color(0xFF10B981),
            size: screenWidth * 0.07,
          ),
        ),
        title: Text(
          reminder.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (reminder.isCompleted ? TextStyle(decoration: TextDecoration.lineThrough, color: Theme.of(context).colorScheme.outline) : null)?.copyWith(fontSize: screenWidth * 0.045),
        ),
        subtitle: Text(
          _formatDate(reminder.reminderDate),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
          onSelected: (value) {
            if (value == 'complete') onComplete();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (!reminder.isCompleted) PopupMenuItem(value: 'complete', child: Text('Mark complete', style: TextStyle(fontSize: screenWidth * 0.04))),
            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: screenWidth * 0.04))),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
