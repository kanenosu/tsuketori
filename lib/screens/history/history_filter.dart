import '../../models/transaction.dart';
import '../../models/transaction_status.dart';
import '../../models/transaction_type.dart';

/// 並び替え順（要件 6.6.4）。
enum HistorySort {
  newest,
  oldest,
  amountDesc,
  amountAsc,
  dueSoonest;

  String get label {
    switch (this) {
      case HistorySort.newest:
        return '新しい順';
      case HistorySort.oldest:
        return '古い順';
      case HistorySort.amountDesc:
        return '金額が大きい順';
      case HistorySort.amountAsc:
        return '金額が小さい順';
      case HistorySort.dueSoonest:
        return '返済期限が近い順';
    }
  }
}

/// 期間フィルター（要件 6.6.3）。
enum HistoryPeriod {
  all,
  thisMonth,
  lastMonth,
  months3,
  months6;

  String get label {
    switch (this) {
      case HistoryPeriod.all:
        return 'すべての期間';
      case HistoryPeriod.thisMonth:
        return '今月';
      case HistoryPeriod.lastMonth:
        return '先月';
      case HistoryPeriod.months3:
        return '3か月';
      case HistoryPeriod.months6:
        return '6か月';
    }
  }
}

/// 種別・ステータスの絞り込み（要件 6.6.3）。
enum HistoryStatusFilter {
  all,
  lend,
  borrow,
  unpaid,
  partial,
  settled,
  overdue;

  String get label {
    switch (this) {
      case HistoryStatusFilter.all:
        return 'すべて';
      case HistoryStatusFilter.lend:
        return '貸した';
      case HistoryStatusFilter.borrow:
        return '借りた';
      case HistoryStatusFilter.unpaid:
        return '未返済';
      case HistoryStatusFilter.partial:
        return '一部返済';
      case HistoryStatusFilter.settled:
        return '返済済み';
      case HistoryStatusFilter.overdue:
        return '期限超過';
    }
  }
}

/// 履歴の検索・絞り込み・並び替え条件をまとめて保持する。
class HistoryQuery {
  const HistoryQuery({
    this.text = '',
    this.statusFilter = HistoryStatusFilter.all,
    this.period = HistoryPeriod.all,
    this.personId,
    this.sort = HistorySort.newest,
  });

  final String text;
  final HistoryStatusFilter statusFilter;
  final HistoryPeriod period;
  final String? personId;
  final HistorySort sort;

  HistoryQuery copyWith({
    String? text,
    HistoryStatusFilter? statusFilter,
    HistoryPeriod? period,
    String? personId,
    bool clearPerson = false,
    HistorySort? sort,
  }) {
    return HistoryQuery(
      text: text ?? this.text,
      statusFilter: statusFilter ?? this.statusFilter,
      period: period ?? this.period,
      personId: clearPerson ? null : (personId ?? this.personId),
      sort: sort ?? this.sort,
    );
  }

  /// 取引リストに検索・絞り込み・並び替えを適用する。
  /// [nameLookup] は相手IDから名前を引く関数（名前検索用）。
  List<TransactionModel> apply(
    Iterable<TransactionModel> source,
    String Function(String personId) nameLookup, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final result = source.where((tx) {
      if (!_matchesStatus(tx)) return false;
      if (personId != null && tx.personId != personId) return false;
      if (!_matchesPeriod(tx, current)) return false;
      if (!_matchesText(tx, nameLookup)) return false;
      return true;
    }).toList();

    result.sort(_comparator);
    return result;
  }

  bool _matchesStatus(TransactionModel tx) {
    switch (statusFilter) {
      case HistoryStatusFilter.all:
        return true;
      case HistoryStatusFilter.lend:
        return tx.type == TransactionType.lend;
      case HistoryStatusFilter.borrow:
        return tx.type == TransactionType.borrow;
      case HistoryStatusFilter.unpaid:
        return tx.effectiveStatus() == TransactionStatus.unpaid;
      case HistoryStatusFilter.partial:
        return tx.effectiveStatus() == TransactionStatus.partial;
      case HistoryStatusFilter.settled:
        return tx.effectiveStatus() == TransactionStatus.settled;
      case HistoryStatusFilter.overdue:
        return tx.effectiveStatus() == TransactionStatus.overdue;
    }
  }

  bool _matchesPeriod(TransactionModel tx, DateTime now) {
    switch (period) {
      case HistoryPeriod.all:
        return true;
      case HistoryPeriod.thisMonth:
        return tx.date.year == now.year && tx.date.month == now.month;
      case HistoryPeriod.lastMonth:
        final lm = DateTime(now.year, now.month - 1);
        return tx.date.year == lm.year && tx.date.month == lm.month;
      case HistoryPeriod.months3:
        return tx.date.isAfter(
          DateTime(now.year, now.month - 3, now.day),
        );
      case HistoryPeriod.months6:
        return tx.date.isAfter(
          DateTime(now.year, now.month - 6, now.day),
        );
    }
  }

  bool _matchesText(
    TransactionModel tx,
    String Function(String) nameLookup,
  ) {
    final q = text.trim();
    if (q.isEmpty) return true;
    final name = nameLookup(tx.personId);
    if (name.contains(q)) return true;
    if ((tx.memo ?? '').contains(q)) return true;
    // 金額検索（数字部分のみで照合）。
    final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty && tx.amount.toString().contains(digits)) {
      return true;
    }
    return false;
  }

  int _comparator(TransactionModel a, TransactionModel b) {
    switch (sort) {
      case HistorySort.newest:
        return b.date.compareTo(a.date);
      case HistorySort.oldest:
        return a.date.compareTo(b.date);
      case HistorySort.amountDesc:
        return b.amount.compareTo(a.amount);
      case HistorySort.amountAsc:
        return a.amount.compareTo(b.amount);
      case HistorySort.dueSoonest:
        // 期限なしは末尾へ。
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return b.date.compareTo(a.date);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
    }
  }
}
