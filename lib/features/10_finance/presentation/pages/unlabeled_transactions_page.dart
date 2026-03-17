import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_state.dart';
import '../widgets/category_icon.dart';

class UnlabeledTransactionsPage extends StatelessWidget {
  const UnlabeledTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Needs Attention'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        buildWhen: (p, c) =>
            p.status != c.status || p.unlabeledTransactions != c.unlabeledTransactions,
        builder: (context, state) {
          if (state.status == FinanceStatus.loading &&
              state.unlabeledTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = state.unlabeledTransactions;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 80,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All caught up!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All your transactions are labeled.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CategoryIcon.build(category: 'Other', size: 40),
                  title: Text(
                    t.merchant ?? t.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Rs. ${t.amount.toStringAsFixed(0)} • ${t.date.day}/${t.date.month}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      // TODO: Navigate to edit/categorize transaction
                    },
                    child: const Text('Label'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
