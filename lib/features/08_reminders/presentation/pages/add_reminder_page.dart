import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/add_reminder_bloc.dart';
import '../bloc/reminder_bloc.dart';

class AddReminderPage extends StatelessWidget {
  const AddReminderPage({super.key});

  String _typeLabel(ReminderType t) {
    switch (t) {
      case ReminderType.billPayment:
        return 'Bill payment';
      case ReminderType.documentExpiry:
        return 'Document expiry';
      case ReminderType.subscription:
        return 'Subscription';
      case ReminderType.custom:
        return 'Custom';
      case ReminderType.none:
        return 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (context) => AddReminderBloc(
        createReminder: context.read(),
        reminderBloc: context.read<ReminderBloc>(),
      )..add(ResetAddReminderState()),
      child: BlocConsumer<AddReminderBloc, AddReminderState>(
        listener: (context, state) {
          if (state is AddReminderSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder added')));
            Navigator.of(context).pop(true);
          } else if (state is AddReminderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          final addReminderState = state is AddReminderInitial ? state : AddReminderInitial();

          return Scaffold(
            appBar: AppBar(
              title: Text('Add Reminder', style: TextStyle(fontSize: screenWidth * 0.05)),
              actions: [
                TextButton(
                  onPressed: addReminderState.isSubmitting ? null : () => context.read<AddReminderBloc>().add(SubmitReminder()),
                  child: addReminderState.isSubmitting
                      ? SizedBox(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: TextEditingController(text: addReminderState.title),
                    onChanged: (value) => context.read<AddReminderBloc>().add(TitleChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Reminder title',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: TextEditingController(text: addReminderState.description),
                    onChanged: (value) => context.read<AddReminderBloc>().add(DescriptionChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Details',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    maxLines: 2,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ListTile(
                    title: Text('Date & Time', style: TextStyle(fontSize: screenWidth * 0.045)),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(addReminderState.reminderDate),
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    trailing: Icon(Icons.calendar_today, size: screenWidth * 0.06),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: addReminderState.reminderDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        if (context.mounted) {
                          context.read<AddReminderBloc>().add(DateChanged(date));
                        }
                      }
                      if (context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(addReminderState.reminderDate),
                        );
                        if (time != null) {
                          if (context.mounted) {
                            context.read<AddReminderBloc>().add(TimeChanged(time));
                          }
                        }
                      }
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  DropdownButtonFormField<ReminderType>(
                    value: addReminderState.type,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    items: ReminderType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t), style: TextStyle(fontSize: screenWidth * 0.04))))
                        .toList(),
                    onChanged: (v) => context.read<AddReminderBloc>().add(TypeChanged(v ?? ReminderType.custom)),
                  ),
                  if (addReminderState.errorMessage != null) ...[
                    SizedBox(height: screenHeight * 0.02),
                    Text(addReminderState.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: screenWidth * 0.04)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
