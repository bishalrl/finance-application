import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_state.dart';
import '../bloc/finance_event.dart';
import '../../domain/entities/transaction.dart';
import 'add_transaction_page.dart';

class FinanceDataManagerPage extends StatefulWidget {
  final bool embedded;
  const FinanceDataManagerPage({super.key, this.embedded = false});

  @override
  State<FinanceDataManagerPage> createState() => _FinanceDataManagerPageState();
}

class _FinanceDataManagerPageState extends State<FinanceDataManagerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<FinanceBloc, FinanceState>(
      buildWhen: (p, c) => p.status != c.status || p.transactions != c.transactions,
      builder: (context, state) {
        if (state.status == FinanceStatus.loading && state.transactions.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final txns = state.transactions;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: widget.embedded ? null : AppBar(title: const Text('Sheet')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.read<FinanceBloc>().add(const ReAnalyzeTransactions());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-analyzing all messages...')),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Re-Sync Data'),
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          body: txns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.table_rows_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No transactions found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openAddTransaction(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add transaction'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: const Color(0xFFF1F5F9),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Total: ${txns.length} records found in local storage.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _openAddTransaction(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add transaction'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Re-import only adds new transactions; existing data is never removed even if you delete SMS.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.grey.shade200),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              horizontalMargin: 16,
                              headingRowHeight: 48,
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 80,
                              headingRowColor: MaterialStateProperty.all(
                                const Color(0xFFF8FAFC),
                              ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                                fontSize: 13,
                              ),
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                              ),
                              columns: const [
                                DataColumn(label: Text('PROVIDER')),
                                DataColumn(label: Text('MESSAGE / SMS')),
                                DataColumn(label: Text('AMOUNT')),
                                DataColumn(label: Text('REMARK')),
                                DataColumn(label: Text('')),
                              ],
                              rows: txns.map((t) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          t.bankName ?? t.sourceKey ?? 'SMS',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: InkWell(
                                          onLongPress: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: t.rawMessage ?? '',
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Message copied'),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            t.rawMessage ?? t.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blueGrey.shade700,
                                              height: 1.3,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        'Rs ${t.amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color:
                                              t.type == TransactionType.credit
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          t.userRemark ??
                                              t.rawRemark ??
                                              t.systemRemark ??
                                              'Tap to edit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: (t.userRemark == null)
                                                ? Colors.grey
                                                : Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      showEditIcon: true,
                                      onTap: () => _editRemark(context, t),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_sweep_rounded,
                                          size: 20,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _confirmDelete(context, t),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => BlocProvider.value(
          value: context.read<FinanceBloc>(),
          child: const AddTransactionPage(),
        ),
      ),
    );
  }

  void _editRemark(BuildContext context, Transaction transaction) {
    // Exact same logic as before...
    final controller = TextEditingController(
      text: transaction.userRemark ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Remark'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FinanceBloc>().add(
                UpdateTransactionRemark(transaction.id, controller.text.trim()),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('Remove this transaction record permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<FinanceBloc>().add(
                DeleteTransaction(transaction.id),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }
}
