import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/time_period.dart';

enum FinanceStatus { initial, loading, loaded, error }

// ─── Helper classes for computed getters ─────────────────────────────────────

/// Finance UI-only grouping choice for charts/tables.
enum FinanceGroupByColumn { date, title, category, remark }

/// Finance flow detail period (Received/Spent details filters).
enum FinanceFlowPeriodUi { thisWeek, thisMonth, allTime }

/// Add transaction form state (UI-only).
enum AddTransactionTypeUi { credit, debit }

/// Monthly balance snapshot for trend line charts.
class MonthlyBalance {
  final DateTime month;
  final double credit;
  final double debit;
  final double cumulativeBalance;

  const MonthlyBalance({
    required this.month,
    required this.credit,
    required this.debit,
    required this.cumulativeBalance,
  });
}

/// Monthly credit + debit pair for stacked bar charts.
class CreditDebitPair {
  final double credit;
  final double debit;

  const CreditDebitPair({required this.credit, required this.debit});

  double get savings => credit - debit;
}

/// Category spend comparison: this month vs last month.
class CategoryComparison {
  final String category;
  final double thisMonth;
  final double lastMonth;
  final double
  changePercent; // positive = spending more, negative = spending less

  const CategoryComparison({
    required this.category,
    required this.thisMonth,
    required this.lastMonth,
    required this.changePercent,
  });
}

/// Rule-based insight card data for the dashboard carousel.
enum InsightKind {
  moneyMirror,
  noSpendDays,
  attentionNeeded,
  spendingPattern,
  forecast,
  categoryShortcut,
}

class InsightData {
  final InsightKind kind;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? categoryFilter;
  final String? merchantFilter;

  const InsightData({
    required this.kind,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.categoryFilter,
    this.merchantFilter,
  });
}

/// One group in timeline (e.g. "Today", "Yesterday", "December 2025").
class TransactionDateGroup extends Equatable {
  final String label;
  final List<Transaction> transactions;

  const TransactionDateGroup({required this.label, required this.transactions});

  @override
  List<Object?> get props => [label, transactions];
}

/// Merchant/payee summary for merchant view.
class MerchantSummary extends Equatable {
  final String name;
  final double total;
  final int count;
  final List<Transaction> transactions;

  const MerchantSummary({
    required this.name,
    required this.total,
    required this.count,
    required this.transactions,
  });

  @override
  List<Object?> get props => [name, total, count, transactions];
}

class FinanceState extends Equatable {
  final FinanceStatus status;
  final List<Transaction> transactions;
  final TransactionType? filterType;
  final String? filterCategory;
  final int? filterYear;
  final int? filterMonth;
  final String? searchQuery;
  final DateTime? filterDateFrom;
  final DateTime? filterDateTo;
  final Map<String, dynamic>? summaryData;
  final TimePeriod summaryPeriod;
  final DateTime summaryDate;
  final String? errorMessage;

  /// Categories user marked as recurring (e.g. Rent, Grocery).
  final Set<String> recurringCategoryLabels;

  // ─── UI-only state (no data duplication) ─────────────────────────────────
  /// Finance hub top tab index (Sheet/Overview/Analytics/...).
  final int financeTabIndex;

  /// Analytics dashboard selected tab (Chart/Pie/Table/Monthly/Columns/Report).
  final int analyticsTabIndex;

  /// True briefly when switching analytics tab (show progress indicator).
  final bool analyticsTabBusy;

  /// Analytics: expanded/collapsed detail section.
  final bool analyticsDetailsExpanded;

  /// Transactions page: toggle between card view and table view.
  final bool transactionsIsTableView;

  /// Transactions table charts: selected “Group by” column.
  final FinanceGroupByColumn transactionsGroupByColumn;

  /// Calendar: selected month (always normalized to first day of month).
  final DateTime calendarSelectedMonth;

  /// Summary: selected time period and focused date.
  final TimePeriod summaryUiPeriod;
  final DateTime summaryUiFocusedDate;

  /// Dashboard carousel current page (for slide counter / dots).
  final int dashboardCarouselPage;

  /// Chart touch interaction: source pie touched index.
  final int sourceBreakdownTouchedIndex;

  /// Chart touch interaction: category pie touched index.
  final int categoryBreakdownTouchedIndex;

  /// Flow detail: selected period (week/month/all). Used by Received/Spent detail pages.
  final FinanceFlowPeriodUi flowDetailPeriod;

