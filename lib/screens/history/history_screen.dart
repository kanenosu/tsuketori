import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/status_style.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/transaction_tile.dart';
import '../transaction/transaction_detail_screen.dart';
import 'filter_screen.dart';
import 'history_filter.dart';
import '../../widgets/surface_card.dart';

/// 履歴画面（要件 6.6・モックアップ⑥準拠）。
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  HistoryQuery _query = const HistoryQuery();

  /// false=返済中 / true=完了（返済済み・取り消し）。
  bool _showFinished = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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
    final all = _query.apply(appState.transactions, nameOf);
    final finishedCount = all.where((t) => t.isFinished).length;
    final results = all.where((t) => t.isFinished == _showFinished).toList();
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
          // Tab（Regular）：選択 #3895FF＋下線2px、背景白＋Low-Shadow。
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: AppColors.lowShadow,
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2,
              onTap: (i) => setState(() => _showFinished = i == 1),
              tabs: [
                Tab(text: '返済中 ${all.length - finishedCount}'),
                Tab(text: '完了 $finishedCount'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    ? EmptyState(
                      icon:
                          _showFinished
                              ? Icons.check_circle_outline
                              : Icons.search_off,
                      title: _showFinished ? '完了した取引はありません' : '該当する取引がありません',
                      message:
                          _showFinished
                              ? '返済済み・取り消しの取引がここに入ります'
                              : 'フィルターの条件を変えてみてください',
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
                          SurfaceCard(
                            child: Padding(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < entry.value.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      const Divider(height: 1, indent: 68),
                                    TransactionTile(
                                      transaction: entry.value[i],
                                      person: appState.person(
                                        entry.value[i].personId,
                                      ),
                                      onTap:
                                          () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      TransactionDetailScreen(
                                                        transactionId:
                                                            entry.value[i].id,
                                                      ),
                                            ),
                                          ),
                                    ),
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
