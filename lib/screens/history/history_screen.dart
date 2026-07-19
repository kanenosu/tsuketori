import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_tile.dart';
import '../transaction/transaction_detail_screen.dart';
import 'history_filter.dart';

/// 履歴画面（要件 6.6）。検索・絞り込み・並び替え・月別表示に対応。
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryQuery _query = const HistoryQuery();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    String nameOf(String id) => appState.person(id)?.name ?? '';
    final results = _query.apply(appState.transactions, nameOf);
    final grouped = _groupByMonth(results);

    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
        actions: [
          PopupMenuButton<HistorySort>(
            icon: const Icon(Icons.sort),
            tooltip: '並び替え',
            initialValue: _query.sort,
            onSelected: (s) => setState(() => _query = _query.copyWith(sort: s)),
            itemBuilder: (_) => HistorySort.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '名前・メモ・金額で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(
                            () => _query = _query.copyWith(text: ''),
                          );
                        },
                      ),
              ),
              onChanged: (v) =>
                  setState(() => _query = _query.copyWith(text: v)),
            ),
          ),
          _FilterBar(
            query: _query,
            onStatusChanged: (f) =>
                setState(() => _query = _query.copyWith(statusFilter: f)),
            onPeriodChanged: (p) =>
                setState(() => _query = _query.copyWith(period: p)),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: '該当する取引がありません',
                    message: '検索条件やフィルターを変えてみてください。',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                        ...entry.value.map(
                          (tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TransactionTile(
                              transaction: tx,
                              person: appState.person(tx.personId),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(
                                      transactionId: tx.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 月別にグルーピング（要件 6.6.1）。並び順は入力リストを尊重する。
  Map<String, List<TransactionModel>> _groupByMonth(
    List<TransactionModel> results,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in results) {
      final key = Formatters.month(tx.date);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.query,
    required this.onStatusChanged,
    required this.onPeriodChanged,
  });

  final HistoryQuery query;
  final ValueChanged<HistoryStatusFilter> onStatusChanged;
  final ValueChanged<HistoryPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ...HistoryStatusFilter.values.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(f.label),
                selected: query.statusFilter == f,
                onSelected: (_) => onStatusChanged(f),
              ),
            ),
          ),
          const VerticalDivider(width: 16),
          ...HistoryPeriod.values.where((p) => p != HistoryPeriod.all).map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(p.label),
                selected: query.period == p,
                onSelected: (sel) =>
                    onPeriodChanged(sel ? p : HistoryPeriod.all),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
