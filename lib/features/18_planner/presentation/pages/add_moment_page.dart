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
  MomentType _type = MomentType.event;
  DateTime _date = DateTime.now();
  DateTime? _dateEnd;
  DateTime? _reminderAt;
  MomentImportance _importance = MomentImportance.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? _date),
    );
    if (!mounted) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
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
    if (_type == MomentType.bill && _amountController.text.trim().isNotEmpty) {
      amount = double.tryParse(_amountController.text.trim());
    }
    context.read<PlannerBloc>().add(CreateMomentEvent(
          type: _type,
          title: title,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          date: _date,
          dateEnd: _dateEnd,
          reminderAt: _reminderAt,
          importance: _importance,
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
              SegmentedButton<MomentType>(
                segments: const [
                  ButtonSegment(value: MomentType.event, label: Text('Event'), icon: Icon(Icons.event)),
                  ButtonSegment(value: MomentType.bill, label: Text('Bill'), icon: Icon(Icons.receipt)),
                  ButtonSegment(value: MomentType.milestone, label: Text('Milestone'), icon: Icon(Icons.flag)),
                ],
                selected: {_type},
                onSelectionChanged: (Set<MomentType> selected) {
                  setState(() => _type = selected.first);
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
              if (_type == MomentType.bill) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (optional)',
                    hintText: '0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
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
                subtitle: Text(
                  '${_date.day}/${_date.month}/${_date.year} ${_date.hour}:${_date.minute.toString().padLeft(2, '0')}',
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
                subtitle: Text(
                  _reminderAt != null
                      ? '${_reminderAt!.day}/${_reminderAt!.month}/${_reminderAt!.year} ${_reminderAt!.hour}:${_reminderAt!.minute.toString().padLeft(2, '0')}'
                      : 'None',
                ),
                trailing: Icon(_reminderAt != null ? Icons.notifications : Icons.notifications_none),
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
              SegmentedButton<MomentImportance>(
                segments: const [
                  ButtonSegment(value: MomentImportance.low, label: Text('Low')),
                  ButtonSegment(value: MomentImportance.normal, label: Text('Normal')),
                  ButtonSegment(value: MomentImportance.high, label: Text('High')),
                ],
                selected: {_importance},
                onSelectionChanged: (Set<MomentImportance> selected) {
                  setState(() => _importance = selected.first);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
