import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/repayment.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/status_style.dart';
import '../../utils/formatters.dart';
import '../../utils/persisted_action.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/status_badge.dart';
import '../repayment/repayment_screen.dart';
import 'edit_transaction_screen.dart';

/// 取引詳細画面（要件 6.3・モックアップ④準拠）。
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tx = appState.transaction(transactionId);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('取引の詳細')),
        body: const Center(child: Text('取引が見つかりません')),
      );
    }

    final person = appState.person(tx.personId);
    final typeColor = StatusStyle.typeColor(tx.type);
    final status = tx.effectiveStatus();
    final repayments = appState.repaymentsForTransaction(tx.id);
    final canRepay = tx.isOutstanding;
    final isLend = tx.type == TransactionType.lend;

    return Scaffold(
      appBar: AppBar(
        title: const Text('取引の詳細'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditTransactionScreen(transactionId: tx.id),
                  ),
                );
              } else if (v == 'delete') {
                _confirmDelete(context, appState);
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('編集する')),
                  PopupMenuItem(value: 'delete', child: Text('削除する')),
                ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 金額と相手を中心にした取引の概要。
          Column(
            children: [
              const SizedBox(height: 12),
              Text(
                tx.type.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isLend ? '+' : '-'}${Formatters.yenSuffix(tx.amount)}',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PersonAvatar(person: person, radius: 16),
                  const SizedBox(width: 8),
                  Text(
                    person?.name ?? '(不明な相手)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tx.repaidAmount > 0 && canRepay) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '残額 ${Formatters.yenSuffix(tx.remainingAmount)}'
                      '（返済済み ${Formatters.yenSuffix(tx.repaidAmount)}）',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value:
                            tx.amount == 0
                                ? 0
                                : (tx.repaidAmount / tx.amount).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: typeColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(typeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _infoRow(context, '日付', value: Formatters.longDate(tx.date)),
                const Divider(height: 1),
                _infoRow(
                  context,
                  '返済予定日',
                  value:
                      tx.dueDate == null
                          ? '未設定'
                          : Formatters.longDate(tx.dueDate!),
                  valueColor:
                      tx.isOverdue() ? StatusStyle.statusColor(status) : null,
                ),
                if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                  const Divider(height: 1),
                  _infoRow(context, 'メモ', value: tx.memo!),
                ],
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(
                          'ステータス',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      StatusBadge(status: status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '作成 ${Formatters.dateTime(tx.createdAt)}'
            '  ／  更新 ${Formatters.dateTime(tx.updatedAt)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
          if (repayments.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  '返済履歴',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${repayments.length}件',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...repayments.map(
              (r) => _RepaymentTile(
                repayment: r,
                onDelete:
                    () => persistedAction(
                      context,
                      () => appState.deleteRepayment(r.id),
                    ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child:
              canRepay
                  ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => EditTransactionScreen(
                                      transactionId: tx.id,
                                    ),
                              ),
                            );
                          },
                          child: const Text('編集する'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              () => _showRepayMenu(context, appState, tx.id),
                          child: const Text('返済を記録する'),
                        ),
                      ),
                    ],
                  )
                  : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  EditTransactionScreen(transactionId: tx.id),
                        ),
                      );
                    },
                    child: const Text('編集する'),
                  ),
        ),
      ),
    );
  }

  /// 返済の記録方法を選ぶ（全額＝返済済みにする／一部返済）。
  Future<void> _showRepayMenu(
    BuildContext context,
    AppState appState,
    String txId,
  ) async {
    final tx = appState.transaction(txId);
    if (tx == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.done_all, color: Colors.green),
                  title: const Text('返済済みにする'),
                  subtitle: Text(
                    '残額 ${Formatters.yenSuffix(tx.remainingAmount)} を全額返済',
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    if (!await persistedAction(context, () async {
                      await appState.addRepayment(
                        transactionId: txId,
                        amount: tx.remainingAmount,
                        date: DateTime.now(),
                      );
                    })) {
                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('返済済みにしました')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('一部返済を記録する'),
                  subtitle: const Text('金額・返済方法・日付を指定'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RepaymentScreen(transactionId: txId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('取引を削除'),
            content: const Text('この取引を削除しますか？削除した取引は元に戻せません。'),
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
    if (ok == true && context.mounted) {
      if (!await persistedAction(
        context,
        () => appState.deleteTransaction(transactionId),
      )) {
        return;
      }
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _infoRow(
    BuildContext context,
    String label, {
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepaymentTile extends StatelessWidget {
  const _RepaymentTile({required this.repayment, required this.onDelete});

  final Repayment repayment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = repayment;
    final subtitle = [
      Formatters.date(r.date),
      if (r.method != null) r.method!.label,
      if (r.memo != null && r.memo!.isNotEmpty) r.memo!,
    ].join(' ・ ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A16A34A),
          child: Icon(Icons.check, color: Colors.green),
        ),
        title: Text(
          Formatters.yenSuffix(r.amount),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('返済記録を削除'),
                    content: const Text('この返済記録を削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
            );
            if (ok == true) onDelete();
          },
        ),
      ),
    );
  }
}
