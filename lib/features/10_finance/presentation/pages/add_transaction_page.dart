import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/finance_category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../theme/finance_theme.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = context.read<FinanceBloc>().state.addTxnDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      context.read<FinanceBloc>().add(SetAddTxnDate(picked));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a description')),
      );
      return;
    }
    context.read<FinanceBloc>().add(const SetAddTxnSubmitted(true));
    final ui = context.read<FinanceBloc>().state;
    final type = ui.addTxnType == AddTransactionTypeUi.credit
        ? TransactionType.credit
        : TransactionType.debit;
    context.read<FinanceBloc>().add(
          AddTransactionRequested(
            amount: amount,
            type: type,
            description: description,
            category: ui.addTxnCategory,
            date: ui.addTxnDate,
            merchant: _merchantController.text.trim().isEmpty
                ? null
                : _merchantController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listenWhen: (p, c) =>
            p.status != c.status || p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.addTxnSubmitted && state.status == FinanceStatus.loaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction added')),
            );
            context.read<FinanceBloc>().add(const SetAddTxnSubmitted(false));
            Navigator.of(context).pop();
            return;
          }
          if (state.status == FinanceStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == FinanceStatus.loading;
          final selectedType = state.addTxnType == AddTransactionTypeUi.credit
              ? TransactionType.credit
              : TransactionType.debit;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(FinanceTheme.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Amount',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: '$kCurrencySymbol ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'Type',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.debit,
                        label: Text('Debit'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: TransactionType.credit,
                        label: Text('Credit'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (s) {
                      context.read<FinanceBloc>().add(
                            SetAddTxnType(
                              s.first == TransactionType.credit
                                  ? AddTransactionTypeUi.credit
                                  : AddTransactionTypeUi.debit,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'Date',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat.yMMMd().format(state.addTxnDate)),
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'Description',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'What was this for?',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'Category',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  DropdownButtonFormField<String>(
                    value: state.addTxnCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Optional'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ...kFinanceCategories.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (v) => context.read<FinanceBloc>().add(SetAddTxnCategory(v)),
                  ),
                  const SizedBox(height: FinanceTheme.gapSection),
                  Text(
                    'Merchant / Payee',
                    style: FinanceTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: FinanceTheme.gapBetweenCards),
                  TextFormField(
                    controller: _merchantController,
                    decoration: const InputDecoration(
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Transaction'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
