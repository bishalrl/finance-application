import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../widgets/sms_permission_dialog.dart';
import 'transactions_page.dart';
import 'finance_summary_page.dart';

/// Simple dashboard — visual but calm. No red panic, no "you overspent" language. Awareness, not control.
class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text('Finance', style: TextStyle(fontSize: screenWidth * 0.05))),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage && c.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state.status == FinanceStatus.loading && state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final credit = state.totalCredit;
          final debit = state.totalDebit;

          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Where your money went — roughly.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: screenWidth * 0.045,
                      ),
                ),
                SizedBox(height: screenHeight * 0.025),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Received',
                        amount: credit,
                        color: const Color(0xFF10B981),
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Spent',
                        amount: debit,
                        color: const Color(0xFF6366F1),
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await SmsPermissionDialog.show(context);
                    if (ok == true && context.mounted) {
                      context.read<FinanceBloc>().add(const ParseSmsTransactionsEvent());
                    }
                  },
                  icon: Icon(Icons.sms, size: screenWidth * 0.05),
                  label: Text('Import from SMS', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Reads bank/wallet/UPI alerts on device. Only extracted amounts and dates are saved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: screenWidth * 0.035,
                      ),
                ),
                SizedBox(height: screenHeight * 0.03),
                ListTile(
                  leading: Icon(Icons.list_alt, size: screenWidth * 0.06),
                  title: Text('Transactions', style: TextStyle(fontSize: screenWidth * 0.045)),
                  subtitle: Text('${state.transactions.length} items', style: TextStyle(fontSize: screenWidth * 0.035)),
                  trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<FinanceBloc>(),
                        child: const TransactionsPage(),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.calendar_month, size: screenWidth * 0.06),
                  title: Text('Monthly summary', style: TextStyle(fontSize: screenWidth * 0.045)),
                  trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<FinanceBloc>(),
                        child: const FinanceSummaryPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: screenWidth * 0.05, color: color),
                SizedBox(width: screenWidth * 0.02),
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontSize: screenWidth * 0.04)),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.06),
            ),
          ],
        ),
      ),
    );
  }
}
