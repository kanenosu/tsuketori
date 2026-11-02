import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// ホーム画面（要件 6.1）。
///
/// PayPay の Half color background レイアウト：透過ヘッダーの下に
/// ブルーを敷いて残高を最上部に置き、主アクション「記録する」は
/// 画面下の Sticky Button に固定する。
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

  void _openNew() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NewTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final summary = appState.summary();
    final topInset = MediaQuery.paddingOf(context).top;

    var transactions = appState.transactions;
    if (_tab == 1) {
      transactions =
          transactions.where((t) => t.type == TransactionType.lend).toList();
    } else if (_tab == 2) {
      transactions =
          transactions.where((t) => t.type == TransactionType.borrow).toList();
    }
    final recent = transactions.take(20).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => appState.load(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Stack(
                      children: [
                        BalanceCard(summary: summary, topInset: topInset + 44),
                        // Transparent Header。
                        Positioned(
                          top: topInset,
                          left: 0,
                          right: 0,
                          height: 44,
                          child: _header(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            '最近の取引',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGray,
                            ),
                          ),
                          const Spacer(),
                          if (recent.isNotEmpty)
                            TextButton(
                              onPressed: widget.onOpenHistory,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text('すべて見る'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: PillTabs(
                        labels: const ['すべて', '貸した', '借りた'],
                        selectedIndex: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                        selectedColor:
                            _tab == 2 ? AppColors.borrow : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: '取引がまだありません',
                          message: '下の「記録する」から、貸した・借りたを残しましょう',
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: AppColors.lowShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              for (var i = 0; i < recent.length; i++) ...[
                                if (i > 0) const Divider(height: 1, indent: 68),
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
            ),
            // Sticky Button：白背景＋上方向の Low-Shadow。
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    offset: Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: FilledButton.icon(
                onPressed: _openNew,
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('記録する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        const Text(
          'ツケトリ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: '統計',
          color: Colors.white,
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
