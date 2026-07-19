import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/repayment.dart';
import '../../state/app_state.dart';
import '../../theme/status_style.dart';
import '../../utils/formatters.dart';
import '../../widgets/person_avatar_row.dart';
import '../../widgets/status_badge.dart';
import '../repayment/repayment_screen.dart';
import 'edit_transaction_screen.dart';

/// 取引詳細画面（要件 6.3）。
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tx = appState.transaction(transactionId);

    if (tx == null) {
      // 削除済みなど。
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('取引が見つかりません')),
      );
    }

    final person = appState.person(tx.personId);
    final typeColor = StatusStyle.typeColor(tx.type);
    final status = tx.effectiveStatus();
    final repayments = appState.repaymentsForTransaction(tx.id);
    final canRepay = tx.isOutstanding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('取引詳細'),
        actions: [
          IconButton(
            tooltip: '編集',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditTransactionScreen(transactionId: tx.id),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '削除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, appState),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tx.type.label,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Formatters.yenSuffix(tx.amount),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: typeColor,
                    ),
                  ),
                  if (tx.repaidAmount > 0 || canRepay) ...[
                    const SizedBox(height: 4),
                    Text(
                      '残額 ${Formatters.yenSuffix(tx.remainingAmount)}'
                      '（返済済み ${Formatters.yenSuffix(tx.repaidAmount)}）',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 12),
                    _ProgressBar(
                      ratio: tx.amount == 0
                          ? 0
                          : tx.repaidAmount / tx.amount,
                      color: typeColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _infoRow(context, '相手', trailing: person == null
                    ? null
                    : PersonAvatarRow(person: person)),
                const Divider(height: 1),
                _infoRow(context, '取引日', value: Formatters.date(tx.date)),
                const Divider(height: 1),
                _infoRow(
                  context,
                  '返済期限',
                  value: tx.dueDate == null
                      ? 'なし'
                      : Formatters.date(tx.dueDate!),
                  valueColor: tx.isOverdue()
                      ? StatusStyle.statusColor(status)
                      : null,
                ),
                if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                  const Divider(height: 1),
                  _infoRow(context, 'メモ', value: tx.memo!),
                ],
                const Divider(height: 1),
                _infoRow(
                  context,
                  '作成日時',
                  value: Formatters.dateTime(tx.createdAt),
                ),
                const Divider(height: 1),
                _infoRow(
                  context,
                  '更新日時',
                  value: Formatters.dateTime(tx.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                '返済履歴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${repayments.length}件',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (repayments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'まだ返済の記録はありません',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            )
          else
            ...repayments.map((r) => _RepaymentTile(
                  repayment: r,
                  onDelete: () => appState.deleteRepayment(r.id),
                )),
        ],
      ),
      bottomNavigationBar: canRepay
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RepaymentScreen(transactionId: tx.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('返済を記録する'),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      await appState.deleteTransaction(transactionId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _infoRow(
    BuildContext context,
    String label, {
    String? value,
    Widget? trailing,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: trailing ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: ratio.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation(color),
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
              builder: (ctx) => AlertDialog(
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
