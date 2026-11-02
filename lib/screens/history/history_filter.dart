import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../../models/transaction_status.dart';
import '../../models/transaction_type.dart';

/// 取引の種類（要件 6.6.3）。
enum HistoryTypeFilter {
  all('すべて'),
  lend('貸した'),
  borrow('借りた');

  const HistoryTypeFilter(this.label);
  final String label;
}

/// ステータス絞り込み（要件 6.6.3）。
enum HistoryStatusFilter {
  all('すべて'),
  unpaid('返済待ち'),
  partial('一部返済'),
  settled('返済済み'),
  overdue('期限超過');

  const HistoryStatusFilter(this.label);
  final String label;
}

/// 期間フィルター（要件 6.6.3）。
enum HistoryPeriod {
  all('すべて'),
  thisMonth('今月'),
  lastMonth('先月'),
  months3('3ヶ月'),
  months6('6ヶ月'),
  custom('カスタム');

  const HistoryPeriod(this.label);
  final String label;
}

/// 並び替え順（要件 6.6.4）。
enum HistorySort {
  newest('新しい順'),
  oldest('古い順'),
  amountDesc('金額が大きい順'),
  amountAsc('金額が小さい順'),
  dueSoonest('返済期限が近い順');

  const HistorySort(this.label);
  final String label;
}

/// 履歴の絞り込み・並び替え条件。
class HistoryQuery {
  const HistoryQuery({
    this.text = '',
    this.typeFilter = HistoryTypeFilter.all,
    this.statusFilter = HistoryStatusFilter.all,
    this.period = HistoryPeriod.all,
    this.customRange,
    this.personId,
    this.sort = HistorySort.newest,
  });

  final String text;
  final HistoryTypeFilter typeFilter;
  final HistoryStatusFilter statusFilter;
  final HistoryPeriod period;
  final DateTimeRange? customRange;
  final String? personId;
  final HistorySort sort;

  HistoryQuery copyWith({
    String? text,
    HistoryTypeFilter? typeFilter,
    HistoryStatusFilter? statusFilter,
    HistoryPeriod? period,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
    String? personId,
    bool clearPerson = false,
    HistorySort? sort,
  }) {
    return HistoryQuery(
      text: text ?? this.text,
      typeFilter: typeFilter ?? this.typeFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      period: period ?? this.period,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
      personId: clearPerson ? null : (personId ?? this.personId),
      sort: sort ?? this.sort,
    );
  }

  /// 絞り込みが1つでも掛かっているか（アイコンのバッジ表示用）。
  bool get hasActiveFilter =>
      typeFilter != HistoryTypeFilter.all ||
      statusFilter != HistoryStatusFilter.all ||
      period != HistoryPeriod.all ||
      personId != null;

  /// 取引リストに絞り込み・並び替えを適用する。
  List<TransactionModel> apply(
    Iterable<TransactionModel> source,
    String Function(String personId) nameLookup, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final result =
        source.where((tx) {
          if (!_matchesType(tx)) return false;
          if (!_matchesStatus(tx, current)) return false;
          if (personId != null && tx.personId != personId) return false;
          if (!_matchesPeriod(tx, current)) return false;
          if (!_matchesText(tx, nameLookup)) return false;
          return true;
        }).toList();

    result.sort(_comparator);
    return result;
  }

  bool _matchesType(TransactionModel tx) {
    switch (typeFilter) {
      case HistoryTypeFilter.all:
        return true;
      case HistoryTypeFilter.lend:
        return tx.type == TransactionType.lend;
      case HistoryTypeFilter.borrow:
        return tx.type == TransactionType.borrow;
    }
  }

  bool _matchesStatus(TransactionModel tx, DateTime current) {
    switch (statusFilter) {
      case HistoryStatusFilter.all:
        return true;
      case HistoryStatusFilter.unpaid:
        return tx.effectiveStatus(asOf: current) == TransactionStatus.unpaid;
      case HistoryStatusFilter.partial:
        return tx.effectiveStatus(asOf: current) == TransactionStatus.partial;
      case HistoryStatusFilter.settled:
        return tx.effectiveStatus(asOf: current) == TransactionStatus.settled;
      case HistoryStatusFilter.overdue:
        return tx.effectiveStatus(asOf: current) == TransactionStatus.overdue;
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
        return tx.date.isAfter(DateTime(now.year, now.month - 3, now.day));
      case HistoryPeriod.months6:
        return tx.date.isAfter(DateTime(now.year, now.month - 6, now.day));
      case HistoryPeriod.custom:
        final range = customRange;
        if (range == null) return true;
        final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        return !d.isBefore(start) && !d.isAfter(end);
    }
  }

  bool _matchesText(TransactionModel tx, String Function(String) nameLookup) {
    final q = text.trim();
    if (q.isEmpty) return true;
    final name = nameLookup(tx.personId);
    if (name.contains(q)) return true;
    if ((tx.memo ?? '').contains(q)) return true;
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
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return b.date.compareTo(a.date);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
    }
  }
}