  /// Add transaction form (UI-only).
  final AddTransactionTypeUi addTxnType;
  final DateTime addTxnDate;
  final String? addTxnCategory;
  final bool addTxnSubmitted;

  FinanceState({
    this.status = FinanceStatus.initial,
    this.transactions = const [],
    this.filterType,
    this.filterCategory,
    this.filterYear,
    this.filterMonth,
    this.searchQuery,
    this.filterDateFrom,
    this.filterDateTo,
    this.summaryData,
    this.summaryPeriod = TimePeriod.monthly,
    DateTime? summaryDate,
    this.errorMessage,
    Set<String>? recurringCategoryLabels,
    this.financeTabIndex = 0,
    this.analyticsTabIndex = 2,
    this.analyticsTabBusy = false,
    this.analyticsDetailsExpanded = false,
    this.transactionsIsTableView = false,
    this.transactionsGroupByColumn = FinanceGroupByColumn.category,
    DateTime? calendarSelectedMonth,
    this.summaryUiPeriod = TimePeriod.monthly,
    DateTime? summaryUiFocusedDate,
    this.dashboardCarouselPage = 0,
    this.sourceBreakdownTouchedIndex = -1,
    this.categoryBreakdownTouchedIndex = -1,
    this.flowDetailPeriod = FinanceFlowPeriodUi.thisMonth,
    this.addTxnType = AddTransactionTypeUi.debit,
    DateTime? addTxnDate,
    this.addTxnCategory,
    this.addTxnSubmitted = false,
  }) : summaryDate =
           summaryDate ??
           DateTime(DateTime.now().year, DateTime.now().month, 1),
       recurringCategoryLabels = recurringCategoryLabels ?? const {},
       calendarSelectedMonth = DateTime(
         (calendarSelectedMonth ?? DateTime.now()).year,
         (calendarSelectedMonth ?? DateTime.now()).month,
         1,
       ),
       summaryUiFocusedDate = summaryUiFocusedDate ?? DateTime.now(),
       addTxnDate = addTxnDate ?? DateTime.now();

