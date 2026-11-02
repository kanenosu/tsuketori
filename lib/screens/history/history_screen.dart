import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/status_style.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/pill_tabs.dart';
import '../transaction/transaction_detail_screen.dart';
import 'filter_screen.dart';
import 'history_filter.dart';

/// 履歴画面（要件 6.6・モックアップ⑥準拠）。
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

  int get _typeTab => switch (_query.typeFilter) {
    HistoryTypeFilter.all => 0,
    HistoryTypeFilter.lend => 1,
    HistoryTypeFilter.borrow => 2,
  };

  Future<void> _openFilter() async {
    final result = await Navigator.of(context).push<HistoryQuery>(
      MaterialPageRoute(builder: (_) => FilterScreen(initial: _query)),
    );
    if (result != null) setState(() => _query = result);
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _query.hasActiveFilter,
              child: const Icon(Icons.tune),
            ),
            tooltip: 'フィルター',
            onPressed: _openFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: '相手・メモ・金額で検索',
                  leading: const Icon(Icons.search),
                  trailing:
                      _query.text.isEmpty
                          ? null
                          : [
                            IconButton(
                              tooltip: '検索をクリア',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(
                                  () => _query = _query.copyWith(text: ''),
                                );
                              },
                            ),
                          ],
                  onChanged:
                      (value) =>
                          setState(() => _query = _query.copyWith(text: value)),
                ),
                const SizedBox(height: 12),
                PillTabs(
                  labels: const ['すべて', '貸した', '借りた'],
                  selectedIndex: _typeTab,
                  selectedColor:
                      _typeTab == 2
                          ? StatusStyle.typeColor(TransactionType.borrow)
                          : StatusStyle.typeColor(TransactionType.lend),
                  onChanged:
                      (i) => setState(() {
                        _query = _query.copyWith(
                          typeFilter: switch (i) {
                            1 => HistoryTypeFilter.lend,
                            2 => HistoryTypeFilter.borrow,
                            _ => HistoryTypeFilter.all,
                          },
                        );
                      }),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                results.isEmpty
                    ? const EmptyState(
                      icon: Icons.search_off,
                      title: '該当する取引がありません',
                      message: 'フィルターの条件を変えてみてください。',
                    )
                    : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < entry.value.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const Divider(height: 1),
                                    _HistoryRow(transaction: entry.value[i]),
                                  ],
                                ],
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

  Map<String, List<TransactionModel>> _groupByMonth(
    List<TransactionModel> results,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in results) {
      map.putIfAbsent(Formatters.month(tx.date), () => []).add(tx);
    }
    return map;
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final tx = transaction;
    final person = appState.person(tx.personId);
    final typeColor = StatusStyle.typeColor(tx.type);
    final isLend = tx.type == TransactionType.lend;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transactionId: tx.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                Formatters.dateShort(tx.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            PersonAvatar(person: person, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person?.name ?? '(不明な相手)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.type.label,
                    style: TextStyle(fontSize: 11, color: typeColor),
                  ),
                ],
              ),
            ),
            Text(
              '${isLend ? '+' : '-'}${Formatters.yenSuffix(tx.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
