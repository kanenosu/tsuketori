import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/transaction_tile.dart';
import '../transaction/transaction_detail_screen.dart';
import 'person_edit_screen.dart';

/// 相手詳細画面（要件 6.5.2 / 6.5.4）。
class PersonDetailScreen extends StatelessWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final person = appState.person(personId);
    if (person == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('相手が見つかりません')),
      );
    }

    final balance = appState.balanceForPerson(personId);
    final diff = balance.diff;
    final diffColor =
        diff > 0
            ? AppColors.lend
            : diff < 0
            ? AppColors.borrow
            : AppColors.unpaid;
    final transactions = appState.transactionsForPerson(personId);
    final outstanding = transactions.where((t) => t.isOutstanding).toList();
    final settled = transactions.where((t) => !t.isOutstanding).toList();
    final offsetable = appState.offsetableAmountForPerson(personId);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, appState, v),
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('相手を編集')),
                  PopupMenuItem(value: 'hide', child: Text('非表示にする')),
                  PopupMenuItem(value: 'delete', child: Text('取引ごと削除')),
                ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  PersonAvatar(person: person, radius: 32),
                  const SizedBox(height: 12),
                  Text(
                    '現在の差額',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.signed(diff)}円',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                  Text(
                    diff > 0
                        ? '受け取る予定'
                        : diff < 0
                        ? '返す予定'
                        : balance.unsettledCount > 0
                        ? '差引なし（未精算${balance.unsettledCount}件）'
                        : '精算済み',
                    style: TextStyle(color: diffColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _totalMetric(
                        context,
                        '貸した合計',
                        balance.lentTotal,
                        AppColors.lend,
                      ),
                      _totalMetric(
                        context,
                        '借りた合計',
                        balance.borrowedTotal,
                        AppColors.borrow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (offsetable > 0) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${Formatters.yenSuffix(offsetable)} を相殺できます',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed:
                          () => _confirmOffset(context, appState, offsetable),
                      child: const Text('相殺'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (person.memo != null && person.memo!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(person.memo!),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (outstanding.isNotEmpty) ...[
            _sectionTitle(context, '未返済の取引', outstanding.length),
            ...outstanding.map((tx) => _tile(context, appState, tx)),
            const SizedBox(height: 12),
          ],
          if (settled.isNotEmpty) ...[
            _sectionTitle(context, '返済済み・取り消しの取引', settled.length),
            ...settled.map((tx) => _tile(context, appState, tx)),
          ],
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'この相手との取引はまだありません',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, AppState appState, TransactionModel tx) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TransactionTile(
          transaction: tx,
          person: appState.person(tx.personId),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transactionId: tx.id),
              ),
            );
          },
        ),
      );

  Widget _sectionTitle(BuildContext context, String title, int count) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              '$count件',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );

  Widget _totalMetric(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.yenSuffix(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    AppState appState,
    String value,
  ) async {
    switch (value) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonEditScreen(person: appState.person(personId)),
          ),
        );
      case 'hide':
        await appState.hidePerson(personId);
        if (context.mounted) Navigator.of(context).pop();
      case 'delete':
        await _confirmDelete(context, appState);
    }
  }

  Future<void> _confirmOffset(
    BuildContext context,
    AppState appState,
    int amount,
  ) async {
    // 相殺実行前に確認画面を表示する（要件 6.5.4）。
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('貸し借りを相殺'),
            content: Text(
              '${Formatters.yenSuffix(amount)} 分の貸し借りを相殺します。'
              'この操作で該当分が返済済みとして記録されます。よろしいですか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('相殺する'),
              ),
            ],
          ),
    );
    if (ok == true) {
      final offset = await appState.offsetPerson(personId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Formatters.yenSuffix(offset)} を相殺しました')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState) async {
    final hasTx = appState.personHasTransactions(personId);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('相手を削除'),
            content: Text(
              hasTx
                  ? 'この相手には取引履歴があります。取引を含めてすべて削除しますか？'
                      'この操作は元に戻せません。'
                  : 'この相手を削除しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('削除する'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await appState.deletePersonWithTransactions(personId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
