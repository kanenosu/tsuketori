import 'package:flutter/material.dart';

import '../models/person.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import '../theme/app_colors.dart';
import '../theme/status_style.dart';
import '../utils/formatters.dart';
import 'person_avatar.dart';
import 'status_badge.dart';
import 'yen_amount.dart';

/// 取引一覧の1行（PayPay の Regular List・複数行）。
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
    final isLend = tx.type == TransactionType.lend;

    // 返済待ち以外（一部返済・返済済み・期限超過）はステータスを、
    // それ以外は種別を Status Label で示す。
    final showStatus =
        status != TransactionStatus.unpaid &&
        status != TransactionStatus.cancelled;
    final badgeLabel = showStatus ? status.label : tx.type.label;
    final badgeColor = showStatus ? StatusStyle.statusColor(status) : typeColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            PersonAvatar(person: person, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person?.name ?? '(不明な相手)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.type.label}・${Formatters.relative(tx.date)}',
                    style: const TextStyle(
                      color: AppColors.subtextGray,
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
                YenAmount(
                  amount: tx.amount,
                  prefix: isLend ? '+' : '-',
                  fontSize: 18,
                  color: typeColor,
                ),
                const SizedBox(height: 4),
                StatusLabel(
                  label: badgeLabel,
                  color: badgeColor,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
