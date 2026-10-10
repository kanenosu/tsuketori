import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/ledger_header.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/transaction_tile.dart';
import '../stats/stats_screen.dart';
import '../transaction/new_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';

/// ホーム画面（要件 6.1・モックアップ準拠）。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenHistory});

  /// 「すべて見る」から履歴タブへ切り替えるためのコールバック。
  final VoidCallback? onOpenHistory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0=すべて / 1=貸した / 2=借りた（要件 6.1.3）。
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final summary = appState.summary();

    var transactions = appState.transactions;
    if (_tab == 1) {
      transactions =
          transactions.where((t) => t.type == TransactionType.lend).toList();
    } else if (_tab == 2) {
      transactions =
          transactions.where((t) => t.type == TransactionType.borrow).toList();
    }
    final recent = transactions.take(20).toList();

    return Scaffold(
      appBar: LedgerHeader(
        title: '貸し借り',
        actions: [
          IconButton(
            tooltip: '統計',
            icon: const Icon(CupertinoIcons.chart_bar),
            onPressed:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            tooltip: '取引を追加',
            icon: const Icon(CupertinoIcons.add, size: 28),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NewTransactionScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            BalanceCard(summary: summary),
            const SizedBox(height: 24),
            PillTabs(
              labels: const ['すべて', '貸した', '借りた'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              selectedColor: _tab == 2 ? AppColors.borrow : AppColors.primary,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  '最近の取引',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: widget.onOpenHistory,
                    child: const Text('すべて見る', style: TextStyle(fontSize: 14)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.swap_horiz,
                  title: '取引がまだありません',
                  message: '右上の＋から、最初の貸し借りを記録できます。',
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < recent.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        TransactionTile(
                          transaction: recent[i],
                          person: appState.person(recent[i].personId),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => TransactionDetailScreen(
                                      transactionId: recent[i].id,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
