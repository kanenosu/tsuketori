import 'package:flutter/material.dart';

import '../models/person.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import '../theme/status_style.dart';
import '../utils/formatters.dart';
import 'person_avatar.dart';

/// 取引一覧の1行（要件 6.1.2・モックアップ準拠）。
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.person,
    this.onTap,
  });

  final TransactionModel transaction;
  final Person? person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final typeColor = StatusStyle.typeColor(tx.type);
    final status = tx.effectiveStatus();
    final theme = Theme.of(context);
    final isLend = tx.type == TransactionType.lend;

    // 返済待ち以外（一部返済・返済済み・期限超過）はステータスを、
    // それ以外は種別を色付きバッジで示す。
    final showStatus = status != TransactionStatus.unpaid &&
        status != TransactionStatus.cancelled;
    final badgeLabel = showStatus ? status.label : tx.type.label;
    final badgeColor = showStatus
        ? StatusStyle.statusColor(status)
        : typeColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            PersonAvatar(person: person, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person?.name ?? '(不明な相手)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tx.type.label}・${Formatters.relative(tx.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isLend ? '+' : '-'}${Formatters.yenSuffix(tx.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
