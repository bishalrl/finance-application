import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/transaction.dart';

/// Builds PDF reports for a date range: by date, title, category, remark.
class FinanceReportPdfService {
  /// [transactions] should already be filtered to the desired range (or pass all and we filter by [rangeStart]/[rangeEnd]).
  static Future<Uint8List> buildReport({
    required List<Transaction> transactions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required String reportTitle,
  }) async {
    final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(
      rangeEnd.year,
      rangeEnd.month,
      rangeEnd.day,
      23,
      59,
      59,
    );
    final list = transactions
        .where((t) =>
            !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();

    // Aggregations
    final byDate = _byDate(list);
    final byTitle = _byTitle(list);
    final byCategory = _byCategory(list);
    final byRemark = _byRemark(list);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${_fmt(start)} – ${_fmt(end)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),
            _section('By Date', _dateTable(byDate)),
            pw.SizedBox(height: 16),
            _section('By Title (Bank/Source)', _summaryTable(byTitle)),
            pw.SizedBox(height: 16),
            _section('By Category', _categoryTable(byCategory)),
            pw.SizedBox(height: 16),
            _section('By Remark', _summaryTable(byRemark)),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static Map<String, double> _byDate(List<Transaction> list) {
    final map = <String, double>{};
    for (final t in list) {
      final key = _fmt(t.date);
      map[key] = (map[key] ?? 0) + t.amount;
    }
    final sorted = map.keys.toList()..sort((a, b) => a.compareTo(b));
    return {for (final k in sorted) k: map[k]!};
  }

  static List<({String name, double total, int count})> _byTitle(List<Transaction> list) {
    final map = <String, List<Transaction>>{};
    for (final t in list) {
      final name = (t.title ?? t.bankName ?? t.sourceKey ?? t.sender ?? 'Unknown').trim();
      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map((e) => (name: e.key, total: e.value.fold(0.0, (s, t) => s + t.amount), count: e.value.length))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  static Map<String, double> _byCategory(List<Transaction> list) {
    final map = <String, double>{};
    for (final t in list) {
      if (t.type == TransactionType.debit) {
        final cat = t.category ?? 'Other';
        map[cat] = (map[cat] ?? 0) + t.amount;
      }
    }
    return map;
  }

  static List<({String name, double total, int count})> _byRemark(List<Transaction> list) {
    final map = <String, List<Transaction>>{};
    for (final t in list) {
      if (t.type != TransactionType.debit) continue;
      final name = (t.displayRemark ?? t.description).trim();
      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map((e) => (name: e.key, total: e.value.fold(0.0, (s, t) => s + t.amount), count: e.value.length))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  static pw.Widget _section(String title, pw.Widget child) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        child,
      ],
    );
  }

  static pw.Widget _dateTable(Map<String, double> byDate) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Date', isHeader: true),
          _cell('Total (Rs)', isHeader: true),
        ],
      ),
      ...byDate.entries.map((e) => pw.TableRow(
            children: [
              _cell(e.key),
              _cell(e.value.toStringAsFixed(2)),
            ],
          )),
    ];
    if (rows.length == 1) {
      rows.add(pw.TableRow(children: [_cell('No data'), _cell('–')]));
    }
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1.5)},
      children: rows,
    );
  }

  static pw.Widget _summaryTable(List<({String name, double total, int count})> items) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Name', isHeader: true),
          _cell('Count', isHeader: true),
          _cell('Total (Rs)', isHeader: true),
        ],
      ),
      ...items.take(30).map((e) => pw.TableRow(
            children: [
              _cell(_truncate(e.name, 40)),
              _cell('${e.count}'),
              _cell(e.total.toStringAsFixed(2)),
            ],
          )),
    ];
    if (rows.length == 1) {
      rows.add(pw.TableRow(children: [_cell('No data'), _cell('–'), _cell('–')]));
    }
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(0.8), 2: const pw.FlexColumnWidth(1.5)},
      children: rows,
    );
  }

  static pw.Widget _categoryTable(Map<String, double> byCategory) {
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Category', isHeader: true),
          _cell('Total (Rs)', isHeader: true),
          _cell('%', isHeader: true),
        ],
      ),
      ...byCategory.entries.map((e) {
        final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
        return pw.TableRow(
          children: [
            _cell(e.key),
            _cell(e.value.toStringAsFixed(2)),
            _cell('$pct%'),
          ],
        );
      }),
    ];
    if (rows.length == 1) {
      rows.add(pw.TableRow(children: [_cell('No data'), _cell('–'), _cell('–')]));
    }
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1.5), 2: const pw.FlexColumnWidth(0.8)},
      children: rows,
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: isHeader ? 9 : 8, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}…';
  }
}
