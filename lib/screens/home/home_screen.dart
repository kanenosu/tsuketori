import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/transaction_tile.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
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
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('貸し借り'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '通知',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('通知機能は今後対応予定です')),
              );
            },
          ),
        ],
      ),
      drawer: const _HomeDrawer(),
      body: RefreshIndicator(
        onRefresh: () => appState.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            BalanceCard(summary: summary),
            const SizedBox(height: 20),
            PillTabs(
              labels: const ['すべて', '貸した', '借りた'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              selectedColor: _tab == 2 ? AppColors.borrow : AppColors.primary,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  '最近の取引',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (recent.isNotEmpty)
                  GestureDetector(
                    onTap: widget.onOpenHistory,
                    child: Text(
                      'すべて見る',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
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
                  message: '右下の＋ボタンから、貸した・借りたを記録しましょう。',
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
                                builder: (_) => TransactionDetailScreen(
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
      floatingActionButton: FloatingActionButton(
        // IndexedStack で全タブが同時に生存するため heroTag を一意にする。
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ハンバーガーメニューのドロワー（統計・設定などへの導線）。
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.currency_yen, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '貸し借り管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('統計'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('履歴'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('設定'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
