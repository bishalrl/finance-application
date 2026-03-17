import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import 'transactions_page.dart';

class FilteredTransactionsPage extends StatefulWidget {
  final String title;
  final TransactionType? type;
  final String? category;
  final DateTime? from;
  final DateTime? to;

  const FilteredTransactionsPage({
    super.key,
    required this.title,
    this.type,
    this.category,
    this.from,
    this.to,
  });

  @override
  State<FilteredTransactionsPage> createState() => _FilteredTransactionsPageState();
}

class _FilteredTransactionsPageState extends State<FilteredTransactionsPage> {
  late final FinanceBloc _bloc;
  TransactionType? _prevType;
  String? _prevCategory;
  DateTime? _prevFrom;
  DateTime? _prevTo;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<FinanceBloc>();
    final s = _bloc.state;
    _prevType = s.filterType;
    _prevCategory = s.filterCategory;
    _prevFrom = s.filterDateFrom;
    _prevTo = s.filterDateTo;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc.add(FilterByType(widget.type));
      _bloc.add(FilterByCategory(widget.category));
      _bloc.add(SetDateRangeFilter(from: widget.from, to: widget.to));
    });
  }

  @override
  void dispose() {
    _bloc.add(FilterByType(_prevType));
    _bloc.add(FilterByCategory(_prevCategory));
    _bloc.add(SetDateRangeFilter(from: _prevFrom, to: _prevTo));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: subtitle == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
      ),
      body: const TransactionsPage(embedded: true),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  String? _subtitle() {
    if (widget.from == null && widget.to == null && widget.category == null && widget.type == null) {
      return null;
    }
    final parts = <String>[];
    if (widget.type != null) {
      parts.add(widget.type == TransactionType.credit ? 'Credit' : 'Debit');
    }
    if (widget.category != null && widget.category!.isNotEmpty) {
      parts.add(widget.category!);
    }
    if (widget.from != null && widget.to != null) {
      parts.add('${DateFormat.yMMMd().format(widget.from!)} → ${DateFormat.yMMMd().format(widget.to!)}');
    }
    return parts.join(' • ');
  }
}

