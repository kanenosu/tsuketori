import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_tile.dart';
import '../stats/stats_screen.dart';
import '../transaction/new_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';

/// ホーム画面（要件 6.1）。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // すべて / 貸した / 借りた（要件 6.1.3）。null=すべて。
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final summary = appState.summary();

    var transactions = appState.transactions;
    if (_filter != null) {
      transactions = transactions.where((t) => t.type == _filter).toList();
    }
    // ホームは最近の取引を表示（要件 6.1.2）。
    final recent = transactions.take(20).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ツケトリ'),
        actions: [
          IconButton(
            tooltip: '統計',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            BalanceCard(summary: summary),
            const SizedBox(height: 20),
            _FilterTabs(
              value: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyState(
                  icon: Icons.swap_horiz,
                  title: '取引がまだありません',
                  message: '右下の＋ボタンから、貸した・借りたを記録しましょう。',
                ),
              )
            else
              ...recent.map(
                (tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TransactionTile(
                    transaction: tx,
                    person: appState.person(tx.personId),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TransactionDetailScreen(transactionId: tx.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // IndexedStack で全タブが同時に生存するため heroTag を一意にする。
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('記録する'),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final TransactionType? value;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('すべて')),
        ButtonSegment(value: 1, label: Text('貸した')),
        ButtonSegment(value: 2, label: Text('借りた')),
      ],
      selected: {value == null ? 0 : (value == TransactionType.lend ? 1 : 2)},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        final v = s.first;
        onChanged(
          v == 0
              ? null
              : v == 1
              ? TransactionType.lend
              : TransactionType.borrow,
        );
      },
    );
  }
}
