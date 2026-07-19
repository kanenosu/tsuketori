import 'package:flutter/material.dart';

import '../models/person.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../theme/status_style.dart';
import '../utils/formatters.dart';
import 'person_avatar.dart';
import 'status_badge.dart';

/// 取引一覧の1行（要件 6.1.2）。
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PersonAvatar(person: person),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tx.type.label,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            person?.name ?? '(不明な相手)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          Formatters.date(tx.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tx.memo!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isLend ? '+' : '-'}${Formatters.number(tx.amount)}円',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: status, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