  List<Transaction> get filteredTransactions {
    var list = List<Transaction>.from(transactions);
    if (filterType != null) {
      list = list.where((t) => t.type == filterType).toList();
    }
    if (filterCategory != null && filterCategory!.isNotEmpty) {
      list = list
          .where((t) => (t.category ?? 'Other') == filterCategory)
          .toList();
    }
    if (filterYear != null && filterMonth != null) {
      list = list
          .where(
            (t) => t.date.year == filterYear && t.date.month == filterMonth,
          )
          .toList();
    }
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final q = searchQuery!.trim().toLowerCase();
      list = list.where((t) {
        final title =
            (t.rawRemark ?? t.systemRemark ?? t.merchant ?? t.description)
                .toLowerCase();
        final cat = (t.category ?? '').toLowerCase();
        // Also search in systemRemark if different from title
        final systemRemark = t.systemRemark?.toLowerCase() ?? '';
        return title.contains(q) ||
            (systemRemark.isNotEmpty &&
                systemRemark != title &&
                systemRemark.contains(q)) ||
            cat.contains(q) ||
            t.amount.toString().contains(q);
      }).toList();
    }
    if (filterDateFrom != null) {
      final from = DateTime(
        filterDateFrom!.year,
        filterDateFrom!.month,
        filterDateFrom!.day,
      );
      list = list.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return !d.isBefore(from);
      }).toList();
    }
    if (filterDateTo != null) {
      final to = DateTime(
        filterDateTo!.year,
        filterDateTo!.month,
        filterDateTo!.day,
        23,
        59,
      );
      list = list.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return !d.isAfter(to);
      }).toList();
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalCredit => filteredTransactions
      .where((t) => t.type == TransactionType.credit)
      .fold(0.0, (s, t) => s + t.amount);
  double get totalDebit => filteredTransactions
      .where((t) => t.type == TransactionType.debit)
      .fold(0.0, (s, t) => s + t.amount);
  double get netFlow => totalCredit - totalDebit;

  /// Groups filtered transactions by "Today", "Yesterday", "This week", "December 2025", etc.
  List<TransactionDateGroup> get transactionsGroupedByDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    final groups = <TransactionDateGroup>[];
    final list = filteredTransactions;
    if (list.isEmpty) return groups;

    List<Transaction> currentBatch = [];
    String currentLabel = _dateGroupLabel(
      list.first.date,
      today,
      yesterday,
      weekStart,
    );

    for (final t in list) {
      final label = _dateGroupLabel(t.date, today, yesterday, weekStart);
      if (label != currentLabel) {
        if (currentBatch.isNotEmpty) {
          groups.add(
            TransactionDateGroup(
              label: currentLabel,
              transactions: currentBatch,
            ),
          );
        }
        currentLabel = label;
        currentBatch = [t];
      } else {
        currentBatch.add(t);
      }
    }
    if (currentBatch.isNotEmpty) {
      groups.add(
        TransactionDateGroup(label: currentLabel, transactions: currentBatch),
      );
    }
    return groups;
  }

  static String _dateGroupLabel(
    DateTime d,
    DateTime today,
    DateTime yesterday,
    DateTime weekStart,
  ) {
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    if (!dateOnly.isBefore(weekStart) && dateOnly.isBefore(today))
      return 'This week';
    final monthStart = DateTime(d.year, d.month, 1);
    if (!dateOnly.isBefore(monthStart) && dateOnly.isBefore(weekStart)) {
      return _monthYear(d);
    }
    return _monthYear(d);
  }

  static String _monthYear(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  /// By merchant/payee (debit only for "spending by merchant"; include credit if you want).
  List<MerchantSummary> get byMerchant {
    final map = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      final name =
          (t.merchant ?? t.rawRemark ?? t.systemRemark ?? t.description).trim();
      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// By Sender Address (Debit Only for Spending Visualization)
  List<MerchantSummary> get bySender {
    final map = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      if (t.type != TransactionType.debit) continue;

      // Use Sender ID if available, otherwise fallback to merchant/description logic
      final name = (t.sender ?? t.merchant ?? t.rawRemark ?? t.description)
          .trim();

      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// By display remark (userRemark, rawRemark, systemRemark) — debit only.
  List<MerchantSummary> get byRemark {
    final map = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      if (t.type != TransactionType.debit) continue;
      final name = (t.displayRemark ?? t.description).trim();
      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// By bank/source name (bankName, sourceKey, sender) — debit only.
  List<MerchantSummary> get byBankName {
    final map = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      if (t.type != TransactionType.debit) continue;
      final name = (t.bankName ?? t.sourceKey ?? t.sender ?? 'Unknown').trim();
      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// By title (normalized; should align with bank/source after migration) — debit only.
  List<MerchantSummary> get byTitle {
    final map = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      if (t.type != TransactionType.debit) continue;
      final name = (t.title ?? t.bankName ?? t.sourceKey ?? t.sender ?? 'Unknown').trim();
      final key = name.isEmpty ? 'Unknown' : name;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Transactions grouped by calendar day (date at midnight) for calendar view.
  Map<DateTime, List<Transaction>> get transactionsByDay {
    final map = <DateTime, List<Transaction>>{};
    for (final t in filteredTransactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map;
  }

  /// By date (daily debit total) for chart "Group by Date". Sorted by date ascending.
  List<MerchantSummary> get byDate {
    final map = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      if (t.type != TransactionType.debit) continue;
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final key = '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
      map.putIfAbsent(key, () => []).add(t);
    }
    final list = map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// By category (category name -> total amount). For debit-only spending.
  Map<String, double> get byCategory {
    final map = <String, double>{};
    for (final t in filteredTransactions) {
      if (t.type == TransactionType.debit) {
        final cat = t.category ?? 'Other';
        map[cat] = (map[cat] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Spent today (all transactions; for dashboard quick stat).
  double get spentToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.debit &&
              DateTime(t.date.year, t.date.month, t.date.day) == today,
        )
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Spent this week, Monday–today (all transactions; for dashboard quick stat).
  double get spentThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final tomorrow = today.add(const Duration(days: 1));
    return transactions
        .where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return t.type == TransactionType.debit &&
              !d.isBefore(weekStart) &&
              d.isBefore(tomorrow);
        })
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Biggest spending category name (all debit transactions; for dashboard).
  String? get biggestCategory {
    final map = <String, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.debit) {
        final cat = t.category ?? 'Other';
        map[cat] = (map[cat] ?? 0) + t.amount;
      }
    }
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Last transaction by date (all transactions; for dashboard quick stat).
  Transaction? get lastTransaction {
    if (transactions.isEmpty) return null;
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  // ─── New computed getters for Phase 1 & 2 ─────────────────────────────────

  /// Monthly balance trend for the last 12 months (for line chart).
  List<MonthlyBalance> get balanceTrendMonthly {
    final now = DateTime.now();
    final result = <MonthlyBalance>[];
    double cumulative = 0;

    // Gather all transactions sorted oldest-first
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 11; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final nextM = DateTime(m.year, m.month + 1, 1);

      double credit = 0, debit = 0;
      for (final t in sorted) {
        if (t.date.isBefore(m)) continue;
        if (!t.date.isBefore(nextM)) continue;
        if (t.type == TransactionType.credit) {
          credit += t.amount;
        } else {
          debit += t.amount;
        }
      }
      cumulative += (credit - debit);
      result.add(
        MonthlyBalance(
          month: m,
          credit: credit,
          debit: debit,
          cumulativeBalance: cumulative,
        ),
      );
    }
    return result;
  }

  /// Monthly credit/debit pairs for last 12 months (for stacked bar chart).
  Map<String, CreditDebitPair> get monthlyCreditDebitByMonth {
    final trend = balanceTrendMonthly;
    final map = <String, CreditDebitPair>{};
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    for (final mb in trend) {
      final label = '${months[mb.month.month - 1]} ${mb.month.year % 100}';
      map[label] = CreditDebitPair(credit: mb.credit, debit: mb.debit);
    }
    return map;
  }

  /// Category comparison: this month vs last month per category.
  Map<String, CategoryComparison> get monthlyComparison {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final thisMonthCats = <String, double>{};
    final lastMonthCats = <String, double>{};

    for (final t in transactions) {
      if (t.type != TransactionType.debit) continue;
      final cat = t.category ?? 'Other';
      final d = t.date;
      if (d.year == thisMonthStart.year && d.month == thisMonthStart.month) {
        thisMonthCats[cat] = (thisMonthCats[cat] ?? 0) + t.amount;
      } else if (d.year == lastMonthStart.year &&
          d.month == lastMonthStart.month) {
        lastMonthCats[cat] = (lastMonthCats[cat] ?? 0) + t.amount;
      }
    }

    final allCats = {...thisMonthCats.keys, ...lastMonthCats.keys};
    final result = <String, CategoryComparison>{};

    for (final cat in allCats) {
      final thisM = thisMonthCats[cat] ?? 0;
      final lastM = lastMonthCats[cat] ?? 0;
      final change = lastM > 0
          ? ((thisM - lastM) / lastM * 100)
          : (thisM > 0 ? 100 : 0);
      result[cat] = CategoryComparison(
        category: cat,
        thisMonth: thisM,
        lastMonth: lastM,
        changePercent: change.toDouble(),
      );
    }
    return result;
  }

  /// Savings rate for current month (% of income saved).
  double get savingsRate {
    final now = DateTime.now();
    double credit = 0, debit = 0;
    for (final t in transactions) {
      if (t.date.year == now.year && t.date.month == now.month) {
        if (t.type == TransactionType.credit) {
          credit += t.amount;
        } else {
          debit += t.amount;
        }
      }
    }
    if (credit <= 0) return 0;
    return ((credit - debit) / credit * 100).clamp(0, 100);
  }

  /// Daily spending intensity for heatmap (day → total debit).
  Map<DateTime, double> get dailySpendingIntensity {
    final map = <DateTime, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.debit) {
        final day = DateTime(t.date.year, t.date.month, t.date.day);
        map[day] = (map[day] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Rule-based quick insights for dashboard carousel - "Money Mirror" style.
  List<InsightData> get quickInsights {
    final insights = <InsightData>[];
    if (transactions.isEmpty) return insights;

    final now = DateTime.now();
    final comparison = monthlyComparison;

    // 1. "Money Mirror" - Category Spending Math
    CategoryComparison? biggestIncrease;
    for (var comp in comparison.values) {
      if (comp.changePercent > 0 && comp.thisMonth > 500) {
        // Significant spending
        if (biggestIncrease == null ||
            comp.changePercent > biggestIncrease.changePercent) {
          biggestIncrease = comp;
        }
      }
    }

    if (biggestIncrease != null && biggestIncrease.changePercent > 5) {
      insights.add(
        InsightData(
          kind: InsightKind.moneyMirror,
          title: 'Money Mirror',
          description:
              'This month you spent more on ${biggestIncrease.category} than last month by ${biggestIncrease.changePercent.toStringAsFixed(0)}%.',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF1E3A8A),
          categoryFilter: biggestIncrease.category,
        ),
      );
    }

    // 2. No Spend Days Motivation
    final noSpendDays = noSpendDaysCount;
    if (noSpendDays > 0) {
      insights.add(
        InsightData(
          kind: InsightKind.noSpendDays,
          title: 'Persistence Paid Off',
          description:
              'You had $noSpendDays "No Spend Days" this month. That\'s impressive!',
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF10B981),
        ),
      );
    }

    // 3. Unlabeled transactions task loop
    final unlabeledCount = unlabeledTransactionsCount;
    if (unlabeledCount > 0) {
      insights.add(
        InsightData(
          kind: InsightKind.attentionNeeded,
          title: 'Attention Needed',
          description:
              '$unlabeledCount transactions need attention. Label them to see better insights.',
          icon: Icons.label_important_outline_rounded,
          color: const Color(0xFFF59E0B),
        ),
      );
    }

    // 4. Smart Grouping / Patterns
    final groups = smartGroups;
    if (groups.isNotEmpty) {
      final topGroup = groups.first;
      insights.add(
        InsightData(
          kind: InsightKind.spendingPattern,
          title: 'Spending Pattern',
          description:
              'You\'ve made ${topGroup.count} transactions at ${topGroup.name} recently.',
          icon: Icons.analytics_rounded,
          color: const Color(0xFF6366F1),
          merchantFilter: topGroup.name,
        ),
      );
    }

    // 5. Balance projection
    final dayOfMonth = now.day;
    if (dayOfMonth >= 5) {
      double thisMonthDebit = 0;
      for (final t in transactions) {
        if (t.date.year == now.year &&
            t.date.month == now.month &&
            t.type == TransactionType.debit) {
          thisMonthDebit += t.amount;
        }
      }
      final dailyAvg = thisMonthDebit / dayOfMonth;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projected = dailyAvg * daysInMonth;
      insights.add(
        InsightData(
          kind: InsightKind.forecast,
          title: 'Month-end Forecast',
          description:
              'Staying on this path, you\'ll spend Rs. ${projected.toStringAsFixed(0)} this month.',
          icon: Icons.speed_rounded,
          color: const Color(0xFF3B82F6),
        ),
      );
    }

    // 6. Fallback Insights (Always show something clickable to prove UX)
    if (insights.length < 2) {
      insights.add(
        const InsightData(
          kind: InsightKind.categoryShortcut,
          title: 'Bills Review',
          description:
              'Tap to see how much you spend on electricity and internet.',
          icon: Icons.lightbulb_outline_rounded,
          color: Color(0xFF0D9488),
          categoryFilter: 'Bills',
        ),
      );
    }

    if (insights.length < 3) {
      insights.add(
        const InsightData(
          kind: InsightKind.categoryShortcut,
          title: 'Food Explorer',
          description: 'Analyze your eating habits and restaurant spending.',
          icon: Icons.restaurant_rounded,
          color: Color(0xFFEA580C),
          categoryFilter: 'Food',
        ),
      );
    }

    return insights;
  }

  /// 2️⃣ Spending Heatmap/No Spend Day logic
  int get noSpendDaysCount {
    final now = DateTime.now();
    int count = 0;
    for (int i = 1; i <= now.day; i++) {
      final day = DateTime(now.year, now.month, i);
      if (isNoSpendDay(day)) count++;
    }
    return count;
  }

  bool isNoSpendDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return !transactions.any(
      (t) =>
          t.type == TransactionType.debit &&
          DateTime(t.date.year, t.date.month, t.date.day) == dayOnly,
    );
  }

  /// 3️⃣ Unknown / Unlabeled Bucket
  int get unlabeledTransactionsCount => unlabeledTransactions.length;

  List<Transaction> get unlabeledTransactions {
    return transactions
        .where(
          (t) =>
              (t.category == null ||
              t.category == 'Other' ||
              t.category!.isEmpty),
        )
        .toList();
  }

  /// 4️⃣ Smart Grouping (Rule-based)
  List<MerchantSummary> get smartGroups {
    final map = <String, List<Transaction>>{};
    // The original code had a typo 'transitions' here. Corrected to 'transactions'.
    // for (final t in transitions) {
    // Wait, name is 'transactions' in field, let me check
    // Using 'transactions' from the class field
    // }
    // Let's re-implement logic here to avoid name confusion
    final txs = transactions;
    for (final t in txs) {
      final key = t.merchant ?? t.sender ?? t.rawRemark ?? 'Unknown';
      if (key == 'Unknown') continue;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map(
          (e) => MerchantSummary(
            name: e.key,
            total: e.value.fold(0.0, (s, t) => s + t.amount),
            count: e.value.length,
            transactions: e.value,
          ),
        )
        .where((m) => m.count >= 2) // At least 2 to be a pattern
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  FinanceState copyWith({
    FinanceStatus? status,
    List<Transaction>? transactions,
    TransactionType? filterType,
    String? filterCategory,
    int? filterYear,
    int? filterMonth,
    String? searchQuery,
    DateTime? filterDateFrom,
    DateTime? filterDateTo,
    Map<String, dynamic>? summaryData,
    TimePeriod? summaryPeriod,
    DateTime? summaryDate,
    String? errorMessage,
    Set<String>? recurringCategoryLabels,
    int? financeTabIndex,
    int? analyticsTabIndex,
    bool? analyticsTabBusy,
    bool? analyticsDetailsExpanded,
    bool? transactionsIsTableView,
    FinanceGroupByColumn? transactionsGroupByColumn,
    DateTime? calendarSelectedMonth,
    TimePeriod? summaryUiPeriod,
    DateTime? summaryUiFocusedDate,
    int? dashboardCarouselPage,
    int? sourceBreakdownTouchedIndex,
    int? categoryBreakdownTouchedIndex,
    FinanceFlowPeriodUi? flowDetailPeriod,
    AddTransactionTypeUi? addTxnType,
    DateTime? addTxnDate,
    String? addTxnCategory,
    bool? addTxnSubmitted,
  }) {
    return FinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filterType: filterType ?? this.filterType,
      filterCategory: filterCategory ?? this.filterCategory,
      filterYear: filterYear ?? this.filterYear,
      filterMonth: filterMonth ?? this.filterMonth,
      searchQuery: searchQuery ?? this.searchQuery,
      filterDateFrom: filterDateFrom ?? this.filterDateFrom,
      filterDateTo: filterDateTo ?? this.filterDateTo,
      summaryData: summaryData ?? this.summaryData,
      summaryPeriod: summaryPeriod ?? this.summaryPeriod,
      summaryDate: summaryDate ?? this.summaryDate,
      errorMessage: errorMessage ?? this.errorMessage,
      recurringCategoryLabels:
          recurringCategoryLabels ?? this.recurringCategoryLabels,
      financeTabIndex: financeTabIndex ?? this.financeTabIndex,
      analyticsTabIndex: analyticsTabIndex ?? this.analyticsTabIndex,
      analyticsTabBusy: analyticsTabBusy ?? this.analyticsTabBusy,
      analyticsDetailsExpanded:
          analyticsDetailsExpanded ?? this.analyticsDetailsExpanded,
      transactionsIsTableView:
          transactionsIsTableView ?? this.transactionsIsTableView,
      transactionsGroupByColumn:
          transactionsGroupByColumn ?? this.transactionsGroupByColumn,
      calendarSelectedMonth: calendarSelectedMonth ?? this.calendarSelectedMonth,
      summaryUiPeriod: summaryUiPeriod ?? this.summaryUiPeriod,
      summaryUiFocusedDate: summaryUiFocusedDate ?? this.summaryUiFocusedDate,
      dashboardCarouselPage: dashboardCarouselPage ?? this.dashboardCarouselPage,
      sourceBreakdownTouchedIndex:
          sourceBreakdownTouchedIndex ?? this.sourceBreakdownTouchedIndex,
      categoryBreakdownTouchedIndex:
          categoryBreakdownTouchedIndex ?? this.categoryBreakdownTouchedIndex,
      flowDetailPeriod: flowDetailPeriod ?? this.flowDetailPeriod,
      addTxnType: addTxnType ?? this.addTxnType,
      addTxnDate: addTxnDate ?? this.addTxnDate,
      addTxnCategory: addTxnCategory ?? this.addTxnCategory,
      addTxnSubmitted: addTxnSubmitted ?? this.addTxnSubmitted,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    filterType,
    filterCategory,
    filterYear,
    filterMonth,
    searchQuery,
    filterDateFrom,
    filterDateTo,
    summaryData,
    summaryPeriod,
    summaryDate,
    errorMessage,
    recurringCategoryLabels,
    financeTabIndex,
    analyticsTabIndex,
    analyticsTabBusy,
    analyticsDetailsExpanded,
    transactionsIsTableView,
    transactionsGroupByColumn,
    calendarSelectedMonth,
    summaryUiPeriod,
    summaryUiFocusedDate,
    dashboardCarouselPage,
    sourceBreakdownTouchedIndex,
    categoryBreakdownTouchedIndex,
    flowDetailPeriod,
    addTxnType,
    addTxnDate,
    addTxnCategory,
    addTxnSubmitted,
  ];
}
