import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/planner_moment.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';
import '../bloc/planner_state.dart';

class AddMomentPage extends StatefulWidget {
  const AddMomentPage({super.key});

  @override
  State<AddMomentPage> createState() => _AddMomentPageState();
}

class _AddMomentPageState extends State<AddMomentPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  final ValueNotifier<MomentType> _type = ValueNotifier<MomentType>(MomentType.event);
  final ValueNotifier<DateTime> _date = ValueNotifier<DateTime>(DateTime.now());
  DateTime? _dateEnd;
  final ValueNotifier<DateTime?> _reminderAt = ValueNotifier<DateTime?>(null);
  final ValueNotifier<MomentImportance> _importance =
      ValueNotifier<MomentImportance>(MomentImportance.normal);

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    _type.dispose();
    _date.dispose();
    _reminderAt.dispose();
    _importance.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date.value),
    );
    if (!mounted) return;
    _date.value = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt.value ?? _date.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt.value ?? _date.value),
    );
    if (!mounted) return;
    _reminderAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    double? amount;
    if (_type.value == MomentType.bill &&
        _amountController.text.trim().isNotEmpty) {
      amount = double.tryParse(_amountController.text.trim());
    }
    context.read<PlannerBloc>().add(CreateMomentEvent(
          type: _type.value,
          title: title,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          date: _date.value,
          dateEnd: _dateEnd,
          reminderAt: _reminderAt.value,
          importance: _importance.value,
          amount: amount,
        ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moment added')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlannerBloc, PlannerState>(
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add moment'),
          actions: [
            TextButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Type'),
              const SizedBox(height: 8),
              ValueListenableBuilder<MomentType>(
                valueListenable: _type,
                builder: (context, currentType, _) {
                  return SegmentedButton<MomentType>(
                    segments: const [
                      ButtonSegment(
                          value: MomentType.event,
                          label: Text('Event'),
                          icon: Icon(Icons.event)),
                      ButtonSegment(
                          value: MomentType.bill,
                          label: Text('Bill'),
                          icon: Icon(Icons.receipt)),
                      ButtonSegment(
                          value: MomentType.milestone,
                          label: Text('Milestone'),
                          icon: Icon(Icons.flag)),
                    ],
                    selected: {currentType},
                    onSelectionChanged: (Set<MomentType> selected) {
                      _type.value = selected.first;
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What matters',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              ValueListenableBuilder<MomentType>(
                valueListenable: _type,
                builder: (context, currentType, _) {
                  if (currentType != MomentType.bill) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (optional)',
                          hintText: '0',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'A few words',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Date & time'),
                subtitle: ValueListenableBuilder<DateTime>(
                  valueListenable: _date,
                  builder: (context, date, _) {
                    final minute = date.minute.toString().padLeft(2, '0');
                    return Text(
                      '${date.day}/${date.month}/${date.year} ${date.hour}:$minute',
                    );
                  },
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Reminder (optional)'),
                subtitle: ValueListenableBuilder<DateTime?>(
                  valueListenable: _reminderAt,
                  builder: (context, reminder, _) {
                    if (reminder == null) return const Text('None');
                    final minute = reminder.minute.toString().padLeft(2, '0');
                    return Text(
                      '${reminder.day}/${reminder.month}/${reminder.year} ${reminder.hour}:$minute',
                    );
                  },
                ),
                trailing: ValueListenableBuilder<DateTime?>(
                  valueListenable: _reminderAt,
                  builder: (context, reminder, _) {
                    return Icon(
                      reminder != null
                          ? Icons.notifications
                          : Icons.notifications_none,
                    );
                  },
                ),
                onTap: _pickReminder,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Importance (optional)'),
              const SizedBox(height: 8),
              ValueListenableBuilder<MomentImportance>(
                valueListenable: _importance,
                builder: (context, level, _) {
                  return SegmentedButton<MomentImportance>(
                    segments: const [
                      ButtonSegment(
                          value: MomentImportance.low, label: Text('Low')),
                      ButtonSegment(
                          value: MomentImportance.normal,
                          label: Text('Normal')),
                      ButtonSegment(
                          value: MomentImportance.high, label: Text('High')),
                    ],
                    selected: {level},
                    onSelectionChanged: (Set<MomentImportance> selected) {
                      _importance.value = selected.first;
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
